if SERVER then
	AddCSLuaFile()
	resource.AddFile("sound/OFB/LTBCKI.wav")
	resource.AddFile("sound/OFB/Shot.wav")
	resource.AddFile("sound/OFB/Fail.wav")
	resource.AddFile("sound/OFB/Secondary.wav")
	resource.AddFile("materials/rainbeam/rainbow1.vmt")
	resource.AddFile("materials/rainbeam/rainbow2d.vmt")
	resource.AddFile("materials/models/weapons/v_vikgun/energy.vmt")
	resource.AddFile("materials/models/weapons/v_vikgun/v_hand_sheet.vmt")
	resource.AddFile("materials/models/weapons/v_vikgun/vikgun.vmt")
    resource.AddFile("materials/VGUI/ttt/icon_ofb_64.jpg")
	resource.AddFile("models/weapons/v_vikgun.mdl")
end

SWEP.EquipMenuData = {
    type = "Orbital Friendship Beam",
    desc = "Let the Magic of Friendship get 'em!"
};
SWEP.HoldType = "shotgun"
SWEP.Base = "weapon_tttbase"
SWEP.PrintName = "Orbital Friendship Beam"
SWEP.Icon = "VGUI/ttt/icon_ofb_64.jpg"
SWEP.Category = "TTT"
SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = true
SWEP.AllowDrop = true 
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.Primary.Recoil	= 5
SWEP.Primary.NumShots = 1
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 30 
SWEP.ViewModel = "models/weapons/v_vikgun.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.Slot = 8
SWEP.ViewModelFOV  = 65
SWEP.ViewModelFlip = false
SWEP.IsCharging = false
SWEP.NextCharge = 0

local AllEffects = {}

local ShootSound = Sound("OFB/LTBCKI.wav")
local FireSound = Sound("OFB/Shot.wav")
local FailSound = Sound("OFB/Fail.wav")
local SeconSound = Sound("OFB/Secondary.wav")
local linex = 0
local liney = 0
local laser = Material("trails/laser")
local maxrange = 800
local math = math

local function around(val)
   return math.Round(val * (10 ^ 3)) / (10 ^ 3);
end

local function ValidTarget(ent)
   return IsValid(ent) and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetPhysicsObject() and (not ent:IsWeapon()) and (not ent:GetNWBool("punched", false))
   -- NOTE: cannot check for motion disabled on client
end

local function kill(index)
    if AllEffects[index] then
        for k, v in pairs(AllEffects[index]) do
            if v and v:IsValid() then 
                v:Remove()
            end
        end
        AllEffects[index] = nil
    end
end

