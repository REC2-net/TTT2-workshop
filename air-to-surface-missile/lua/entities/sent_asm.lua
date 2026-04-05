if SERVER then
	AddCSLuaFile()
	if file.Exists("scripts/sh_explosionutil.lua", "LUA") then
		AddCSLuaFile("scripts/sh_explosionutil.lua")
		print(
			"[INFO][Air-to-Surface Missile] Using the utility plugin to handle explosions instead of the local version"
		)
	else
		AddCSLuaFile("scripts/sh_explosionutil_local.lua")
		print(
			"[INFO][Air-to-Surface Missile] Using the local version to handle explosions instead of the utility plugin"
		)
	end
end

if file.Exists("scripts/sh_explosionutil.lua", "LUA") then
	include("scripts/sh_explosionutil.lua")
else
	include("scripts/sh_explosionutil_local.lua")
end

ENT.Explosion = ExplosionUtil()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Air-to-surface Missile"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.AssociatedTeam = nil
ENT.UserID = nil

local SndLoop = Sound("weapons/rpg/rocket1.wav")
local SndFire = Sound("weapons/stinger_fire1.wav")
local SndBoost = Sound("weapons/rpg/rocketfire1.wav")

local function getCvarBool(name, fallback)
	local cvar = GetConVar(name)
	if not cvar then
		return fallback
	end

	return cvar:GetBool()
end

local function getCvarInt(name, fallback)
	local cvar = GetConVar(name)
	if not cvar then
		return fallback
	end

	return cvar:GetInt()
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_phx/mk-82.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetColor(Color(0, 0, 0, 0))
		self.Launched = false
		self.Exploded = false
		self.Sound = CreateSound(self, SndLoop)

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableGravity(false)
			phys:Wake()
		end
	end
end

function ENT:Launch()
	self:SetTrail()
	self:EmitSound(SndFire)
	self:SetColor(Color(0, 0, 0, 255))
	self.Sound:Play()
	self.Launched = true
end

function ENT:Boost()
	self:EmitSound(SndBoost)
end

function ENT:Think()
	if not SERVER then
		return
	end
	if not self.Launched then
		return
	end

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then
		self:NextThink(CurTime() + 0.05)
		return true
	end

	local vel = Vector(0, 0, -24)
	if IsValid(self.SWEP) and self.SWEP.Status == 3 then
		vel = Vector(0, 0, -4)
	end
	phys:AddVelocity(vel)

	self:NextThink(CurTime() + 0.01)
	return true
end

function ENT:PhysicsCollide(data, physobj)
	self:Explode()
end

function ENT:Explode()
	if self.Sound then
		self.Sound:Stop()
		self.Sound = nil
	end

	if not self.Exploded then
		local vPos = self:GetPos() - Vector(0, 0, self:OBBMaxs().z + 50)
		if IsValid(self.SWEP) then
			timer.Simple(0, function()
				if IsValid(self.SWEP) then
					self.SWEP:UnlockPlayer()
				end
			end)
		end
		if IsValid(self:GetOwner()) then
			self:GetOwner():SetViewEntity(self:GetOwner())
		end

		local baseDamage = getCvarInt("ttt_asm_missile_blast_damage", 110)
		local radius = getCvarInt("ttt_asm_missile_blast_radius", 384)
		local debug = getCvarBool("ttt_asm_show_debug", false)
		local attacker = self:GetOwner()
		if not IsValid(attacker) and IsValid(self.SWEP) then
			attacker = self.SWEP:GetOwner()
		end
		local inflictor = IsValid(self.SWEP) and self.SWEP or self
		self.Explosion:Explode(
			self,
			vPos,
			baseDamage,
			radius,
			attacker,
			inflictor,
			"ASM-Explosion",
			debug,
			self.AssociatedTeam,
			self.UserID
		)

		util.ScreenShake(vPos, 15, 15, 4, 1000)
		util.Decal("Scorch", vPos + Vector(0, 0, 1), vPos - Vector(0, 0, 1))

		self.Exploded = true
	end
end

function ENT:SetTrail()
	local trail = ents.Create("env_spritetrail")
	trail:SetPos(self:GetPos() + Vector(0, 0, 10))
	trail:SetAngles(self:GetAngles())
	trail:SetKeyValue("lifetime", "6.0")
	trail:SetKeyValue("startwidth", "32.0")
	trail:SetKeyValue("endwidth", "10.0")
	trail:SetKeyValue("renderamt", "100")
	trail:SetKeyValue("rendercolor", "128 128 128")
	trail:SetKeyValue("rendermode", "0")
	trail:SetKeyValue("spritename", "trails/smoke.vmt")
	trail:SetParent(self)
	trail:Spawn()
	self.Trail = trail
end

function ENT:Draw()
	local wep = LocalPlayer():GetActiveWeapon()
	if wep and wep.IsAsmSWEP and ((wep.Status == 2) or (wep.Status == 3)) then
		return
	end
	self:DrawModel()
end

function ENT:OnRemove()
	if SERVER then
		if IsValid(self.SWEP) then
			self.SWEP:MissileEndPhase()
		end
		if IsValid(self.Trail) then
			local trail = self.Trail
			trail:SetParent(nil)
			timer.Simple(5, function()
				if IsValid(trail) then
					trail:Remove()
				end
			end)
		end
	end
end
