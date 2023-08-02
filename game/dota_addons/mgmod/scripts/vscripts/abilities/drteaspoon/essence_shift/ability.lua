drteaspoon_essence_shift = class({})
function drteaspoon_essence_shift:GetIntrinsicModifierName()
	return "modifier_drteaspoon_essence_shift"
end
LinkLuaModifier("modifier_drteaspoon_essence_shift","abilities/drteaspoon/essence_shift/ability",LUA_MODIFIER_MOTION_NONE)
modifier_drteaspoon_essence_shift = class({
--GetTexture = function() return "legion_grant_movement" end,
IsPermanent = function() return true end,
RemoveOnDeath = function() return false end,
IsHidden = function() return true end,
IsDebuff = function() return false end,
IsPurgable = function() return false end,
IsPurgeException = function() return false end,
GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_drteaspoon_essence_shift:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end

function modifier_drteaspoon_essence_shift:OnAttackLanded(event)
end