local function start(tr, trace, self, plySteam64)
    local tracedata2 = {}
    tracedata2.start = trace.HitPos
    tracedata2.endpos = trace.HitPos + Vector(0,0,-50000)
    tracedata2.filter = ents.GetAll()
    local trace2 = util.TraceLine(tracedata2)

    -- Glow at the bottom of the fsm
    self.glow = ents.Create("env_lightglow")
	self.glow:SetKeyValue("rendercolor", "255 255 255")
    self.glow:SetKeyValue("VerticalGlowSize", "40")
    self.glow:SetKeyValue("HorizontalGlowSize", "40")
    self.glow:SetKeyValue("MaxDist", "500")
    self.glow:SetKeyValue("MinDist", "0")
    self.glow:SetKeyValue("HDRColorScale", "100")
    self.glow:SetPos(trace2.HitPos + Vector(0,0,32))
    self.glow:Spawn()
    
    -- Duplicate glow at the bottom of the fsm
    self.glow2 = ents.Create("env_lightglow")
	self.glow2:SetKeyValue("rendercolor", "255 255 255")
    self.glow2:SetKeyValue("VerticalGlowSize", "40")
    self.glow2:SetKeyValue("HorizontalGlowSize", "40")
    self.glow2:SetKeyValue("MaxDist", "500")
    self.glow2:SetKeyValue("MinDist", "0")
    self.glow2:SetKeyValue("HDRColorScale", "100")
    self.glow2:SetPos(trace2.HitPos + Vector(0,0,32))
    self.glow2:Spawn()
    
    -- Glow at the top of the fsm
    self.glow3 = ents.Create("env_lightglow")
	self.glow3:SetKeyValue("rendercolor", "255 255 255")
    self.glow3:SetKeyValue("VerticalGlowSize", "30")
    self.glow3:SetKeyValue("HorizontalGlowSize", "30")
    self.glow3:SetKeyValue("MaxDist", "500")
    self.glow3:SetKeyValue("MinDist", "0")
    self.glow3:SetKeyValue("HDRColorScale", "100")
    self.glow3:SetPos(trace2.HitPos + Vector(0,0,27000))
    self.glow3:Spawn()
    
    -- Dummy target of the laser
    self.targ = ents.Create("info_target")
    self.targ:SetKeyValue("targetname", tostring(self.targ))
    self.targ:SetPos(tr.HitPos + Vector(0, 0, -50000))
    self.targ:Spawn()
    
    -- The actual beam
    self.laser = ents.Create("env_laser")
    self.laser.OrbitalFriendshipBeam = true
    self.laser.Owner = plySteam64
    self.laser:SetKeyValue("texture", "rainbeam/rainbow1.vmt")
    self.laser:SetKeyValue("TextureScroll", "100")
    self.laser:SetKeyValue("noiseamplitude", "0")
    self.laser:SetKeyValue("width", "512")
    self.laser:SetKeyValue("damage", "10000")
    self.laser:SetKeyValue("rendercolor", "255 255 255")
    self.laser:SetKeyValue("renderamt", "255")
    self.laser:SetKeyValue("dissolvetype", "0")
    self.laser:SetKeyValue("lasertarget", tostring(self.targ))
    self.laser:SetPos(trace.HitPos)
    self.laser:Spawn()
    self.laser:Fire("turnon", 0)
	
    -- Pseudo laser beam outside of skybox
    self.effects = ents.Create("effects")
    self.effects:SetPos(trace.HitPos)
    self.effects:Spawn()
    
    -- Pushes away corpses from beam
    self.remover = ents.Create("remover")
    self.remover:SetPos(trace.HitPos)
    self.remover:Spawn()
    
    self.blastwave = ents.Create("blastwave")
    self.blastwave.OrbitalFriendshipBeam = true
    self.blastwave.Owner = plySteam64
    self.blastwave:SetPos(trace2.HitPos)
    self.blastwave:Spawn()

    local index = self:EntIndex()
    AllEffects[index] = {}
    table.insert(AllEffects[index], self.targ)
    table.insert(AllEffects[index], self.effects)
    table.insert(AllEffects[index], self.remover)
    table.insert(AllEffects[index], self.blastwave)
    table.insert(AllEffects[index], self.glow)
    table.insert(AllEffects[index], self.glow2)
    table.insert(AllEffects[index], self.glow3)
    table.insert(AllEffects[index], self.laser)
    table.insert(AllEffects[index], self)
    timer.Simple(GetConVar("ttt_ofb_duration"):GetFloat(), function() kill(index) end)
end

AccessorFunc(SWEP, "charge", "Charge")

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "charge")
end

function SWEP:Initialize()
    return self.BaseClass.Initialize(self)
end

function SWEP:PreDrop()
    self.IsCharging = false
    self:SetCharge(0)
    -- OnDrop does not happen on client
end

