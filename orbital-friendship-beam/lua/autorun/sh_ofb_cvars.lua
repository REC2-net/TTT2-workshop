if SERVER then
	AddCSLuaFile()
	if file.Exists("scripts/sh_convarutil.lua", "LUA") then
		AddCSLuaFile("scripts/sh_convarutil.lua")
		print("[INFO][Orbital Friendship Beam] Using the utility plugin to handle convars instead of the local version")
	else
		AddCSLuaFile("scripts/sh_convarutil_local.lua")
		print("[INFO][Orbital Friendship Beam] Using the local version to handle convars instead of the utility plugin")
	end
end

if file.Exists("scripts/sh_convarutil.lua", "LUA") then
	include("scripts/sh_convarutil.lua")
else
	include("scripts/sh_convarutil_local.lua")
end

-- Must run before hook.Add
local cg = ConvarGroup("OFB", "Orbital Friendship Beam")
Convar(cg, false, "ttt_ofb_startDelay", 2.8, { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Time before the friendship beam is actually launched", "float", 0, 60, 1)
Convar(cg, false, "ttt_ofb_duration", 16.6, { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Duration of the friendship beam", "float", 0.1, 600, 1)
--
--generateCVTable()
--