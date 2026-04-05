SWEP.PrintName = "Air-to-Surface Missile"
SWEP.Author = "Fabii, mexikoedi (original), Otger (ported)"
SWEP.Purpose = "Air-to-Surface Controllable Missile."
SWEP.Instructions = "Left click to launch an air-to-surface missile attack from the sky above the aimed position.\n"
	.. "Use the mouse or the movement keys to direct it.\n"
	.. "Left click to launch, right click to abort."
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.BounceWeaponIcon = true
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP1
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.LimitedStock = true
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.Icon = "vgui/ttt/icon_asm_64.jpg" -- Text shown in the equip menu
SWEP.EquipMenuData = {
	type = "Missile",
	desc = "Left click to launch an air-to-surface missile attack from the sky above the aimed position.\n"
		.. "Use the mouse or the movement keys to direct it.\n"
		.. "Left click to launch, right click to abort.",
}
SWEP.Weight = 7
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.CountdownEnd = 0
SWEP.LastPosInBounds = nil
SWEP.UserID = -1
SWEP.IsAsmSWEP = true

if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/swep_asm.vmt")
	resource.AddFile("materials/vgui/swep_asm.vtf")
	resource.AddFile("materials/vgui/ttt/icon_asm_64.jpg")
	resource.AddFile("materials/hud/killicons/asm_missile.vmt")
	resource.AddFile("materials/hud/killicons/asm_missile.vtf")
end

if util.IsValidModel("models/weapons/v_c4.mdl") then
	SWEP.ModelC4 = true
	SWEP.ViewModel = "models/weapons/v_c4.mdl"
	SWEP.WorldModel = "models/weapons/w_c4.mdl"
else
	SWEP.ModelC4 = false
	SWEP.ViewModel = "models/weapons/v_toolgun.mdl"
	SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
end

local SndReady = Sound("npc/metropolice/vo/isreadytogo.wav")
local SndReadyB = Sound("buttons/blip2.wav")
local SndRequested = Sound("buttons/button24.wav")
local SndInbound = Sound("npc/combine_soldier/vo/inbound.wav")

local cv = {
	Debug = false,
	CountdownLength = 15,
	ShiftSpeedModifier = 2,
	AltSpeedModifier = 0.25,
	MouseSpeedModifier = 3,
	AllowAbort = true,
	AllowAbortMidFlight = false,
	AllowCameraMoveMidFlight = true,
}

local function getCvarBool(name, fallback)
	local cvar = GetConVar(name)
	if not cvar then
		return fallback
	end

	return cvar:GetBool()
end

local function getCvarFloat(name, fallback)
	local cvar = GetConVar(name)
	if not cvar then
		return fallback
	end

	return cvar:GetFloat()
end

local function refreshConvars()
	cv.Debug = getCvarBool("ttt_asm_show_debug", false)
	cv.CountdownLength = getCvarFloat("ttt_asm_aim_time", 15)
	cv.ShiftSpeedModifier = getCvarFloat("ttt_asm_shift_speed_modifier", 2)
	cv.AltSpeedModifier = getCvarFloat("ttt_asm_alt_speed_modifier", 0.25)
	cv.MouseSpeedModifier = getCvarFloat("ttt_asm_mouse_speed_modifier", 3)
	cv.AllowAbort = getCvarBool("ttt_asm_allow_abort", true)
	cv.AllowAbortMidFlight = getCvarBool("ttt_asm_allow_abort_mid_flight", false)
	cv.AllowCameraMoveMidFlight = getCvarBool("ttt_asm_allow_camera_move_mid_flight", true)
end

refreshConvars()