function SWEP:ViewModelDrawn()
    local client = LocalPlayer()
    local vm = client:GetViewModel()
    if not IsValid(vm) then 
        return 
    end

    local plytr = client:GetEyeTrace(MASK_SHOT)

    local muzzle_angpos = vm:GetAttachment(1)
    local spos = muzzle_angpos.Pos + muzzle_angpos.Ang:Forward() * 10
    local epos = client:GetShootPos() + client:GetAimVector() * maxrange

    -- Painting beam
    local tr = util.TraceLine({start=spos, endpos=epos, filter=client, mask=MASK_ALL})

    local c = COLOR_WHITE
    local a = 255
    
    if LocalPlayer():IsTraitor() then
        c = COLOR_WHITE
        a = 255
    else
        c = COLOR_RED
    end

    render.SetMaterial(laser)
    render.DrawBeam(spos, tr.HitPos, 5, 0, 0, c)

    -- Charge indicator
    local vm_ang = muzzle_angpos.Ang
    local cpos = muzzle_angpos.Pos + (vm_ang:Up() * -4) + (vm_ang:Forward() * -18) + (vm_ang:Right() * -7)
    local cang = vm:GetAngles()
    cang:RotateAroundAxis(cang:Forward(), 90)
    cang:RotateAroundAxis(cang:Right(), 90)
    cang:RotateAroundAxis(cang:Up(), 90)

    cam.Start3D2D(cpos, cang, 0.05)

    surface.SetDrawColor(255, 55, 55, 50)
    surface.DrawOutlinedRect(0, 0, 50, 15)

    local sz = 48
    local next = self:GetNextPrimaryFire()
    local ready = (next - CurTime()) <= 0
    local frac = 1.0
    if not ready then
        frac = 1 - ((next - CurTime()) / 5)
        sz = sz * math.max(0, frac)
    end

    surface.SetDrawColor(255, 10, 10, 170)
    surface.DrawRect(1, 1, sz, 13)

    surface.SetTextColor(255,255,255,15)
    surface.SetFont("Default")
    surface.SetTextPos(10,0)
    surface.DrawText("Target")

    surface.SetDrawColor(0,0,0, 80)
    surface.DrawRect(linex, 1, 3, 13)

    surface.DrawLine(1, liney, 48, liney)

    linex = linex + 3 > 48 and 0 or linex + 1
    liney = liney > 13 and 0 or liney + 1

    cam.End3D2D()

end

function SWEP:Reload()
    self:EmitSound(FireSound)
end

function SWEP:PrimaryAttack()
    local tr = self:GetOwner():GetEyeTrace()
    local tracedata = {}
	
    tracedata.start = tr.HitPos + Vector(0,0,0)
    tracedata.endpos = tr.HitPos + Vector(0,0,50000)
    tracedata.filter = ents.GetAll()
    local trace = util.TraceLine(tracedata)
	if trace.HitSky == true then
        hitsky = true	
    else
        hitsky = true
    end
    
    if hitsky == true then
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:EmitSound(ShootSound)
    else
        self:EmitSound(FailSound)
    end
    
    if (SERVER) then 
        if hitsky == true then
            self:TakePrimaryAmmo(1)
            local ply = self:GetOwner():SteamID64()
            timer.Simple(GetConVar("ttt_ofb_startDelay"):GetFloat(), function() start(tr, trace, self, ply) end)
        end
    end
end

function SWEP:SecondaryAttack()   
    self:EmitSound(SeconSound)
end

function SWEP:ShouldDropOnDie()
    return false
end

-- PSEUDO RAINBOW EFFECT OUTSIDE OF SKYBOX BLOCK
do
    local ENT = {}
    ENT.Type = "anim"
    ENT.Base = "base_anim"
    ENT.PrintName = "effects"
    ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
    if (CLIENT) then
        local EFFECT={} 
        function EFFECT:Init(data)
            local Laser = Material("rainbeam/rainbow2d.vmt")
            local tracedata = {}
    
            tracedata.start = data:GetOrigin() + Vector(0,0,-10)
            tracedata.endpos = data:GetOrigin() + Vector(0,0,-50000)
    
            local trace = util.TraceLine(tracedata)
            local a = data:GetOrigin()
            local b = trace.HitPos + Vector(0,0,27000)
    
            render.SetMaterial(Laser)
            render.DrawBeam(b,a, 200, -1, -1, Color(255, 255, 255, 255))
        end
        effects.Register(EFFECT,"beam") 
    end
    
    function ENT:Draw(data)
        local d = EffectData()
        d:SetOrigin(self:GetPos()) 
        util.Effect("beam", d)
    end 
    
    scripted_ents.Register(ENT, "effects", true)    
end

