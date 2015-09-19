--[[

	For use with the following version of Counter-Strike: Global Offensive.

	Protocol version 13502
	Exe version 1.35.0.2 (csgo)
	Exe build: 14:10:39 Sep 14 2015 (6155) (730)

		* client.dll: 8003BA07E94D55325F4B99B92EE44F7C (MD5)
		* engine.dll: 011A00953C3F7315138493F1D9F2318D (MD5)

]]--

return {
	-- Define the process to open.
	TargetProcess = "csgo.exe",

	-- Define the memory addresses to use.
	Offsets = {
		["client.dll"] = {
			MapName = 0x4A7CC54
		},
		["engine.dll"] = {
			Camera = 0x687248
		}
	}
}