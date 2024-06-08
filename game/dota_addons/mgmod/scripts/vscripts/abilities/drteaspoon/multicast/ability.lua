drteaspoon_multicast = class({})
function drteaspoon_multicast:GetIntrinsicModifierName()
	return "modifier_drteaspoon_multicast"
end
LinkLuaModifier("modifier_drteaspoon_multicast","abilities/drteaspoon/multicast/ability",LUA_MODIFIER_MOTION_NONE)
modifier_drteaspoon_multicast = class({
--GetTexture = function() return "legion_grant_movement" end,
IsPermanent = function() return true end,
RemoveOnDeath = function() return false end,
IsHidden = function() return true end,
IsDebuff = function() return false end,
IsPurgable = function() return false end,
IsPurgeException = function() return false end,
GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_drteaspoon_multicast:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED 
    }
    return funcs
end


function modifier_drteaspoon_multicast:OnAbilityExecuted(event)
    if not IsServer() then return end
    if (event.unit ~= self:GetParent()) then return end
    local fRoll = Script_RandomFloat(0.0,100.0)
    local x2chance = self:GetAbility():GetSpecialValueFor("multicast_2_times")
    local x3chance = self:GetAbility():GetSpecialValueFor("multicast_3_times")
    local x4chance = self:GetAbility():GetSpecialValueFor("multicast_4_times")

    local hDumbLuck = self:GetParent():FindAbilityByName("ogre_magi_dumb_luck")
    if hDumbLuck ~= nil and self:GetParent().GetStrength ~= nil then
        local iStr = self:GetParent():GetStrength()
        if x2chance > 0 then
            x2chance = x2chance + 0.05*iStr
        end
        if x3chance > 0 then
            x3chance = x3chance + 0.05*iStr
        end
        if x4chance > 0 then
            x4chance = x4chance + 0.05*iStr
        end
    end

    local iCount = 0
    if fRoll < x4chance then
        iCount = 3
    elseif fRoll < x3chance then
        iCount = 2
    elseif fRoll < x2chance then
        iCount = 1
    end
    if iCount == 0 then return end
    local hUnit = event.unit
    local hAbility = event.ability
    local hTarget = event.target
    local vPos = hAbility:GetCursorPosition()
    local iBehav = hAbility:GetBehavior()
    if type(iBehav) ~= "number" then
        iBehav = tonumber(tostring(iBehav))
    end
    if hAbility:IsItem() and not hAbility:IsPermanent() then
        return
    end
    if bit.band(iBehav,DOTA_ABILITY_BEHAVIOR_CHANNELLED ) == DOTA_ABILITY_BEHAVIOR_CHANNELLED  then --channel
        return
    elseif  bit.band(iBehav,DOTA_ABILITY_BEHAVIOR_TOGGLE) == DOTA_ABILITY_BEHAVIOR_TOGGLE then --no target
        return

    elseif  bit.band(iBehav,DOTA_ABILITY_BEHAVIOR_POINT) == DOTA_ABILITY_BEHAVIOR_POINT then --no target
        for i=1,iCount do
            local fDelay = 0.6*i
            Timers:CreateTimer(fDelay,function()
                hUnit:SetCursorPosition(vPos)
                hAbility:OnSpellStart()
            end)
        end
    elseif  bit.band(iBehav,DOTA_ABILITY_BEHAVIOR_NO_TARGET) == DOTA_ABILITY_BEHAVIOR_NO_TARGET then --no target
        for i=1,iCount do
            local fDelay = 0.6*i
            Timers:CreateTimer(fDelay,function()
                hAbility:OnSpellStart()
            end)
        end
    else --target
        --print(iBehav)
        local iTeam = hUnit:GetTeam()
        if hTarget == nil then return end
        local vRPos = hTarget:GetAbsOrigin()
        local fRadius = hAbility:GetCastRange(vRPos,nil)
        local teamFilter = hAbility:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
        local typeFilter = hAbility:GetAbilityTargetType() or DOTA_UNIT_TARGET_BASIC
        local flagFilter = hAbility:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE
        for i=1,iCount do
            local fDelay = 0.6*i
            if hTarget == hUnit then
                Timers:CreateTimer(fDelay,function()
                    hUnit:SetCursorCastTarget(hTarget)
                    hAbility:OnSpellStart()
                end)
            else
                Timers:CreateTimer(fDelay,function()
                    local t = FindUnitsInRadius(
                        iTeam,
                        vRPos,
                        nil,
                        fRadius,
                        teamFilter,
                        typeFilter,
                        flagFilter,
                        FIND_ANY_ORDER,
                        false
                    )
                    if #t > 0 then
                        local l = RandomInt(1,#t)
                        local nhTarget = t[l]
                        hUnit:SetCursorCastTarget(nhTarget)
                        hAbility:OnSpellStart()
                    elseif hTarget:IsAlive() then
                        hUnit:SetCursorCastTarget(hTarget)
                        hAbility:OnSpellStart()
                    end
                end)
            end
        end
    end
    
    local prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf', PATTACH_OVERHEAD_FOLLOW, hUnit)
    ParticleManager:SetParticleControl(prt, 1, Vector(iCount+1, 0, 0))
    ParticleManager:ReleaseParticleIndex(prt)

    prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_b.vpcf', PATTACH_OVERHEAD_FOLLOW, hUnit:GetCursorCastTarget() or hUnit)
    prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_b.vpcf', PATTACH_OVERHEAD_FOLLOW, hUnit)
    ParticleManager:ReleaseParticleIndex(prt)

    prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_c.vpcf', PATTACH_OVERHEAD_FOLLOW, hUnit:GetCursorCastTarget() or hUnit)
    ParticleManager:SetParticleControl(prt, 1, Vector(iCount+1, 0, 0))
    ParticleManager:ReleaseParticleIndex(prt)

    -- Play the sound
    hUnit:EmitSound('Hero_OgreMagi.Fireblast.x'..(iCount))
end
