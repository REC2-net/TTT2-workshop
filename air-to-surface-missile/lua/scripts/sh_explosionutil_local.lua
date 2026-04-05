ExplosionUtil = ExplosionUtil or {}
ExplosionUtil.__index = ExplosionUtil

local registeredExplosions = registeredExplosions or 0

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

local function isFriendly(teamId, ply)
	if not teamId or not IsValid(ply) or not ply:IsPlayer() then
		return false
	end

	if TTT2 and ply.GetTeam then
		return ply:GetTeam() == teamId
	end

	if ply.GetRole then
		return ply:GetRole() == teamId
	end

	return false
end

local function getBlockInfo(ent, ply, pos, samples, mask)
	local connection = ply:GetPos() - pos

	local normal
	if connection.x == 0 and connection.y == 0 and connection.z ~= 0 then
		normal = Vector(1, 0, 0)
	else
		normal = Vector(0, 0, 1):Cross(connection)
	end
	normal:Normalize()

	local mid = pos
	local right = pos + normal * 10
	local left = pos - normal * 10

	local tr1 = util.TraceLine({
		start = mid,
		endpos = mid + connection + Vector(0, 0, 50),
		filter = ent,
		mask = mask,
	})
	if not tr1.Hit then
		return false, left, right, connection
	end

	if samples <= 1 then
		return true, left, right, connection
	end

	local tr2 = util.TraceLine({
		start = left,
		endpos = left + connection + Vector(0, 0, 50),
		filter = ent,
		mask = mask,
	})
	local tr3 = util.TraceLine({
		start = right,
		endpos = right + connection + Vector(0, 0, 50),
		filter = ent,
		mask = mask,
	})

	if samples <= 3 then
		return tr2.Hit and tr3.Hit, left, right, connection
	end

	local tr4 = util.TraceLine({
		start = left + Vector(0, 0, 100),
		endpos = left + connection + Vector(0, 0, 50),
		filter = ent,
		mask = mask,
	})
	local tr5 = util.TraceLine({
		start = mid + Vector(0, 0, 100),
		endpos = mid + connection + Vector(0, 0, 50),
		filter = ent,
		mask = mask,
	})
	local tr6 = util.TraceLine({
		start = right + Vector(0, 0, 100),
		endpos = right + connection + Vector(0, 0, 50),
		filter = ent,
		mask = mask,
	})

	return tr2.Hit and tr3.Hit and tr4.Hit and tr5.Hit and tr6.Hit, left, right, connection
end

function ExplosionUtil:new()
	local newExplosionUtil = { Id = registeredExplosions }

	if SERVER then
		util.AddNetworkString("Explosion" .. registeredExplosions .. "NetworkString")
	end

	if CLIENT then
		local id = registeredExplosions
		net.Receive("Explosion" .. id .. "NetworkString", function()
			local hit = net.ReadVector()
			local radius = net.ReadUInt(16)
			local baseDamage = net.ReadUInt(16)
			local left = net.ReadVector()
			local right = net.ReadVector()
			local connection = net.ReadVector()
			local hasBlockInformation = net.ReadBool()
			local mid = hit

			hook.Add("PostDrawTranslucentRenderables", "Explosion" .. id .. "HitSphere", function()
				render.SetColorMaterial()

				local safeBaseDamage = math.max(1, baseDamage)
				local radiusSqr = radius * radius
				local yArg = radiusSqr - (radiusSqr * 100) / safeBaseDamage
				local zArg = radiusSqr - (radiusSqr * 50) / safeBaseDamage

				local y = math.Clamp(math.sqrt(math.max(0, yArg)), 0, radius)
				local z = math.Clamp(math.sqrt(math.max(0, zArg)), 0, radius)

				render.DrawWireframeSphere(hit, y, 10, 10, Color(255, 0, 0, 255))
				render.DrawWireframeSphere(hit, z, 10, 10, Color(255, 255, 0, 255))
				render.DrawWireframeSphere(hit, radius, 10, 10, Color(0, 255, 0, 255))

				if hasBlockInformation then
					render.DrawLine(left, left + connection + Vector(0, 0, 50), Color(255, 255, 255))
					render.DrawLine(mid, mid + connection + Vector(0, 0, 50), Color(255, 255, 255))
					render.DrawLine(right, right + connection + Vector(0, 0, 50), Color(255, 255, 255))
					render.DrawLine(
						left + Vector(0, 0, 100),
						left + connection + Vector(0, 0, 50),
						Color(255, 255, 255)
					)
					render.DrawLine(mid + Vector(0, 0, 100), mid + connection + Vector(0, 0, 50), Color(255, 255, 255))
					render.DrawLine(
						right + Vector(0, 0, 100),
						right + connection + Vector(0, 0, 50),
						Color(255, 255, 255)
					)
				end
			end)

			timer.Create("Explosion" .. id .. "HitSphereTimer", 10, 1, function()
				hook.Remove("PostDrawTranslucentRenderables", "Explosion" .. id .. "HitSphere")
			end)
		end)
	end

	setmetatable(newExplosionUtil, ExplosionUtil)
	registeredExplosions = registeredExplosions + 1
	return newExplosionUtil
