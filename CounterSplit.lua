--[[

	CounterSplit - automated splitter for Counter-Strike: Source
	Copyright (C) 2014 - 2015, Team SkyeNet. (www.skyenet.org)
	
	Contributors:
		* aixxe <aixxe@skyenet.org>
		* emskye96 <emma@skyenet.org>
	
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with CounterSplit. If not, see <http://www.gnu.org/licenses/>.

]]--

-- Print startup text.
print("CounterSplit - automated splitter for Counter-Strike: Source");
print("Copyright (C) 2014 - 2015, Team SkyeNet. (www.skyenet.org)\n");

-- Include support modules.
require("RemoteProcess");

-- Include support files.
dofile("includes/enums.lua");
dofile("includes/functions.lua");

-- Define global variables.
g_GlobalVars = {
	Process = {
		Modules = {}
	},
	Offsets = {},
	MapInfo = {
		Name = "",
		Ready = false,
		Zones = {},
		Checkpoints = {}
	},
	RunState = 3,
	LastCheckpoint = 0
};

local sConfigFile = "includes\\config.lua";

if (arg[1]) then
	-- Set configuration file from command line argument.
	sConfigFile = arg[1];
end

-- Include configuration file.
local bSuccess, tConfigTbl = pcall(dofile, sConfigFile);

if (bSuccess and type(tConfigTbl) == "table") then
	g_Print("Read configuration from file '%s'.", sConfigFile);
	g_Configuration = tConfigTbl;
	
	-- Read offsets.
	if (type(g_Configuration.OffsetFile) == "string") then
		-- Attempt to include offset file.
		local sOffsetFile = g_Configuration.OffsetFile;
		local bSuccess, tOffsetTbl = pcall(dofile, sOffsetFile);
		
		if (bSuccess and type(tOffsetTbl) == "table") then
			g_Print("Read offsets from file '%s'.", sOffsetFile);
			g_Configuration.TargetProcess = tOffsetTbl.TargetProcess;
			g_Configuration.Offsets = tOffsetTbl.Offsets;
		else
			return g_Error("Failed to read file '%s'.", sOffsetFile);
		end
	else
		return g_Error("'OffsetFile' not specified in configuration file.");
	end
else
	return g_Error("Failed to read file '%s'.", sConfigFile);
end

-- Retrieve process list.
local tProcessList = RemoteProcess.GetProcessList();

if (type(tProcessList) ~= "table") then
	return g_Error("Failed to retrieve process list.");
end

-- Locate game process.
local szTargetProcess, nGamePID = g_Configuration.TargetProcess, -1;
g_Print("Searching for process '%s'..", szTargetProcess);

for szProcessName, tblProcessInfo in pairs(tProcessList) do
	if (szProcessName == szTargetProcess) then
		-- Store process ID.
		nGamePID = tblProcessInfo.ProcessID;
		
		-- Continue.
		break;
	end
end

if (nGamePID == -1) then
	return g_Error("Failed to locate target process. (%s)", szTargetProcess);
end

-- Open handle to process.
local hGameProcess, nErrorCode = RemoteProcess.OpenProcess(nGamePID, PROCESS_ALL_ACCESS);
g_Print("Opening handle to process..");

if not (hGameProcess) then
	return g_Error("Failed to open handle to target process. (errno: %i)", nErrorCode);
end

-- Locate required module addresses.
local tProcessModules = RemoteProcess.GetModuleList(nGamePID);

if (type(tProcessModules) ~= "table") then
	return g_Error("Failed to retrieve process module list.");
end

-- Get list of modules.
local tModuleNames = {};

for K, V in pairs(g_Configuration.Offsets) do
	table.insert(tModuleNames, K:lower());
end

-- Get base module addresses.
for szModuleName, tblModuleInfo in pairs(tProcessModules) do
	if (g_TableHasValue(tModuleNames, szModuleName:lower())) then
		g_GlobalVars.Process.Modules[szModuleName] = tblModuleInfo.BaseAddr;
	end
end

