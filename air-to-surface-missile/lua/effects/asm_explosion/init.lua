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
		wave:SetLifeTime(math.Rand(0.2, 0.4))
		wave:SetDieTime(math.Rand(3, 4))
		wave:SetStartSize(64)
		wave:SetEndSize(48)
		wave:SetColor(160, 160, 160)
		wave:SetRollDelta(math.Rand(-1, 1))

		local fire = em:Add("effects/fire_cloud1", self.Pos + VectorRand() * self.Radius / 2)
		fire:SetVelocity(
			Vector(math.random(-8, 8), math.random(-8, 8), math.random(8, 16)):GetNormal() * math.random(128, 1024)
		)
		fire:SetAirResistance(256)
		fire:SetLifeTime(math.Rand(0.2, 0.4))
		fire:SetDieTime(math.Rand(2, 3))
		fire:SetStartSize(80)
		fire:SetEndSize(32)
		fire:SetColor(160, 64, 64, 192)
		fire:SetRollDelta(math.Rand(-1, 1))
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
		smoke:SetRollDelta(math.Rand(-1, 1))
	end

	em:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render() end

effects.Register(EFFECT, "ASM-Explosion")