end

function ExplosionUtil:Explode(
	ent,
	pos,
	baseDamage,
	radius,
	attacker,
	inflictor,
	effect,
	debug,
	associatedTeam,
	ownerUserId
)
	effect = effect or "Explosion"
	baseDamage = baseDamage or 100
	radius = radius or 200
	debug = debug or false

	local effd = EffectData()
	effd:SetStart(pos)
	effd:SetOrigin(pos)
	effd:SetScale(1)
	effd:SetRadius(radius)
	effd:SetEntity(NULL)
	util.Effect(effect, effd)

	if not IsValid(attacker) then
		attacker = ent
	end

	if not IsValid(inflictor) then
		inflictor = ent
	end

	local radiusSqr = radius * radius
	local respectWalls = getCvarBool("ttt_asm_explosion_respect_walls", true)
	local samples = math.Clamp(getCvarInt("ttt_asm_explosion_wallcheck_samples", 6), 0, 6)
	local mask = MASK_NPCWORLDSTATIC

	local damageOwner = getCvarBool("ttt_asm_damage_owner", true)
	local friendlyFire = getCvarBool("ttt_asm_friendlyfire", true)

	local debugNet = debug and IsValid(attacker) and attacker:IsPlayer()
	local debugLeft = pos
	local debugRight = pos
	local debugConn = Vector(0, 0, 0)
	local debugHasBlockInfo = false

	if debugNet then
		net.Start("Explosion" .. self.Id .. "NetworkString")
		net.WriteVector(pos)
		net.WriteUInt(math.Clamp(radius, 0, 65535), 16)
		net.WriteUInt(math.Clamp(baseDamage, 0, 65535), 16)
	end

	local d = DamageInfo()
	d:SetAttacker(attacker)
	d:SetInflictor(inflictor)
	d:SetDamageType(DMG_BLAST)

	for _, ply in ipairs(ents.FindInSphere(pos, radius)) do
		if IsValid(ply) and (ply:IsPlayer() or ply:IsNPC()) then
			local allowDamage = true

			if ply:IsPlayer() then
				if ownerUserId and ply:UserID() == ownerUserId and not damageOwner then
					allowDamage = false
				end

				if not friendlyFire and isFriendly(associatedTeam, ply) then
					allowDamage = false
				end
			end

			if allowDamage then
				local distSqr = ply:GetPos():DistToSqr(pos)
				local dmg = baseDamage * ((radiusSqr - distSqr) / radiusSqr)

				if dmg > 0 then
					local blocked = false
					if respectWalls and samples > 0 and ply:IsPlayer() then
						local behindWall, left, right, conn = getBlockInfo(ent, ply, pos, samples, mask)
						blocked = behindWall

						if debugNet and behindWall and not debugHasBlockInfo then
							debugHasBlockInfo = true
							debugLeft = left
							debugRight = right
							debugConn = conn
						end
					end

					if not blocked then
						d:SetDamage(dmg)
						ply:TakeDamageInfo(d)
					end
				end
			end
		end
	end

	if debugNet then
		net.WriteVector(debugLeft)
		net.WriteVector(debugRight)
		net.WriteVector(debugConn)
		net.WriteBool(debugHasBlockInfo)
		net.Send(attacker)
	end

	SafeRemoveEntityDelayed(ent, 0)
end

setmetatable(ExplosionUtil, { __call = ExplosionUtil.new })