-- Append offsets to base addresses.
for szModuleName, tOffsetTable in pairs(g_Configuration.Offsets) do
	for szOffsetName, nOffsetAddress in pairs(tOffsetTable) do
		local nModuleAddr = g_GlobalVars.Process.Modules[szModuleName];
		
		if not (nModuleAddr) then
			return g_Error("Failed to get base address for module '%s'.", szModuleName);
		end
		
		g_GlobalVars.Offsets[szOffsetName] = (nModuleAddr + nOffsetAddress);
	end
end

-- Assign common offsets to local variables.
local dwCameraOrigin = (g_GlobalVars.Offsets.Camera);
local dwCurrentMapName = (g_GlobalVars.Offsets.MapName);

-- Set hotkey local variables.
local vkReset, vkSplit = g_Configuration.Hotkeys.Reset, g_Configuration.Hotkeys.Split;

-- Retrieve current map name.
g_UpdateMapInformation(hGameProcess, dwCurrentMapName);

if (g_GlobalVars.MapInfo.Name == "") then
	g_Print("Waiting for a map to be loaded..");
end

-- Enter main process loop.
while (RemoteProcess.IsProcessRunning(hGameProcess)) do
	-- Retrieve camera position. (should be the same as values shown with cl_showpos)
	local X, Y, Z = RemoteProcess.ReadMemory(hGameProcess, dwCameraOrigin, TYPE_FLOAT, 3);
	local tPlayerPosition = {X, Y, Z};

	-- Update map information when camera position returns (0, 0, 0).
	if ((X == 0 and Y == 0 and Z == 0) or (not X or not Y or not Z) or (g_GlobalVars.MapInfo.Name == "")) then
		g_UpdateMapInformation(hGameProcess, dwCurrentMapName);
	elseif (g_GlobalVars.MapInfo.Ready) then
		-- Check whether the player is currently in the start/end zone.
		local bInStartZone = g_IsInBox(tPlayerPosition, g_GlobalVars.MapInfo.Zones.Start[1], g_GlobalVars.MapInfo.Zones.Start[2]);
		local bInEndZone = g_IsInBox(tPlayerPosition, g_GlobalVars.MapInfo.Zones.End[1], g_GlobalVars.MapInfo.Zones.End[2]);
		
		-- Always check zones regardless of run state.
		if (bInStartZone and g_GlobalVars.RunState ~= 1) then
			-- Reset external timer.
			g_SendKeyPress(vkReset);
			
			-- Set "In Start Zone" state.
			g_GlobalVars.RunState = 1;
			g_Print("Leave the start zone to begin.");
		elseif (bInEndZone and g_GlobalVars.RunState == 3) then
			-- Advance final split to stop timer.
			g_SendKeyPress(vkSplit);
			
			-- Set "In End Zone" state.
			g_GlobalVars.RunState = 2;
			g_Print("Timer stopped.");
		elseif (not bInStartZone and not bInEndZone and g_GlobalVars.RunState == 1) then
			-- Start external timer.
			g_SendKeyPress(vkSplit);
			
			-- Set "In Progress" state.
			g_GlobalVars.LastCheckpoint = 0;
			g_GlobalVars.RunState = 3;
			g_Print("Timer started.");
		end
		
		-- Advance checkpoints while the timer is running.
		if (g_GlobalVars.RunState == 3) then
			local nNextCheckpoint = (g_GlobalVars.LastCheckpoint + 1);
			
			if (g_GlobalVars.MapInfo.Checkpoints[nNextCheckpoint]) then
				-- Compare player position to next checkpoint box.
				local tCheckpoint = g_GlobalVars.MapInfo.Checkpoints[nNextCheckpoint];
				
				if (g_IsInBox(tPlayerPosition, tCheckpoint[1], tCheckpoint[2])) then
					-- Advance to next split.
					g_SendKeyPress(vkSplit);
					
					g_GlobalVars.LastCheckpoint = nNextCheckpoint;
					g_Print("Passed checkpoint %i.", nNextCheckpoint);
				end
			end
		end
	end
	
	-- Wait 1ms before next check.
	g_Sleep(1);
end

-- Close handle and exit.
RemoteProcess.CloseProcess(hGameProcess);
g_Print("Game closed, exiting..");