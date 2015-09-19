--[[

	For use with the following version of Counter-Strike: Source.

	Build Label:           2234230   # Uniquely identifies each build
	Network PatchVersion:  2230303   # Determines client and server compatibility
	Protocol version:           24   # High level network protocol version

		* client.dll: 613B6AEF2CFA35A1D545CF876A18F967 (MD5)

]]--

return {
	-- Define the process to open.
	TargetProcess = "hl2.exe",

	-- Define the memory addresses to use.
	Offsets = {
		["client.dll"] = {
			Camera = 0x579F18,
			MapName = 0x57D7D8
		}
	}
}