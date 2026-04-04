if SERVER then
	AddCSLuaFile()
end

local FCVAR_SYNC = { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }

CreateConVar(
	"ttt_asm_shift_speed_modifier",
	"2",
	FCVAR_SYNC,
	"Movement speed multiplier during the aiming sequence (Shift key)"
)
CreateConVar(
	"ttt_asm_alt_speed_modifier",
	"0.25",
	FCVAR_SYNC,
	"Movement speed multiplier during the aiming sequence (Alt key)"
)
CreateConVar("ttt_asm_mouse_speed_modifier", "3", FCVAR_SYNC, "Speed multiplier applied to the mouse movement")
CreateConVar("ttt_asm_aim_time", "15", FCVAR_SYNC, "How much time do you have to aim the missile")
CreateConVar("ttt_asm_missile_blast_damage", "110", FCVAR_SYNC, "Damage of the missile blast")
CreateConVar("ttt_asm_missile_blast_radius", "384", FCVAR_SYNC, "Radius of the missile blast")
CreateConVar("ttt_asm_allow_abort", "1", FCVAR_SYNC, "Allows you to abort the aiming sequence")
CreateConVar("ttt_asm_allow_abort_mid_flight", "0", FCVAR_SYNC, "Allows you to abort after the missile was launched")
CreateConVar(
	"ttt_asm_allow_camera_move_mid_flight",
	"1",
	FCVAR_SYNC,
	"Whether or not the camera can still be moved after the missile was launched"
)
CreateConVar(
	"ttt_asm_show_colleagues",
	"1",
	FCVAR_SYNC,
	"Makes your colleagues blue in the aiming sequence, so you don't accidentally hit them"
)
CreateConVar("ttt_asm_damage_owner", "1", FCVAR_SYNC, "Should the missile damage its owner")
CreateConVar("ttt_asm_friendlyfire", "1", FCVAR_SYNC, "Should the missile damage the owners teammates")
CreateConVar(
	"ttt_asm_show_debug",
	"0",
	FCVAR_SYNC,
	"Show debug information, including the missile blast radius on impact"
)
