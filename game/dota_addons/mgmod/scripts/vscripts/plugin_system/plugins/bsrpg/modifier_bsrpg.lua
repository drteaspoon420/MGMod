modifier_bsrpg = modifier_bsrpg or class({})


function modifier_bsrpg:GetTexture() return "alchemist_chemical_rage" end

function modifier_bsrpg:IsPermanent() return true end
function modifier_bsrpg:RemoveOnDeath() return false end
function modifier_bsrpg:IsHidden() return true end 	-- we can hide the modifier
function modifier_bsrpg:IsDebuff() return false end 	-- make it red or green
function modifier_bsrpg:IsPurgeException() return false end
function modifier_bsrpg:AllowIllusionDuplicate() return true end

function modifier_bsrpg:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_bsrpg:OnCreated(kv)
	self.boost = {}
	if not IsServer() then return end
    self:SetHasCustomTransmitterData(true)
end

function modifier_bsrpg:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
	return funcs
end

function modifier_bsrpg:UpdateValue(a,k,v)
	self.boost[a .. "|" .. k] = v
	self:SendBuffRefreshToClients()
end

function modifier_bsrpg:AddCustomTransmitterData()
    return self.boost
end

function modifier_bsrpg:HandleCustomTransmitterData( data )
	self.boost = {}
    for k,v in pairs(data) do
		self.boost[k] = v
	end
end

function modifier_bsrpg:GetModifierOverrideAbilitySpecial( params )
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

function modifier_bsrpg:GetModifierOverrideAbilitySpecialValue( params )
	local szAbilityName = params.ability:GetAbilityName() 
	local szSpecialValueName = params.ability_special_value
	local k = szAbilityName .. "|" .. szSpecialValueName
	local nSpecialLevel = params.ability_special_level
	local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( szSpecialValueName, nSpecialLevel )
	local fBoost = self.boost[k]
	return flBaseValue * fBoost
end