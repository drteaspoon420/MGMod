LinkLuaModifier( "modifier_tremulous_power", "plugin_system/plugins/tremulous/abilities/tremulous_power", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_tremulous_power_aura", "plugin_system/plugins/tremulous/abilities/tremulous_power", LUA_MODIFIER_MOTION_NONE )
tremulous_power = class({})
function tremulous_power:GetIntrinsicModifierName() return "modifier_tremulous_power" end
modifier_tremulous_power = class({})
function modifier_tremulous_power:IsAura()
    if self:GetParent():HasModifier("modifier_building_inprogress") then return false end
	return true
end

function modifier_tremulous_power:IsHidden() return true end

function modifier_tremulous_power:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_tremulous_power:GetAuraDuration()
	return 0.5
end

function modifier_tremulous_power:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_tremulous_power:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY 
end

function modifier_tremulous_power:GetAuraSearchType()
	return DOTA_UNIT_TARGET_BASIC
end

function modifier_tremulous_power:GetModifierAura()
	return "modifier_tremulous_power_aura"
end

modifier_tremulous_power_aura = class({})
function modifier_tremulous_power_aura:IsHidden() return false end