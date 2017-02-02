--[[

	For use with the following version of Counter-Strike: Source.

	Build Label:           3398447   # Uniquely identifies each build
	Network PatchVersion:  3398447   # Determines client and server compatibility
	Protocol version:           24   # High level network protocol version
	Server version:        3398447
	Server AppID:           232330
	Client version:        3398447
	Client AppID:              240

		* client.dll: B62A08CC32DDA7D6CAB94B284F970EF9 (MD5)

]]--

return {
	-- Define the process to open.
	TargetProcess = "hl2.exe",

	-- Define the memory addresses to use.
	Offsets = {
		["client.dll"] = {
			Camera = 0x4FA8E4
		},
		["engine.dll"] = {
			MapName = 0x45E980
		}
	}
}