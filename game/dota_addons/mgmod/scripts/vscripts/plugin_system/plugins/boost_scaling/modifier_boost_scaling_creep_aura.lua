modifier_boost_scaling_creep_aura = modifier_boost_scaling_creep_aura or class({})
LinkLuaModifier( "modifier_boost_scaling_creep_aura_effect", "plugin_system/plugins/boost_scaling/modifier_boost_scaling_creep_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_boost_scaling_creep_aura:GetTexture() return "backdoor_protection" end
function modifier_boost_scaling_creep_aura:IsPermanent() return true end
function modifier_boost_scaling_creep_aura:RemoveOnDeath() return false end
function modifier_boost_scaling_creep_aura:IsHidden() return false end
function modifier_boost_scaling_creep_aura:IsDebuff() return false end
function modifier_boost_scaling_creep_aura:IsPurgeException() return false end
function modifier_boost_scaling_creep_aura:AllowIllusionDuplicate() return false end
function modifier_boost_scaling_creep_aura:GetBehavior() return DOTA_ABILITY_BEHAVIOR_AURA end
function modifier_boost_scaling_creep_aura:IsAura() return true end
function modifier_boost_scaling_creep_aura:GetAuraRadius() return FIND_UNITS_EVERYWHERE end
function modifier_boost_scaling_creep_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_boost_scaling_creep_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_BASIC end
function modifier_boost_scaling_creep_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end

function modifier_boost_scaling_creep_aura:GetModifierAura()
	return "modifier_boost_scaling_creep_aura_effect"
end

function modifier_boost_scaling_creep_aura:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_boost_scaling_creep_aura:OnCreated(kv)
	if not IsServer() then return end
	if kv.creep_bonus_damage ~= nil then
		self.creep_bonus_damage = kv.creep_bonus_damage
	else
		self.creep_bonus_damage = 0
	end

	if kv.creep_bonus_magic_resistance ~= nil then
		self.creep_bonus_magic_resistance = kv.creep_bonus_magic_resistance
	else
		self.creep_bonus_magic_resistance = 0
	end

	if kv.creep_bonus_armor ~= nil then
		self.creep_bonus_armor = kv.creep_bonus_armor
	else
		self.creep_bonus_armor = 0
	end

	if kv.creep_bonus_hp_regen ~= nil then
		self.creep_bonus_hp_regen = kv.creep_bonus_hp_regen
	else
		self.creep_bonus_hp_regen = 0
	end

	if kv.creep_bonus_hp ~= nil then
		self.creep_bonus_hp = kv.creep_bonus_hp
	else
		self.creep_bonus_hp = 0
	end

	self:SetStackCount(0)
	self:SetHasCustomTransmitterData(true)
	self:SendBuffRefreshToClients()
end

function modifier_boost_scaling_creep_aura:AddCustomTransmitterData()
	return {
		bonus_hp = self.creep_bonus_hp,
		bonus_hp_regen = self.creep_bonus_hp_regen,
		bonus_armor = self.creep_bonus_armor,
		bonus_magic_resistance = self.creep_bonus_magic_resistance,
		bonus_damage = self.creep_bonus_damage
	}
end

--this is a client-only function that is called with the table returned by modifier:AddCustomTransmitterData()
function modifier_boost_scaling_creep_aura:HandleCustomTransmitterData( data )
	self.creep_bonus_hp = data.bonus_hp
	self.creep_bonus_hp_regen = data.bonus_hp_regen
	self.creep_bonus_armor = data.bonus_armor
	self.creep_bonus_magic_resistance = data.bonus_magic_resistance
	self.creep_bonus_damage = data.bonus_damage
end

function modifier_boost_scaling_creep_aura:OnRefresh()
    if not IsServer() then return end
    self:SendBuffRefreshToClients()
end

modifier_boost_scaling_creep_aura_effect = modifier_boost_scaling_creep_aura_effect or class({})
function modifier_boost_scaling_creep_aura_effect:GetTexture() return "backdoor_protection" end
function modifier_boost_scaling_creep_aura_effect:IsHidden() return false end
function modifier_boost_scaling_creep_aura_effect:IsDebuff() return false end
function modifier_boost_scaling_creep_aura_effect:IsPurgeException() return false end
function modifier_boost_scaling_creep_aura_effect:IsPermanent() return true end
function modifier_boost_scaling_creep_aura_effect:RemoveOnDeath() return false end

function modifier_boost_scaling_creep_aura_effect:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_boost_scaling_creep_aura_effect:OnCreated(kv)
	if not IsServer() then return end
	local modifier  = self:GetCaster():FindAllModifiersByName("modifier_boost_scaling_creep_aura")[1]
	
	if modifier ~= nil then
		self.creep_bonus_damage = modifier.creep_bonus_damage
		self.creep_bonus_magic_resistance = modifier.creep_bonus_magic_resistance
		self.creep_bonus_armor = modifier.creep_bonus_armor
		self.creep_bonus_hp_regen = modifier.creep_bonus_hp_regen
		self.creep_bonus_hp = modifier.creep_bonus_hp
		self:SetStackCount(modifier:GetStackCount())
	else
		self.creep_bonus_damage = 0
		self.creep_bonus_magic_resistance = 0
		self.creep_bonus_armor = 0
		self.creep_bonus_hp_reen = 0
		self.creep_bonus_hp = 0
		self:SetStackCount(0)
	end

	self:SetHasCustomTransmitterData(true)
	self:SendBuffRefreshToClients()
end

function modifier_boost_scaling_creep_aura_effect:AddCustomTransmitterData()
	return {
		bonus_hp = self.creep_bonus_hp,
		bonus_hp_regen = self.creep_bonus_hp_regen,
		bonus_armor = self.creep_bonus_armor,
		bonus_magic_resistance = self.creep_bonus_magic_resistance,
		bonus_damage = self.creep_bonus_damage
	}
end

--this is a client-only function that is called with the table returned by modifier:AddCustomTransmitterData()
function modifier_boost_scaling_creep_aura_effect:HandleCustomTransmitterData( data )
	self.creep_bonus_hp = data.bonus_hp
	self.creep_bonus_hp_regen = data.bonus_hp_regen
	self.creep_bonus_armor = data.bonus_armor
	self.creep_bonus_magic_resistance = data.bonus_magic_resistance
	self.creep_bonus_damage = data.bonus_damage
end

function modifier_boost_scaling_creep_aura_effect:OnRefresh()
    if not IsServer() then return end
	local modifier  = self:GetCaster():FindAllModifiersByName("modifier_boost_scaling_creep_aura")[1]
	if modifier ~= nil then
		self:SetStackCount(modifier:GetStackCount())
	end
    self:SendBuffRefreshToClients()
    self:GetParent():CalculateGenericBonuses()
end

function modifier_boost_scaling_creep_aura_effect:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
	return funcs
end

function modifier_boost_scaling_creep_aura_effect:GetModifierPreAttack_BonusDamage()
    return self:GetStackCount() * self.creep_bonus_damage
end

function modifier_boost_scaling_creep_aura_effect:GetModifierMagicalResistanceBonus()
    return self:GetStackCount() * self.creep_bonus_magic_resistance
end

function modifier_boost_scaling_creep_aura_effect:GetModifierPhysicalArmorBonus()
    return self:GetStackCount() * self.creep_bonus_armor
end

function modifier_boost_scaling_creep_aura_effect:GetModifierConstantHealthRegen()
    return self:GetStackCount() * self.creep_bonus_hp_regen
end

function modifier_boost_scaling_creep_aura_effect:GetModifierExtraHealthBonus()
    return self:GetStackCount() * self.creep_bonus_hp
end