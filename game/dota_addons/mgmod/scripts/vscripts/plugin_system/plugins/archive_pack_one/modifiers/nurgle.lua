nurgle = class({})


function nurgle:GetTexture() return "kumamoto" end
function nurgle:IsPermanent() return true end
function nurgle:RemoveOnDeath() return false end
function nurgle:IsHidden() return true end
function nurgle:IsDebuff() return false end
function nurgle:IsPurgable() return false end
function nurgle:IsPurgeException() return false end
function nurgle:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function nurgle:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
	}
	return funcs
end

function nurgle:OnCreated(kv)
    if not IsServer() then return end
    self.min_random = 0.5
    self.max_random = 3.0
    self:SetHasCustomTransmitterData(true)
    self:SendBuffRefreshToClients()
end

function nurgle:HandleCustomTransmitterData( data )
    self.min_random = data.min_random
    self.max_random = data.max_random
end
function nurgle:AddCustomTransmitterData()
return {
    min_random = self.min_random,
    max_random = self.max_random,
}
end
function nurgle:GetModifierOverrideAbilitySpecial(kv)
    return 1
end
function nurgle:GetModifierOverrideAbilitySpecialValue( kv )
    return kv.ability:GetLevelSpecialValueNoOverride(kv.ability_special_value,kv.ability_special_level) * RandomFloat(self.min_random,self.max_random)
end