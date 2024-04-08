xmas23_day6 = class({})


--function xmas23_day6:GetTexture() return "kumamoto" end
function xmas23_day6:IsPermanent() return true end
function xmas23_day6:RemoveOnDeath() return false end
function xmas23_day6:IsHidden() return true end
function xmas23_day6:IsDebuff() return false end
function xmas23_day6:IsPurgable() return false end
function xmas23_day6:IsPurgeException() return false end
function xmas23_day6:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

xmas23_day6.blocks = {
	AbilityCastRange = true,
	AbilityOvershootCastRange = true,
	AbilityCastRangeBuffer = true,
	AbilityCastPoint = true,
	AbilityChannelTime = true,
	AbilityCooldown = true,
	AbilityDuration = true,
	AbilityCharges = true,
	AbilityChargeRestoreTime = true,
}

function xmas23_day6:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
	}
	return funcs
end

function xmas23_day6:OnCreated(kv)
    if not IsServer() then return end
end


function xmas23_day6:GetModifierOverrideAbilitySpecial(kv)
	if xmas23_day6.blocks[kv.ability_special_value] ~= nil then return 0 end
    local v = kv.ability:GetLevelSpecialValueNoOverride(kv.ability_special_value,kv.ability_special_level)
	if v == 0 then
    	return 1
	end
	return 0
end

function xmas23_day6:GetModifierOverrideAbilitySpecialValue( kv )
    return 10
end