-- NO ACTUAL EFFECT BUT PUSHES AWAY CORPSES BLOCK
do
    local ENT = {}
    ENT.Type = "point"
    ENT.Base = "base_point"
    ENT.PrintName = "remover"
    ENT.RenderGroup = RENDERGROUP_OTHER

    if (CLIENT) then
        --Explosion effects
        local EFFECT={} 
        function EFFECT:Init(dat)
            -- Unused effect for whatever reason
        end
        effects.Register(EFFECT,"poof") 
    end

    function ENT:Think()
        local tracedata3 = {}
        tracedata3.start = self:GetPos()
        tracedata3.endpos = self:GetPos() + Vector(0,0,-50000)
        tracedata3.filter = ents.GetAll()
        local trace3 = util.TraceLine(tracedata3)

        if (!SERVER) then 
            return 
        end
        local targets = ents.FindInBox(trace3.HitPos + Vector(-16,-16,0), self:GetPos() + Vector(16,16,0))

        for k, v in pairs(targets) do
            if (v:GetClass() != "prop_ragdoll" && v:GetMoveType() == 6) then
                v:Remove()
            end
            if (v:GetClass() == "prop_ragdoll") then
                local bones = v:GetPhysicsObjectCount()
                for bone = 0, bones-1 do
                    local phys = v:GetPhysicsObjectNum(bone)
                    if phys:IsValid()then
                        phys:SetPos(phys:GetPos() + Vector(100,0,0))
                        phys:Wake()
                    end
                end
            end 
        end
    end

    scripted_ents.Register(ENT, "remover", true)
end

--[[if SERVER then
    util.AddNetworkString("TESTDRAW")
end

net.Receive("TESTDRAW", function(len, ply)
    local pos = net.ReadVector()
    local radius = 256
    local wideSteps = 10
    local tallSteps = 10
    hook.Add( "PostDrawTranslucentRenderables", "test", function()
        render.SetColorMaterial()
        render.DrawSphere( pos, radius, wideSteps, tallSteps, Color( 0, 175, 175, 100 ) )
        render.DrawWireframeSphere( pos, radius, wideSteps, tallSteps, Color( 255, 255, 255, 255 ) )
    end )
end)]]

