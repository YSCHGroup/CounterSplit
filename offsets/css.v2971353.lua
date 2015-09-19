--[[

	For use with the following version of Counter-Strike: Source.

	Build Label:           2971353   # Uniquely identifies each build
	Network PatchVersion:  2971353   # Determines client and server compatibility
	Protocol version:           24   # High level network protocol version
	Server version:        2971353
	Server AppID:           232330
	Client version:        2971353
	Client AppID:              240

		* client.dll: 2BE2E164389A52B4178ACC73AECA4E49 (MD5)

]]--

return {
	-- Define the process to open.
	TargetProcess = "hl2.exe",

	-- Define the memory addresses to use.
	Offsets = {
		["client.dll"] = {
			Camera = 0x4FA8E4,
			MapName = 0x4FE164
		}
	}
}