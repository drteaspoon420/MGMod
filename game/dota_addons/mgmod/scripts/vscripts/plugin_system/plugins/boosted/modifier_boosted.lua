modifier_boosted = modifier_boosted or class({})


function modifier_boosted:GetTexture() return "alchemist_chemical_rage" end

function modifier_boosted:IsPermanent() return true end
function modifier_boosted:RemoveOnDeath() return false end
function modifier_boosted:IsHidden() return true end 	-- we can hide the modifier
function modifier_boosted:IsDebuff() return false end 	-- make it red or green
function modifier_boosted:IsPurgeException() return false end
function modifier_boosted:AllowIllusionDuplicate() return true end

function modifier_boosted:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_boosted:OnCreated(kv)
	self.boost = {}
	if not IsServer() then return end
    self:SetHasCustomTransmitterData(true)
end

function modifier_boosted:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
	return funcs
end

function modifier_boosted:UpdateValue(a,k,v)
	self.boost[a .. "|" .. k] = v
	self:SendBuffRefreshToClients()
end

function modifier_boosted:AddCustomTransmitterData()
    return self.boost
end

function modifier_boosted:HandleCustomTransmitterData( data )
	self.boost = {}
    for k,v in pairs(data) do
		self.boost[k] = v
	end
end

function modifier_boosted:GetModifierOverrideAbilitySpecial( params )
	if self:GetParent() == nil or params.ability == nil then
		return 0
	end
	if self.boost == nil then return 0 end
	local szAbilityName = params.ability:GetAbilityName()
	local szSpecialValueName = params.ability_special_value
	local k = szAbilityName .. "|" .. szSpecialValueName
	if self.boost[k] == nil then return 0 end
	if self.boost[k] == 1 then return 0 end
	return 1
end

function modifier_boosted:GetModifierOverrideAbilitySpecialValue( params )
	local szAbilityName = params.ability:GetAbilityName() 
	local szSpecialValueName = params.ability_special_value
	local k = szAbilityName .. "|" .. szSpecialValueName
	local nSpecialLevel = params.ability_special_level
	local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( szSpecialValueName, nSpecialLevel )
	local fBoost = self.boost[k]
	return flBaseValue * fBoost
end