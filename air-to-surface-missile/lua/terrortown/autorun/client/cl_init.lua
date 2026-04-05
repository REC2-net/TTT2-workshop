if _G.ASM_CL_INIT_LOADED then
	return
end

_G.ASM_CL_INIT_LOADED = true

hook.Add("TTT2FinishedLoading", "TTT2RegisterMenof36goAddonDev", function()
	AddTTT2AddonDev("76561198056317817")
end)
