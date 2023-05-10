drteaspoon_essence_shift_str = class({})
function drteaspoon_essence_shift_str:GetIntrinsicModifierName()
	return "modifier_drteaspoon_essence_shift_str"
end
LinkLuaModifier("modifier_drteaspoon_essence_shift_str","abilities/drteaspoon/essence_shift_str/ability",LUA_MODIFIER_MOTION_NONE)
modifier_drteaspoon_essence_shift_str = class({
--GetTexture = function() return "legion_grant_movement" end,
IsPermanent = function() return true end,
RemoveOnDeath = function() return false end,
IsHidden = function() return true end,
IsDebuff = function() return false end,
IsPurgable = function() return false end,
IsPurgeException = function() return false end,
GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_drteaspoon_essence_shift_str:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED 
    }
    return funcs
end