-- BLASTWAVE EFFECT BLOCK
do
    local ENT = {}
    ENT.Type = "point" -- Avoids this from being drawn, because it shouldn't
    ENT.Base = "base_point" -- Avoids this from being drawn, because it shouldn't
    ENT.PrintName = "blastwave"
    ENT.RenderGroup = RENDERGROUP_OTHER -- Avoids this from being drawn, because it shouldn't
    if (CLIENT) then
        local EFFECT = {}
    
        function EFFECT:Init(data)
            local start = data:GetOrigin()
            local em = ParticleEmitter(start)
            for i=1, 1024 do
                local part = em:Add("particle/smokesprites_0009", start) --Shockwave
                if part then
                    part:SetVelocity(Vector(math.random(-10,10),math.random(-10,10),0):GetNormal() * math.random(1700,2000))
                    local rad = math.abs(math.atan2(part:GetVelocity().x,part:GetVelocity().y))
                    local angle = (rad/math.pi*1536)
                    if(angle < 255 && angle >= 0) then
                        part:SetColor(255,angle,0)
                    end
                    if(angle < 511 && angle >= 255) then
                        part:SetColor(511-angle,255,0)
                    end   
                    if(angle < 767 && angle >= 511) then
                        part:SetColor(0,255,angle-511)
                    end
                    if(angle < 1023 && angle >= 767) then
                        part:SetColor(0,1023-angle,255)
                    end 
                    if(angle < 1279 && angle >= 1023) then
                        part:SetColor(angle-1023,0,255)
                    end
                    if(angle < 1535 && angle >= 1279) then
                        part:SetColor(255,0,1535-angle)
                    end 
                    if(angle > 1535) then
                        part:SetColor(255,0,0)
                    end
    
                    part:SetDieTime(math.random(5,6))
                    part:SetLifeTime(math.random(1,2))
                    if (math.Dist(0,0,part:GetVelocity().x,part:GetVelocity().y) >= 1500) then    
                        part:SetStartSize((math.Dist(0,0,part:GetVelocity().x,part:GetVelocity().y)-1600)/4)
                        part:SetEndSize(math.Dist(0,0,part:GetVelocity().x,part:GetVelocity().y)-1600)
                    else
                        part:SetStartSize(0)
                        part:SetEndSize(0)
                    end
                    part:SetAirResistance(5)
                    part:SetRollDelta(math.random(-2,2))
                end
            end  
            for i=1,512 do
                local part1 = em:Add("particle/smokesprites_0010", start) --Main Explosion
                if part1 then                                               
                    part1:SetVelocity(Vector(math.random(-100,100),math.random(-100,100),math.random(-3,3)):GetNormal() * math.random(100,2400))
                    part1:SetColor(255,255,255)
                    part1:SetDieTime(math.random(5,6))
                    part1:SetLifeTime(math.random(0.3,0.5))
                    part1:SetStartSize(150 - (math.Dist(0,0,part1:GetVelocity().x,part1:GetVelocity().y))/16)
                    part1:SetEndSize(600 - (math.Dist(0,0,part1:GetVelocity().x,part1:GetVelocity().y))/4) 
                    part1:SetAirResistance(50)
                    part1:SetRollDelta(math.random(-2,2))
                end
                local part2 = em:Add("particle/smokesprites_0010", start) --Secondary Shockwave
                if part2 then
                    part2:SetVelocity(Vector(math.random(-10,10),math.random(-10,10),0):GetNormal() * 2000)
                    part2:SetColor(255,255,255)
                    part2:SetDieTime(math.random(5,6))
                    part2:SetLifeTime(math.random(0.5,1))
                    part2:SetStartSize(10)
                    part2:SetEndSize(math.random(80,120)) 
                    part2:SetAirResistance(math.random(30,31))
                    part2:SetRollDelta(math.random(-2,2))
                end
            end
            em:Finish()
        end

        effects.Register(EFFECT,"wave") 
    end

    function ENT:Initialize()
        if !SERVER then 
            return 
        end

        --print("Initialize", self:GetPos())
        --[[net.Start("TESTDRAW")
        net.WriteVector(self:GetPos())
        net.Broadcast()]]
    
        local e = EffectData()
        e:SetOrigin(self:GetPos() + Vector(0,0,64)) 
        util.Effect("wave", e)
        util.ScreenShake(self:GetPos(), 50, 55, 15, 5000)
    end

    function ENT:Think()
        if !SERVER then
            return
        end

        local rad = 256
        local targets2 = ents.FindInSphere(self:GetPos(), rad)
        local pos = self:GetPos()
        if self.OrbitalFriendshipBeam and self:GetOwner() then
            local inf = ents.Create("swep_orbitalfriendshipbeam")
            for k, f in pairs(targets2) do
                if (IsValid(f) and f:IsPlayer() and f:Alive()) then
                    local dmg = math.Round(30 * (f:GetPos() - pos):Length() / rad)
                    local dmg = dmg > 0 and dmg or 0
                    local dmginfo = DamageInfo()
                    dmginfo:SetInflictor(inf)
                    dmginfo:SetDamage(dmg)
                    local ply = player.GetBySteamID64(self:GetOwner())
                    --print("Ply", ply, self:GetOwner())
                    if ply then
                        dmginfo:SetAttacker(ply)
                    end
                    dmginfo:SetDamageType(DMG_ENERGYBEAM)
                    f:TakeDamageInfo(dmginfo) 
                end
            end
        end
    end

    scripted_ents.Register(ENT, "blastwave", true)    
end

hook.Add("EntityTakeDamage", "ttt_ofb_damage", function(target, dmginfo)
    local inflictor = dmginfo:GetInflictor()
    --print("Attacker", dmginfo:GetAttacker())
    --print(target, target and target:IsPlayer(), inflictor, inflictor and inflictor.OrbitalFriendshipBeam, inflictor and inflictor.Owner, inflictor and inflictor.GetClass and inflictor:GetClass())
    if (target:IsPlayer() and inflictor and inflictor.OrbitalFriendshipBeam and inflictor.Owner) then
        --print(target:IsPlayer(), inflictor, inflictor.OrbitalFriendshipBeam, inflictor.Owner)
        dmginfo:SetDamageType(DMG_ENERGYBEAM)
        dmginfo:SetInflictor(ents.Create("swep_orbitalfriendshipbeam"))
        local ply = player.GetBySteamID64(inflictor.Owner)
        if ply then
            dmginfo:SetAttacker(ply)
        end
	end
end)
