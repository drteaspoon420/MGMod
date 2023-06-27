bloodbath = bloodbath or class({})


function bloodbath:IsPermanent() return true end
function bloodbath:RemoveOnDeath() return false end
function bloodbath:IsHidden() return  false end
function bloodbath:IsDebuff() return false end
function bloodbath:AllowIllusionDuplicate() return true end
function bloodbath:GetTexture() return "bloodbath" end -- get the icon from a different ability

function bloodbath:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function bloodbath:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_CAST_RANGE_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
	return funcs
end

function bloodbath:OnCreated(event)
	if not IsServer() then return end
end

function bloodbath:OnTakeDamage(event)
	if not IsServer() then return end
	if event.attacker ~= self:GetParent() then return end
    if self.dmg == nil then self.dmg = 0 end
    self.dmg = self.dmg + event.damage
    local k = self:GetStackCount()
    self:SetStackCount(math.floor(self.dmg / 250))
    if k ~= self:GetStackCount() then
        self:GetParent():CalculateGenericBonuses()
        if self:GetParent():IsHero() then
            self:GetParent():CalculateStatBonus(true)
        end
    end
end
function bloodbath:GetModifierAttackRangeBonus(event)
    return self:GetStackCount()*0.1
end
function bloodbath:GetModifierCastRangeBonus(event)
    return self:GetStackCount()*2
end
function bloodbath:GetModifierPhysicalArmorBonus(event)
    return self:GetStackCount()*0.17
end
function bloodbath:GetModifierAttackSpeedBonus_Constant(event)
    return self:GetStackCount()
end
function bloodbath:GetModifierBaseAttack_BonusDamage(event)
    return self:GetStackCount()
end
function bloodbath:GetModifierExtraHealthBonus(event)
    return self:GetStackCount()*20
end
function bloodbath:GetModifierExtraManaBonus(event)
    return self:GetStackCount()*12
end
function bloodbath:GetModifierMoveSpeedBonus_Constant(event)
    return self:GetStackCount()*0.2
end
function bloodbath:GetModifierConstantManaRegen(event)
    return self:GetStackCount()*0.05
end
function bloodbath:GetModifierConstantHealthRegen(event)
    return self:GetStackCount()*0.1
end
function bloodbath:GetModifierSpellAmplify_Percentage(event)
    return self:GetStackCount()*0.1
end
function bloodbath:GetModifierAttackSpeed_Limit(event)
    return 1
end
function bloodbath:GetModifierIgnoreMovespeedLimit(event)
    return 1
end