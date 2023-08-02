modifier_time_scaling_heroes = modifier_time_scaling_heroes or class({})


function modifier_time_scaling_heroes:GetTexture() return "alchemist_chemical_rage" end

function modifier_time_scaling_heroes:IsPermanent() return true end
function modifier_time_scaling_heroes:RemoveOnDeath() return false end
function modifier_time_scaling_heroes:IsHidden() return true end 	-- we can hide the modifier
function modifier_time_scaling_heroes:IsDebuff() return false end 	-- make it red or green
function modifier_time_scaling_heroes:IsPurgeException() return false end
function modifier_time_scaling_heroes:AllowIllusionDuplicate() return true end

function modifier_time_scaling_heroes:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_time_scaling_heroes:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
	}
	return funcs
end

function modifier_time_scaling_heroes:OnCreated(kv)
	if not IsServer() then return end
    self:ServerData(kv)
	self:SetHasCustomTransmitterData(true)
    self:UpdateMe()
end

function modifier_time_scaling_heroes:ServerData(kv)
    self.ss_hp_max = kv.hp_max
    self.ss_mp_max = kv.mp_max
    self.ss_str = kv.str
    self.ss_agi = kv.agi
    self.ss_int = kv.int
    self.ss_armor = kv.armor
    self.ss_magic_resist = kv.magic_resist
    self.ss_status_resist = kv.status_resist
    self.ss_attack_speed = kv.attack_speed
    self.ss_attack_damage = kv.attack_damage
    self.ss_interval = kv.interval
    self:StartIntervalThink(self.ss_interval)
end

function modifier_time_scaling_heroes:OnIntervalThink()
    if IsServer() then
        self:UpdateMe()
        if self:GetParent().CalculateStatBonus ~= nil then
            self:GetParent():CalculateStatBonus(true)
        end
        self:GetParent():CalculateGenericBonuses()
    end
end

function modifier_time_scaling_heroes:UpdateMe()
    local time = math.floor(GameRules:GetDOTATime(false,false) / self.ss_interval + 0.5)
    self.hp_max = self.ss_hp_max * time
    self.mp_max = self.ss_mp_max * time
    self.str = self.ss_str * time
    self.agi = self.ss_agi * time
    self.int = self.ss_int * time
    self.armor = self.ss_armor * time
    self.magic_resist = self.ss_magic_resist * time
    self.status_resist = self.ss_status_resist * time
    self.attack_speed = self.ss_attack_speed * time
    self.attack_damage = self.ss_attack_damage * time
    self:SendBuffRefreshToClients()
end

function modifier_time_scaling_heroes:HandleCustomTransmitterData( data )
    self.hp_max				    = data.hp_max
    self.mp_max				    = data.mp_max
    self.str				    = data.str
    self.agi				    = data.agi
    self.int				    = data.int
    self.armor				    = data.armor
    self.magic_resist		    = data.magic_resist
    self.status_resist		    = data.status_resist
    self.attack_speed		    = data.attack_speed
    self.attack_damage		    = data.attack_damage
end

function modifier_time_scaling_heroes:GetModifierExtraHealthBonus()           return self.hp_max end
function modifier_time_scaling_heroes:GetModifierExtraManaBonus()             return self.mp_max end
function modifier_time_scaling_heroes:GetModifierBonusStats_Strength()        return self.str end
function modifier_time_scaling_heroes:GetModifierBonusStats_Agility()         return self.agi end
function modifier_time_scaling_heroes:GetModifierBonusStats_Intellect()       return self.int end
function modifier_time_scaling_heroes:GetModifierPhysicalArmorBonus()         return self.armor end
function modifier_time_scaling_heroes:GetModifierMagicalResistanceBonus()     return self.magic_resist end
function modifier_time_scaling_heroes:GetModifierStatusResistance()           return self.status_resist end
function modifier_time_scaling_heroes:GetModifierAttackSpeedBonus_Constant()  return self.attack_speed end
function modifier_time_scaling_heroes:GetModifierPreAttack_BonusDamage()      return self.attack_damage end


function modifier_time_scaling_heroes:AddCustomTransmitterData()
    return {
        hp_max = self.hp_max,
        mp_max = self.mp_max,
        str = self.str,
        agi = self.agi,
        int = self.int,
        armor = self.armor,
        magic_resist = self.magic_resist,
        status_resist = self.status_resist,
        attack_speed = self.attack_speed,
        attack_damage = self.attack_damage,
    }
end
 