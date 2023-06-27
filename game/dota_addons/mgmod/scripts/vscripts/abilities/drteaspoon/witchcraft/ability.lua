drteaspoon_witchcraft = class({})
function drteaspoon_witchcraft:GetIntrinsicModifierName()
	return "modifier_drteaspoon_witchcraft"
end
LinkLuaModifier("modifier_drteaspoon_witchcraft","abilities/drteaspoon/witchcraft/ability",LUA_MODIFIER_MOTION_NONE)
modifier_drteaspoon_witchcraft = class({
--GetTexture = function() return "legion_grant_movement" end,
IsPermanent = function() return true end,
RemoveOnDeath = function() return false end,
IsHidden = function() return true end,
IsDebuff = function() return false end,
IsPurgable = function() return false end,
IsPurgeException = function() return false end,
GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_drteaspoon_witchcraft:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_COOLDOWN_REDUCTION_CONSTANT,
        MODIFIER_PROPERTY_MANACOST_REDUCTION_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
    return funcs
end

function modifier_drteaspoon_witchcraft:GetModifierCooldownReduction_Constant()
    return self:GetAbility():GetSpecialValueFor( "cooldown_reduction" )
end
function modifier_drteaspoon_witchcraft:GetModifierManacostReduction_Constant()
    return self:GetAbility():GetSpecialValueFor( "manacost_reduction" )
end
function modifier_drteaspoon_witchcraft:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor( "movement_speed_bonus_pct" )
end