local function addConvarCallbacks()
	local id = "ASMRefreshConvars"

	cvars.RemoveChangeCallback("ttt_asm_show_debug", id)
	cvars.RemoveChangeCallback("ttt_asm_aim_time", id)
	cvars.RemoveChangeCallback("ttt_asm_shift_speed_modifier", id)
	cvars.RemoveChangeCallback("ttt_asm_alt_speed_modifier", id)
	cvars.RemoveChangeCallback("ttt_asm_mouse_speed_modifier", id)
	cvars.RemoveChangeCallback("ttt_asm_allow_abort", id)
	cvars.RemoveChangeCallback("ttt_asm_allow_abort_mid_flight", id)
	cvars.RemoveChangeCallback("ttt_asm_allow_camera_move_mid_flight", id)

	cvars.AddChangeCallback("ttt_asm_show_debug", refreshConvars, id)
	cvars.AddChangeCallback("ttt_asm_aim_time", refreshConvars, id)
	cvars.AddChangeCallback("ttt_asm_shift_speed_modifier", refreshConvars, id)
	cvars.AddChangeCallback("ttt_asm_alt_speed_modifier", refreshConvars, id)
	cvars.AddChangeCallback("ttt_asm_mouse_speed_modifier", refreshConvars, id)
	cvars.AddChangeCallback("ttt_asm_allow_abort", refreshConvars, id)
	cvars.AddChangeCallback("ttt_asm_allow_abort_mid_flight", refreshConvars, id)
	cvars.AddChangeCallback("ttt_asm_allow_camera_move_mid_flight", refreshConvars, id)
end

addConvarCallbacks()

local function debugPrint(...)
	if cv.Debug then
		local arg = { ... }
		if CLIENT then
			print("Client", unpack(arg))
		elseif SERVER then
			print("Server", unpack(arg))
		end
	end
end

local function asmLog(level, ...)
	local cvar = GetConVar("ttt_asm_log_level")
	local active = cvar and cvar:GetInt() or 0
	if active < level then
		return
	end

	print("[ASM]", ...)
end

util.PrecacheModel("models/props_junk/PopCan01a.mdl")
util.PrecacheModel("models/props_c17/canister01a.mdl")

function SWEP:Initialize()
	refreshConvars()
	self.Delay = 0
	self.Status = 0
	self.ThirdPerson = false

	if self.ModelC4 then
		self:SetWeaponHoldType("slam")
	else
		self:SetWeaponHoldType("pistol")
	end

	if CLIENT then
		self.FadeCount = 0
		self.Load = 0
		killicon.Add("sent_asm", "hud/killicons/asm_missile", Color(255, 0, 0, 255))
		language.Add("sent_asm", "Air-to-surface Missile")
	end
end

function SWEP:OnDrop()
	local ply = Player(self.UserID)
	if IsValid(ply) then
		ply:SetViewEntity(ply)
	end
	self:UnlockPlayer()
	if IsValid(self.Camera) then
		debugPrint("Air-To-Surface-Missile: OnDrop - Camera valid")
		local owner = self:GetOwner()
		if IsValid(owner) and owner:GetViewEntity() == self.Camera then
			debugPrint("Air-To-Surface-Missile: OnDrop - Reset View Entity")
			owner:SetViewEntity(owner)
		end
		self.Camera:Remove()
	end
	if IsValid(ply) and not ply:Alive() then
		self:SetStatus(6, 0)
	end
end

function SWEP:OnRemove()
	if SERVER then
		self:UnlockPlayer()
		if IsValid(self.Camera) then
			local owner = self:GetOwner()
			if IsValid(owner) and owner:GetViewEntity() == self.Camera then
				owner:SetViewEntity(owner)
			end
			self.Camera:Remove()
		end
	end
end

function SWEP:Deploy()
	if SERVER then
		self:SendWeaponAnim(ACT_VM_DRAW)
	end
	return true
end

function SWEP:Holster()
	if self.Status > 0 then
		return false
	end
	return true
end

function SWEP:ShouldDropOnDie()
	return false
end

local function isFriendly(team, ent)
	if team ~= nil and IsValid(ent) and ent:IsPlayer() then
		if TTT2 and ent.GetTeam then
			return ent:GetTeam() == team
		end
		if ent.GetRole then
			return ent:GetRole() == team
		end
	end
	return false
end

-- SERVER --

