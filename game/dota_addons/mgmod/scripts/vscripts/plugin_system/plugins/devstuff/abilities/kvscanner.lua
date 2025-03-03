kvscanner = class({})
function kvscanner:GetIntrinsicModifierName()
	return "modifier_kvscanner"
end
LinkLuaModifier("modifier_kvscanner","plugin_system/plugins/devstuff/abilities/kvscanner",LUA_MODIFIER_MOTION_NONE)

modifier_kvscanner = class({
--GetTexture = function() return "legion_grant_movement" end,
IsPermanent = function() return true end,
RemoveOnDeath = function() return false end,
IsHidden = function() return true end,
IsDebuff = function() return false end,
IsPurgable = function() return false end,
IsPurgeException = function() return false end,
GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_kvscanner:DeclareFunctions()
    local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
    }
    return funcs
end

modifier_kvscanner.banned = {
    AbilityChargeRestoreTime = true,
    AbilityCharges = true,
    AbilityManaCost = true,
    AbilityCooldown = true,
    AbilityCastRange = true,
}

function modifier_kvscanner:GetModifierOverrideAbilitySpecial( params )
	if self:GetParent() == nil or params.ability == nil then
		return 0
	end
    if modifier_kvscanner.banned[params.ability_special_value] ~= nil then return 0 end
    --print("[kvscanner]: " .. params.ability_special_value)
    return 0
end

function modifier_kvscanner:GetModifierOverrideAbilitySpecialValue( params )
	return 1337
end