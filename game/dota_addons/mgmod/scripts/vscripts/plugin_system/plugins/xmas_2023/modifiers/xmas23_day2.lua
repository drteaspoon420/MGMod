xmas23_day2 = class({})


function xmas23_day2:GetTexture() return "kumamoto" end
function xmas23_day2:IsPermanent() return true end
function xmas23_day2:RemoveOnDeath() return false end
function xmas23_day2:IsHidden() return true end
function xmas23_day2:IsDebuff() return false end
function xmas23_day2:IsPurgable() return false end
function xmas23_day2:IsPurgeException() return false end
function xmas23_day2:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function xmas23_day2:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
	}
	return funcs
end

function xmas23_day2:OnCreated(kv)
    if not IsServer() then return end
    self.min_random = 0.1
    self.max_random = 10.0
    self.boost = {}
    self:SetHasCustomTransmitterData(true)
    self:SendBuffRefreshToClients()
end

function xmas23_day2:HandleCustomTransmitterData( data )
	self.boost = {}
    for k,v in pairs(data) do
		self.boost[k] = v
	end
end

function xmas23_day2:UpdateValue(k,v)
	self.boost[k] = v
	self:SendBuffRefreshToClients()
end


function xmas23_day2:AddCustomTransmitterData()
    return self.boost
end

function xmas23_day2:GetModifierOverrideAbilitySpecial(kv)
	if self.boost == nil then return 0 end
	local szAbilityName = kv.ability:GetAbilityName()
	local szSpecialValueName = kv.ability_special_value
	local k = szAbilityName .. "|" .. szSpecialValueName
	if self.boost[k] == nil then
        if IsServer() then
            self:UpdateValue(k,RandomFloat(self.min_random,self.max_random))
            return 1
        end
        return 0
    end
    return 1
end
function xmas23_day2:GetModifierOverrideAbilitySpecialValue( kv )
    local v = kv.ability:GetLevelSpecialValueNoOverride(kv.ability_special_value,kv.ability_special_level)
	local k = kv.ability:GetAbilityName() .. "|" .. kv.ability_special_value
    return self.boost[k] * v
end