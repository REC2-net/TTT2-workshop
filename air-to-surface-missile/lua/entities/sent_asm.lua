ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Air-to-surface Missile"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.AssociatedTeam = nil
ENT.UserID = nil

local SndLoop = Sound("weapons/rpg/rocket1.wav")
local SndFire = Sound("weapons/stinger_fire1.wav")
local SndBoost = Sound("weapons/rpg/rocketfire1.wav")

if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("ASM-Hit")
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
		if IsValid(phys) then
			phys:EnableGravity(false)
			phys:Wake()
		end
	end
end

function ENT:Launch()
	self:SetTrail()
	self:EmitSound(SndFire)
	self:SetColor(Color(0, 0, 0, 255))
	if self.Sound then
		self.Sound:Play()
	end
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

	local vel = Vector(0, 0, -24)
	if IsValid(self.SWEP) and self.SWEP.Status == 3 then
		vel = Vector(0, 0, -4)
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:AddVelocity(vel)
	end

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
		self.Exploded = true

		local vPos = self:GetPos() - Vector(0, 0, self:OBBMaxs().z + 50)
		if IsValid(self.SWEP) then
			timer.Simple(0, function()
				if IsValid(self.SWEP) then
					self.SWEP:UnlockPlayer()
				end
			end)
		end

		local owner = self:GetOwner()
		if IsValid(owner) then
			owner:SetViewEntity(owner)
		end

		local baseDamage = GetConVar("ttt_asm_missile_blast_damage"):GetInt()
		local radius = GetConVar("ttt_asm_missile_blast_radius"):GetInt()

		util.BlastDamage(self, IsValid(owner) and owner or self, vPos, radius, baseDamage)

		local effd = EffectData()
		effd:SetStart(vPos)
		effd:SetOrigin(vPos)
		effd:SetScale(1)
		effd:SetRadius(radius)
		effd:SetEntity(NULL)
		util.Effect("ASM-Explosion", effd)

		util.ScreenShake(vPos, 15, 15, 4, 1000)
		util.Decal("Scorch", vPos + Vector(0, 0, 1), vPos - Vector(0, 0, 1))

		self:Remove()
	end
end

function ENT:SetTrail()
	local ent = ents.Create("env_spritetrail")
	if not IsValid(ent) then
		return
	end

	ent:SetPos(self:GetPos() + Vector(0, 0, 10))
	ent:SetAngles(self:GetAngles())
	ent:SetKeyValue("lifetime", "6.0")
	ent:SetKeyValue("startwidth", "32.0")
	ent:SetKeyValue("endwidth", "10.0")
	ent:SetKeyValue("renderamt", "100")
	ent:SetKeyValue("rendercolor", "128 128 128")
	ent:SetKeyValue("rendermode", "0")
	ent:SetKeyValue("spritename", "trails/smoke.vmt")
	ent:SetParent(self)
	ent:Spawn()

	self.Trail = ent
end

function ENT:Draw()
	if not IsValid(LocalPlayer()) then
		self:DrawModel()
		return
	end
	local wep = LocalPlayer():GetActiveWeapon()
	if IsValid(wep) and wep.IsAsmSWEP then
		if wep.Status == 2 or wep.Status == 3 then
			return
		end
	end
	self:DrawModel()
end

function ENT:OnRemove()
	if SERVER then
		if self.Sound then
			self.Sound:Stop()
			self.Sound = nil
		end

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
