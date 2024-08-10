modifier_boost_scaling_tower = modifier_boost_scaling_tower or class({})


function modifier_boost_scaling_tower:GetTexture() return "backdoor_protection" end

function modifier_boost_scaling_tower:IsPermanent() return true end
function modifier_boost_scaling_tower:RemoveOnDeath() return false end
function modifier_boost_scaling_tower:IsHidden() return false end
function modifier_boost_scaling_tower:IsDebuff() return false end
function modifier_boost_scaling_tower:IsPurgeException() return false end
function modifier_boost_scaling_tower:AllowIllusionDuplicate() return false end

function modifier_boost_scaling_tower:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_boost_scaling_tower:OnCreated(kv)
	if not IsServer() then return end
	if kv.tower_bonus_damage ~= nil then
		self.tower_bonus_damage = kv.tower_bonus_damage
	else
		self.tower_bonus_damage = 0
	end

	if kv.tower_bonus_magic_resistance ~= nil then
		self.tower_bonus_magic_resistance = kv.tower_bonus_magic_resistance
	else
		self.tower_bonus_magic_resistance = 0
	end

	if kv.tower_bonus_armor ~= nil then
		self.tower_bonus_armor = kv.tower_bonus_armor
	else
		self.tower_bonus_armor = 0
	end

	if kv.tower_bonus_hp_regen ~= nil then
		self.tower_bonus_hp_regen = kv.tower_bonus_hp_regen
	else
		self.tower_bonus_hp_regen = 0
	end

	if kv.tower_bonus_hp ~= nil then
		self.tower_bonus_hp = kv.tower_bonus_hp
	else
		self.tower_bonus_hp = 0
	end

	self:SetStackCount(0)
	self:SetHasCustomTransmitterData(true)
	self:SendBuffRefreshToClients()
end

function modifier_boost_scaling_tower:AddCustomTransmitterData()
	return {
		bonus_hp = self.tower_bonus_hp,
		bonus_hp_regen = self.tower_bonus_hp_regen,
		bonus_armor = self.tower_bonus_armor,
		bonus_magic_resistance = self.tower_bonus_magic_resistance,
		bonus_damage = self.tower_bonus_damage
	}
end

--this is a client-only function that is called with the table returned by modifier:AddCustomTransmitterData()
function modifier_boost_scaling_tower:HandleCustomTransmitterData( data )
	self.tower_bonus_hp = data.bonus_hp
	self.tower_bonus_hp_regen = data.bonus_hp_regen
	self.tower_bonus_armor = data.bonus_armor
	self.tower_bonus_magic_resistance = data.bonus_magic_resistance
	self.tower_bonus_damage = data.bonus_damage
end

function modifier_boost_scaling_tower:OnRefresh()
    if not IsServer() then return end
    self:SendBuffRefreshToClients()
    self:GetParent():CalculateGenericBonuses()
end

function modifier_boost_scaling_tower:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
	return funcs
end

function modifier_boost_scaling_tower:GetModifierPreAttack_BonusDamage()
    return self:GetStackCount() * self.tower_bonus_damage
end

function modifier_boost_scaling_tower:GetModifierMagicalResistanceBonus()
    return math.min((1 - math.pow(1 - self.tower_bonus_magic_resistance * 0.01, self:GetStackCount())) * 100, 95)
end

function modifier_boost_scaling_tower:GetModifierPhysicalArmorBonus()
    return self:GetStackCount() * self.tower_bonus_armor
end

function modifier_boost_scaling_tower:GetModifierConstantHealthRegen()
    return self:GetStackCount() * self.tower_bonus_hp_regen
end

function modifier_boost_scaling_tower:GetModifierExtraHealthBonus()
    return self:GetStackCount() * self.tower_bonus_hp
end