if SERVER then
	util.AddNetworkString("ASM-Update")
	util.AddNetworkString("ASM-Firstperson")
	util.AddNetworkString("ASM-Msg")

	function SWEP:PrimaryAttack()
		self.AllowDrop = false

		if self.Status == 0 then
			if self.Delay > CurTime() then
				return
			end

			local tr = self:GetOwner():GetEyeTrace()
			local vPos = self:FindInitialPos(tr.HitPos)

			if vPos then
				self:SpawnCamera(vPos)
				net.Start("ASM-Firstperson")
				net.Send(self:GetOwner())
				self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
				self:GetOwner():SetAnimation(PLAYER_ATTACK1)
				self:EmitSound(SndRequested)

				self:LockPlayer()
				self:SetStatus(1, 1.75)
			else
				asmLog(
					2,
					"Could not find sky position above aim point for",
					IsValid(self:GetOwner()) and self:GetOwner() or "unknown owner"
				)
				self:SendMessage(1)
			end
		elseif self.Status == -1 then
			self:SendMessage(2)
		end
		self:SetNextPrimaryFire(CurTime() + 1)
	end

	function SWEP:SecondaryAttack()
		self.AllowDrop = true

		if not cv.AllowAbort then
			return
		end

		if self.Status < 1 then
			return
		end

		if IsValid(self.Missile) and cv.AllowAbortMidFlight then
			self:MissileEndPhase()
		elseif not IsValid(self.Missile) then
			if IsValid(self:GetOwner()) then
				self:GetOwner():SetViewEntity(self:GetOwner())
			end
			self:UnlockPlayer()
			self:SetStatus(6, 0)
		end

		self:SetNextSecondaryFire(CurTime() + 0.2)
	end

	function SWEP:Reload() end

	function SWEP:Equip()
		--if !self.ModelC4 then self:SendMessage(0) end
		self.AllowDrop = true
		if IsValid(self:GetOwner()) then
			self.UserID = self:GetOwner():UserID()
		end
	end

	function SWEP:Think()
		if CurTime() < self.Delay then
			return
		end

		if self.Status == 1 then
			self:SetStatus(2, 0.5)
		-- Try start missile
		elseif self.Status == 2 then
			self:GetOwner():SetViewEntity(self.Camera)
			self:SendWeaponAnim(ACT_VM_IDLE)
			self:SetStatus(3, 0)
		elseif (self.Status > 2) and (self.Status < 6) then
			if not IsValid(self.Camera) then
				asmLog(
					1,
					"Lost camera entity while guiding missile for",
					IsValid(self:GetOwner()) and self:GetOwner() or "unknown owner"
				)
				self:SendMessage(3)
				self:MissileEndPhase()
				return
			end
			local pos = self.Camera:GetPos()
			local tr = util.TraceLine({
				start = pos,
				endpos = Vector(pos.x, pos.y, -10000),
				mask = MASK_NPCWORLDSTATIC,
				filter = { self.Camera },
			})
			if tr.Hit == false then
				if self.LastPosInBounds then
					self.Camera:SetPos(self.LastPosInBounds)
					pos = self.LastPosInBounds
				end
			else
				self.LastPosInBounds = pos
			end

			if self.Status < 5 then
				if
					(
						self:GetOwner():KeyDown(IN_ATTACK)
						or self:GetOwner():KeyDown(IN_USE)
						or (self.CountdownEnd - CurTime() <= 0)
					) and not IsValid(self.Missile)
				then
					self:SpawnMissile(pos)
					self:SetStatus(4, 0)
					if IsValid(self.Missile) then
						self.Missile:Boost()
					end
					self.Camera:SetVelocity(-self.Camera:GetVelocity())
				end
				if cv.AllowAbort and self:GetOwner():KeyDown(IN_ATTACK2) then
					if IsValid(self.Missile) and cv.AllowAbortMidFlight then
						self:MissileEndPhase()
					elseif not IsValid(self.Missile) then
						self:GetOwner():SetViewEntity(self:GetOwner())
						self:UnlockPlayer()
						self:SetStatus(6, 0)
					end
				end
				-- Only allow moving the camera if the missile isn't already fired
				if not IsValid(self.Missile) or cv.AllowCameraMoveMidFlight then
					local mVel = Vector(0, 0, 0)
					local kVel = Vector(0, 0, 0)
					local treshold = 0.9
					local cmd = self:GetOwner():GetCurrentCommand()
					local SpeedModifier = 1
					local maxVal = 300
					local maxValMouse = maxVal * cv.MouseSpeedModifier

					if self:GetOwner():KeyDown(IN_FORWARD) then
						kVel = kVel + Vector(maxVal - 0.1, 0, 0)
					end
					if self:GetOwner():KeyDown(IN_BACK) then
						kVel = kVel + Vector(-maxVal - 0.1, 0, 0)
					end
					if self:GetOwner():KeyDown(IN_MOVELEFT) then
						kVel = kVel + Vector(0, maxVal - 0.1, 0)
					end
					if self:GetOwner():KeyDown(IN_MOVERIGHT) then
						kVel = kVel + Vector(0, -maxVal - 0.1, 0)
					end
					if self:GetOwner():KeyDown(IN_SPEED) then
						SpeedModifier = cv.ShiftSpeedModifier
					elseif self:GetOwner():KeyDown(IN_WALK) then
						SpeedModifier = cv.AltSpeedModifier
					end

					mVel = mVel + Vector(0, -cmd:GetMouseX() * 3 * cv.MouseSpeedModifier, 0)
					mVel = mVel + Vector(-cmd:GetMouseY() * 3 * cv.MouseSpeedModifier, 0, 0)

					if math.abs(mVel.x) > treshold or math.abs(mVel.y) > treshold then
						if
							(math.abs(kVel.x) > treshold or math.abs(kVel.y) > treshold)
							and (math.abs(kVel.x) > maxVal or math.abs(kVel.y) > maxVal)
						then
							kVel.x = math.Clamp(kVel.x, -maxVal, maxVal)
							kVel.y = math.Clamp(kVel.y, -maxVal, maxVal)
						end
						mVel:Add(kVel)
						if math.abs(mVel.x) > maxValMouse or math.abs(mVel.y) > maxValMouse then
							mVel.x = math.Clamp(mVel.x, -maxValMouse, maxValMouse)
							mVel.y = math.Clamp(mVel.y, -maxValMouse, maxValMouse)
						end
						self.Camera:SetVelocity(mVel * SpeedModifier - self.Camera:GetVelocity() * 0.7)
						--debugPrint(mVel * SpeedModifier - self.Camera:GetVelocity())
					elseif math.abs(kVel.x) > treshold or math.abs(kVel.y) > treshold then
						if math.abs(kVel.x) > maxVal or math.abs(kVel.y) > maxVal then
							kVel.x = math.Clamp(kVel.x, -maxVal, maxVal)
							kVel.y = math.Clamp(kVel.y, -maxVal, maxVal)
						end
						self.Camera:SetVelocity(kVel * SpeedModifier - self.Camera:GetVelocity() * 0.7)
						--debugPrint(kVel * SpeedModifier - self.Camera:GetVelocity())
					else
						local drag = self.Camera:GetVelocity()
						drag = -0.7 * drag
						self.Camera:SetVelocity(drag)
					end
				end
			end
		-- Missile already exploded
		elseif self.Status == 6 then
			self:UnlockPlayer()
			self:SetStatus(-1, 0)
			timer.Simple(3, function()
				if IsValid(self) and self.Status == -1 then
					self:SetStatus(0, 0)
				end
			end)
		end
	end

	function SWEP:SetStatus(status, delay)
		self.Status = (status or 0)
		if delay > 0 then
			self.Delay = CurTime() + delay
		end
		if IsValid(self:GetOwner()) then
			local send = -1
			if status == 2 then
				self.CountdownEnd = CurTime() + cv.CountdownLength
				send = self.CountdownEnd
				debugPrint("Send", send)
			end
			net.Start("ASM-Update")
			net.WriteFloat(send)
			net.WriteEntity(self)
			net.WriteInt(status or 0, 32)
			net.Send(self:GetOwner())
		end
	end

	function SWEP:SendMessage(id)
		net.Start("ASM-Msg")
		net.WriteInt(id, 32)
		net.Send(self:GetOwner())
	end

	function SWEP:CreateCamera()
		local ent = ents.Create("prop_physics")
		ent:SetModel("models/props_junk/PopCan01a.mdl")
		ent:SetPos(self:GetOwner():GetPos())
		ent:SetAngles(Angle(90, 0, 0))
		ent:Spawn()
		ent:Activate()
		ent:SetMoveType(MOVETYPE_NOCLIP)
		ent:SetSolid(SOLID_NONE)
		ent:SetRenderMode(RENDERMODE_NONE)
		ent:DrawShadow(false)
		return ent
	end

	function SWEP:SpawnCamera(vPos)
		if not IsValid(self.Camera) then
			self.Camera = self:CreateCamera()
		end

		self.Camera:SetPos(vPos + Vector(0, 0, -56))
		self.Camera:SetAngles(Angle(90, 0, 0))
	end

	function SWEP:SpawnMissile(vPos)
		local mis = ents.Create("sent_asm")
		mis:SetPos(vPos + Vector(0, 0, mis:OBBMins().z - 48))
		mis:SetAngles(Angle(90, 0, 0))

		local owner = self:GetOwner()
		if IsValid(owner) then
			mis:SetOwner(owner)
			mis.Owner = owner
			mis.SWEP = self

			if TTT2 then
				mis.AssociatedTeam = owner:GetTeam()
			else
				mis.AssociatedTeam = owner:GetRole()
			end
			mis.UserID = owner:UserID()
		end

		mis:Spawn()
		mis:Activate()
		mis:Launch()

		if IsValid(mis) then
			self.Missile = mis
			self:SetNWEntity("Missile", mis)
			return true
		end
		return false
	end

	local function ASMSetVis(ply)
		local wep = ply:GetActiveWeapon()
		if
			IsValid(wep)
			and wep:GetClass() == "swep_asm"
			and ((wep.Status == 2) or (wep.Status == 3))
			and IsValid(wep.Camera)
		then
			AddOriginToPVS(wep.Camera:GetPos())
		end
	end
	hook.Add("SetupPlayerVisibility", "ASMSetupVis", ASMSetVis)

	function SWEP:LockPlayer()
		self.LastMoveType = self:GetOwner():GetMoveType()
		self:GetOwner():SetMoveType(MOVETYPE_NONE)
	end

	function SWEP:UnlockPlayer()
		debugPrint("Air-To-Surface-Missile: Unlock player")
		local owner = self:GetOwner()
		if IsValid(owner) and owner:GetMoveType() == MOVETYPE_NONE then
			debugPrint("Air-To-Surface-Missile: Actually unlock player")
			owner:SetMoveType(self.LastMoveType or MOVETYPE_WALK)
		end
	end

	function SWEP:MissileEndPhase()
		debugPrint("Air-To-Surface-Missile: Missile is in air or destroyed")
		if IsValid(self:GetOwner()) then
			self:GetOwner():SetViewEntity(self:GetOwner())
			self:UnlockPlayer()
			debugPrint("Air-To-Surface-Missile: Missile end phase - Reset View Entity")
		end
		if IsValid(self.Camera) then
			self.Camera:SetParent(nil)
		end
		if self.Status > 1 then
			self:SetStatus(6, 0.5)
			self:Remove()
		end
	end

	function SWEP:FindInitialPos(vStart)
		local td = {}
		td.start = vStart + Vector(0, 0, -32)
		td.endpos = vStart
		td.endpos.z = 16384
		td.mask = MASK_NPCWORLDSTATIC
		td.filter = {}
		local bContinue = true
		local nCount = 0
		local tr = {}
		local vPos = nil

		while bContinue and td.start.z <= td.endpos.z do
			nCount = nCount + 1
			tr = util.TraceLine(td)
			if tr.HitSky then
				vPos = tr.HitPos
				bContinue = false
			elseif not tr.Hit then
				td.start = tr.HitPos - Vector(0, 0, 64)
			elseif tr.HitWorld then
				td.start = tr.HitPos + Vector(0, 0, 64)
			elseif IsValid(tr.Entity) then
				table.insert(td.filter, tr.Entity)
			end
			if nCount > 128 then
				break
			end
		end
		return vPos
	end

	function SWEP:CheckFriendly(ent)
		if getCvarBool("ttt_asm_show_colleagues", true) then
			if IsValid(self:GetOwner()) then
				local teamOwn = nil
				if TTT2 then
					teamOwn = self:GetOwner():GetTeam()
				else
					teamOwn = self:GetOwner():GetRole()
				end
				return isFriendly(teamOwn, ent)
			end
			return false
		else
			if ent:Disposition(self:GetOwner()) == 1 then
				return false
			end
			return true
		end
	end
