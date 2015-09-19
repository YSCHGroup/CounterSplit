-- Require FFI for support functions.
local ffi = require("ffi");

ffi.cdef([[

	void Sleep(int ms);
	int MapVirtualKeyA(int keycode, int maptype);
	void keybd_event(int keycode, int scancode, int flags, int extra);

]]);

-- Simulate key presses.
function g_SendKeyPress(nVKey)
	local nScanCode = ffi.C.MapVirtualKeyA(nVKey, 0);
	ffi.C.keybd_event(nVKey, nScanCode, 0, 0);
	ffi.C.keybd_event(nVKey, nScanCode, 0x0002, 0);
end

-- Wait function to reduce CPU usage.
function g_Sleep(nTime)
	ffi.C.Sleep(nTime);
end

-- Determine whether a table contains a value.
function g_TableHasValue(tTable, vValue)
	for K, V in pairs(tTable) do
		if (V == vValue) then
			return true;
		end
	end
	
	return false;
end

-- Determine whether the player is inside a defined box.
function g_IsInBox(Position, BoxA, BoxB)
	local bInX = (BoxA[1] > BoxB[1] and Position[1] <= BoxA[1] and Position[1] >= BoxB[1]) or
				(BoxA[1] < BoxB[1] and Position[1] >= BoxA[1] and Position[1] <= BoxB[1]);

	local bInY = (BoxA[2] > BoxB[2] and Position[2] <= BoxA[2] and Position[2] >= BoxB[2]) or
				(BoxA[2] < BoxB[2] and Position[2] >= BoxA[2] and Position[2] <= BoxB[2]);

	local bInZ = (BoxA[3] > BoxB[3] and Position[3] <= BoxA[3] and Position[3] >= BoxB[3]) or
				(BoxA[3] < BoxB[3] and Position[3] >= BoxA[3] and Position[3] <= BoxB[3]);


	return (bInX and bInY and bInZ);
end

-- Load new map zones on map change.
function g_UpdateMapInformation(hHandle, dwOffset)
	-- Get current map name.
	local szMapName = RemoteProcess.ReadMemory(hHandle, dwOffset, TYPE_CHAR, 128);
	
	if (not szMapName) then
		return false;
	end
	
	-- Strip extension. (v34 fix)
	local nExtStart = szMapName:find(".bsp");
	
	if (nExtStart) then
		szMapName = szMapName:sub(0, nExtStart - 1);
	end
	
	if (type(szMapName) == "string" and szMapName ~= "" and szMapName ~= g_GlobalVars.MapInfo.Name) then
		-- Load the new map information from file.
		local bSuccess, tReturn = pcall(dofile, "maps/"..szMapName..".lua");
		
		-- Overwrite new new map data.
		g_GlobalVars.MapInfo = {
			Name = szMapName,
			Ready = false,
			Zones = {},
			Checkpoints = {}
		};
		
		-- Print some text to console.
		g_Print("Set current map to '%s'.", szMapName);
		
		if (bSuccess and type(tReturn) == "table") then
			-- Append map positional information.
			if (type(tReturn.Zones) == "table") then
				for K, V in pairs(tReturn.Zones) do
					if (type(V[1]) == "table" and type(V[2]) == "table") then
						g_GlobalVars.MapInfo.Zones[K] = V;
					end
				end
				
				for K, V in pairs(tReturn.Checkpoints) do
					if (type(V[1]) == "table" and type(V[2]) == "table") then
						table.insert(g_GlobalVars.MapInfo.Checkpoints, V);
					end
				end
			end
			
			-- Confirm there are start and end zones.
			if (g_GlobalVars.MapInfo.Zones.Start and g_GlobalVars.MapInfo.Zones.End) then
				-- Ready.
				g_GlobalVars.MapInfo.Ready = true;
				
				local nTotalCheckpoints = #g_GlobalVars.MapInfo.Checkpoints;
				
				if (nTotalCheckpoints >= 1) then
					g_Print("Parsed "..nTotalCheckpoints.." checkpoints successfully.");
				end
			else
				g_Print("Map file contains invalid zones.");
			end
		else
			-- Couldn't load the file. (parse error, no such file, read error, etc.)
			g_Print("Failed to read map information.");
		end
	end
end

-- Formatted time print function.
function g_Print(szText, ...)
	local szTimeString = os.date("%H:%M:%S");
	print(string.format("[%s] "..szText, szTimeString, ...));
end

-- Formatted error function.
function g_Error(szText, ...)
	io.stderr:write(string.format("ERROR: "..szText, ...).."\n");
end