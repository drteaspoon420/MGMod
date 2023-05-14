day_7 = class({})


--function day_7:GetTexture() return "kumamoto" end
function day_7:IsPermanent() return true end
function day_7:RemoveOnDeath() return false end
function day_7:IsHidden() return true end
function day_7:IsDebuff() return false end
function day_7:IsPurgable() return false end
function day_7:IsPurgeException() return false end
function day_7:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function day_7:DeclareFunctions()
	local funcs = {
	}
	return funcs
end

function day_7:OnCreated(kv)
    if not IsServer() then return end
    self:StartIntervalThink(20)
end

function day_7:OnIntervalThink()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if not hParent:IsAlive() or hParent:HasModifier("modifier_fountain_aura_buff") then return end
    local hEnemy = self:FindRandomHero(((hParent:GetTeam()+1)%DOTA_TEAM_GOODGUYS)+DOTA_TEAM_GOODGUYS)
    if hEnemy == nil then return end
    local hNeutral = self:FindAnyNeutral()
    if hNeutral == nil then return end
    local vPos = self:FindRandomPosition(hParent:GetAbsOrigin())
    local illusion_keys = {
        outgoing_damage =  1.0,
        incoming_damage =  1000.0,
        bounty_base =  0.0,
        bounty_growth =  0.0,
        outgoing_damage_structure = 0.0,
        outgoing_damage_roshan = 0.0,
        duration = RandomFloat(20.0,40.0),
    }
   -- print("creating illusion of", hEnemy:GetUnitName(), "at", hParent:GetUnitName())
    local hIllusion = CreateIllusions(hNeutral, hEnemy, illusion_keys, 1, 0, false, false)
    if hIllusion ~= nil and hIllusion[1] ~= nil and hIllusion[1].SetAbsOrigin ~= nil then
        hIllusion[1]:SetAbsOrigin(vPos)
        hParent:MakeVisibleToTeam(hNeutral:GetTeam(),illusion_keys.duration)
        FindClearSpaceForUnit(hIllusion[1],vPos,false)
        local tOrder = {
            OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
            TargetIndex = hParent:entindex(), --:GetAbsOrigin(),
            UnitIndex = hIllusion[1]:entindex()
        }
        ExecuteOrderFromTable(tOrder)
    end
    self:StartIntervalThink(RandomFloat(20.0,40.0))
end

function day_7:FindRandomPosition(vPos)
    local nPos = vPos
    local iTeam = self:GetParent():GetTeam()
    local c = 0
    while IsLocationVisible(DOTA_TEAM_GOODGUYS,vPos) or IsLocationVisible(DOTA_TEAM_BADGUYS,vPos) or c > 100 do
        vPos = nPos + RandomVector(50*c)
        c = c + 1
    end
    return vPos
end


function day_7:FindRandomHero(iTeam)
    local hEnt = Entities:First()
    local t = {}
    while hEnt do
        if hEnt:IsDOTANPC() and hEnt:IsRealHero() and hEnt:GetTeam() == iTeam then
            table.insert(t,hEnt)
        end
        hEnt = Entities:Next(hEnt)
    end
    if #t > 0 then
        return t[RandomInt(1,#t)]
    else
        return nil
    end
end

function day_7:FindAnyNeutral()
    local hEnt = Entities:First()
    while hEnt do
        if hEnt:IsDOTANPC() and hEnt:IsNeutralUnitType() and hEnt:IsAlive() then
            return hEnt
        end
        hEnt = Entities:Next(hEnt)
    end
end