end

-- CLIENT --

if CLIENT then
	surface.CreateFont("AsmScreenFont", {
		size = 18,
		weight = 400,
		antialias = false,
		shadow = false,
		font = "Trebuchet MS",
	})

	surface.CreateFont("AsmCamFont", {
		size = 22,
		weight = 700,
		antialias = false,
		shadow = false,
		font = "Courier New",
	})

	--local texScreenOverlay = surface.GetTextureID("effects/combine_binocoverlay")
	--local matMissileAvailable = Material("HUD/asm_available")

	local SndNoPos = Sound("npc/combine_soldier/vo/sectorisnotsecure.wav")
	local SndNoPosB = Sound("buttons/button19.wav")
	local SndNotReady = Sound("buttons/button2.wav")
	local SndLost = Sound("npc/combine_soldier/vo/lostcontact.wav")

	function SWEP:Think() end

	net.Receive("ASM-Update", function(len, ply)
		local countdownEnd = net.ReadFloat()
		local ent = net.ReadEntity()
		local status = net.ReadInt(32)
		if IsValid(ent) and ent:GetClass() == "swep_asm" then
			ent:UpdateStatus(status)
			if not (countdownEnd == -1) and status == 2 then
				ent.CountdownEnd = countdownEnd
			end
		end
	end)

	net.Receive("ASM-Firstperson", function()
		local tbl = concommand.GetTable()
		if tbl and tbl.firstperson then
			RunConsoleCommand("firstperson", "1")
		end
	end)

	net.Receive("ASM-Msg", function(len, ply)
		local nId = net.ReadInt(32)
		if nId == 0 then
			MsgN("[Air-to-surface Missile SWEP] Counter-Strike: Source is not mounted. Using Toolgun model.")
		elseif nId == 1 then
			notification.AddLegacy("Could not find open sky above the specified position", NOTIFY_ERROR, 5)
			LocalPlayer():EmitSound(SndNoPos)
			LocalPlayer():EmitSound(SndNoPosB)
		elseif nId == 2 then
			notification.AddLegacy("Missiles currently unavailable", NOTIFY_ERROR, 5)
			LocalPlayer():EmitSound(SndNotReady)
		elseif nId == 3 then
			notification.AddLegacy("Lost contact with the missile", NOTIFY_GENERIC, 5)
			LocalPlayer():EmitSound(SndLost)
		end
	end)

	function SWEP:UpdateStatus(status)
		local nLastStatus = self.Status
		self.Status = status
		if status == 0 then
			if nLastStatus == -1 then
				self:EmitSound(SndReady)
				self:EmitSound(SndReadyB)
			end
		else
			if status == 1 then
				self.Load = CurTime() + 1.75
			elseif status == 2 then
				self:EmitSound(SndInbound)
				self.FadeCount = 0
			elseif status == 3 then
				self.FadeCount = 255
			end
		end
	end

	function SWEP:DrawInactiveHUD()
		if self.Status == 0 then
			draw.RoundedBoxEx(8, ScrW() - 50, 60, 50, 60, Color(224, 224, 224, 255), true, false, true, false)
			draw.DrawText(
				"Missile\nReady",
				"HudHintTextLarge",
				ScrW() - 4,
				26,
				Color(224, 224, 224, 255),
				TEXT_ALIGN_RIGHT
			)
		end
	end

	function SWEP:CheckFriendly(ent)
		if getCvarBool("ttt_asm_show_colleagues", true) then
			if IsValid(self:GetOwner()) then
				local teamOwn = nil
				if TTT2 then
					teamOwn = self:GetOwner():GetTeam()
				else
					teamOwn = self:GetOwner():GetRole()
				end
				return isFriendly(teamOwn, ent)
			end
			return false
		else
			if ent == LocalPlayer() then
				return true
			end
			return false
		end
	end

	function SWEP:DrawHUD()
		if self.Status > 1 then
			if self.Status == 2 then
				surface.SetDrawColor(0, 0, 0, self.FadeCount)
				surface.DrawRect(0, 0, ScrW(), ScrH())

				if self.FadeCount < 255 then
					self.FadeCount = self.FadeCount + 5
				end
			elseif self.Status > 4 then
				surface.SetDrawColor(0, 0, 0, self.FadeCount)
				surface.DrawRect(0, 0, ScrW(), ScrH())

				if self.FadeCount > 0 then
					self.FadeCount = self.FadeCount - 5
				end
			elseif self.Status == 3 or self.Status == 4 then
				local col = {}
				col["$pp_colour_addr"] = 0
				col["$pp_colour_addg"] = 0
				col["$pp_colour_addb"] = 0
				col["$pp_colour_brightness"] = 0.1
				col["$pp_colour_contrast"] = 1
				col["$pp_colour_colour"] = 0
				col["$pp_colour_mulr"] = 0
				col["$pp_colour_mulg"] = 0
				col["$pp_colour_mulb"] = 0
				DrawColorModify(col)
				DrawSharpen(1, 2)

				local h = ScrH() / 2
				local w = ScrW() / 2
				local ho = 2 * h / 3

				surface.SetDrawColor(160, 160, 160, 255)
				surface.DrawOutlinedRect(w - 48, h - 32, 96, 64)

				surface.DrawLine(w, h - 32, w, h - 128)
				surface.DrawLine(w, h + 32, w, h + 128)
				surface.DrawLine(w - 48, h, w - 144, h)
				surface.DrawLine(w + 48, h, w + 144, h)

				surface.DrawLine(w - ho, h - ho + 64, w - ho, h - ho)
				surface.DrawLine(w - ho, h - ho, w - ho + 64, h - ho)
				surface.DrawLine(w + ho - 64, h - ho, w + ho, h - ho)
				surface.DrawLine(w + ho, h - ho, w + ho, h - ho + 64)
				surface.DrawLine(w + ho, h + ho - 64, w + ho, h + ho)
				surface.DrawLine(w + ho, h + ho, w + ho - 64, h + ho)
				surface.DrawLine(w - ho + 64, h + ho, w - ho, h + ho)
				surface.DrawLine(w - ho, h + ho, w - ho, h + ho - 64)

				local camera = GetViewEntity(LocalPlayer())
				local pos = camera:GetPos()
				surface.SetFont("AsmCamFont")
				surface.SetTextColor(64, 64, 64, 255)

				surface.SetTextPos(24, 16)
				surface.DrawText(
					tostring(math.Round(pos.x))
						.. " "
						.. tostring(math.Round(pos.y))
						.. " "
						.. tostring(math.Round(pos.z))
				)

				surface.SetTextPos(24, 40)
				local dist = self:GetOwner():GetEyeTrace().HitPos:Distance(pos - Vector(0, 0, pos.z))
				surface.DrawText(
					tostring(math.Round(dist)) .. " : " .. tostring(math.Round(camera:GetVelocity():Length()))
				)

				surface.SetTextPos(24, 64)
				surface.DrawText("5 295 [" .. math.Round(CurTime()) .. "]")
				surface.SetTextPos(24, 84)
				surface.SetFont("CloseCaption_Bold")
				local Countdown = math.Round((self.CountdownEnd - CurTime()) * 10) / 10.0
				if math.fmod(math.Round(Countdown), 2) == 0 then
					surface.SetTextColor(220, 220, 220, 255)
				else
					surface.SetTextColor(220, 0, 0, 255)
				end
				surface.DrawText("Time remaining: " .. Countdown)
				surface.SetFont("Default")
				surface.SetTextColor(64, 64, 64, 255)

				local tEnts = player.GetAll()
				for _, ent in pairs(tEnts) do
					if IsValid(ent) then
						local vPos = ent:GetPos() + Vector(0, 0, 0.5 * ent:OBBMaxs().z)
						local scrPos = vPos:ToScreen()
						if self:CheckFriendly(ent) then
							if ent == LocalPlayer() then
								surface.SetDrawColor(64, 255, 64, 160)
								surface.DrawLine(scrPos.x - 16, scrPos.y - 16, scrPos.x + 16, scrPos.y + 16)
								surface.DrawLine(scrPos.x - 16, scrPos.y + 16, scrPos.x + 16, scrPos.y - 16)
							else
								surface.SetDrawColor(64, 64, 255, 160)
								surface.DrawLine(scrPos.x - 16, scrPos.y, scrPos.x + 16, scrPos.y)
								surface.DrawLine(scrPos.x, scrPos.y + 16, scrPos.x, scrPos.y - 16)
							end
						else
							surface.SetDrawColor(255, 64, 64, 160)
						end
						surface.DrawOutlinedRect(scrPos.x - 16, scrPos.y - 16, 32, 32)
					end
				end
				surface.SetTextColor(0, 255, 0, 255)
				surface.SetTextPos(24, 108)
				surface.SetFont("CloseCaption_Bold")
				surface.DrawText("You are green")
				surface.SetTextPos(24, 132)
				surface.SetTextColor(0, 0, 255, 255)
				surface.SetFont("CloseCaption_Bold")
				surface.DrawText("Your teammates are blue")
				surface.SetTextColor(255, 0, 0, 255)
				surface.SetTextPos(24, 156)
				surface.SetFont("CloseCaption_Bold")
				surface.DrawText("Your enemies are red")
			end
		end
	end

	function SWEP:GetViewModelPosition(pos, ang)
		if self:GetModel() == "models/weapons/v_toolgun.mdl" then
			local offset = Vector(-6, 5.6, 0)
			offset:Rotate(ang)
			pos = pos + offset
		end
		return pos, ang
	end

	function SWEP:FreezeMovement()
		if (self.Status > 0) and (self.Status ~= 5) then
			return true
		end
		return false
	end

	function SWEP:HUDShouldDraw(el)
		if self.Status > 2 and self.Status < 7 then
			if el == "CHudGMod" then
				return true
			end
			return false
		end
		return true
	end

	-- Explosion effect

	local EFFECT = {}
	function EFFECT:Init(data)
		self.Pos = data:GetOrigin()
		self.Radius = data:GetRadius()

		sound.Play("ambient/explosions/explode_4.wav", self.Pos, 100, 140, 1)
		sound.Play("npc/env_headcrabcanister/explosion.wav", self.Pos, 100, 140, 1)

		local em = ParticleEmitter(self.Pos)
		for n = 1, 180 do
			local wave = em:Add("particle/particle_noisesphere", self.Pos)
			wave:SetVelocity(Vector(math.sin(math.rad(n * 2)), math.cos(math.rad(n * 2)), 0) * self.Radius * 3)
			wave:SetAirResistance(128)
			wave:SetLifeTime(math.random(0.2, 0.4))
			wave:SetDieTime(math.random(3, 4))
			wave:SetStartSize(64)
			wave:SetEndSize(48)
			wave:SetColor(160, 160, 160)
			wave:SetRollDelta(math.random(-1, 1))
			local fire = em:Add("effects/fire_cloud1", self.Pos + VectorRand() * self.Radius / 2)
			fire:SetVelocity(
				Vector(math.random(-8, 8), math.random(-8, 8), math.random(8, 16)):GetNormal() * math.random(128, 1024)
			)
			fire:SetAirResistance(256)
			fire:SetLifeTime(math.random(0.2, 0.4))
			fire:SetDieTime(math.random(2, 3))
			fire:SetStartSize(80)
			fire:SetEndSize(32)
			fire:SetColor(160, 64, 64, 192)
			fire:SetRollDelta(math.random(-1, 1))
		end
		for n = 1, 16 do
			local smoke = em:Add("particle/particle_noisesphere", self.Pos + 48 * VectorRand() * n)
			smoke:SetVelocity(VectorRand() * math.Rand(32, 96))
			smoke:SetAirResistance(32)
			smoke:SetDieTime(8)
			smoke:SetStartSize((32 - n) * 2 * math.Rand(8, 16))
			smoke:SetEndSize((32 - n) * math.Rand(8, 16))
			smoke:SetColor(160, 160, 160)
			smoke:SetStartAlpha(math.Rand(224, 255))
			smoke:SetEndAlpha(0)
			smoke:SetRollDelta(math.random(-1, 1))
		end
		em:Finish()
	end

	function EFFECT:Think()
		return false
	end
	function EFFECT:Render() end

	effects.Register(EFFECT, "ASM-Explosion")

	hook.Add("HUDPaint", "ASMInactiveHUD", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then
			return
		end

		local wep = ply:GetWeapon("swep_asm")
		if not IsValid(wep) then
			return
		end

		if ply:GetActiveWeapon() == wep then
			return
		end

		if type(wep.DrawInactiveHUD) ~= "function" then
			return
		end

		wep:DrawInactiveHUD()
	end)
end
