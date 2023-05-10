modifier_zombie_power = class({
    --GetTexture = function() return "legion_grant_movement" end,
    IsPermanent = function() return true end,
    RemoveOnDeath = function() return false end,
    IsHidden = function() return true end,
    IsDebuff = function() return false end,
    IsPurgable = function() return false end,
    IsPurgeException = function() return false end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_zombie_power:OnCreated(kv)
    if not IsServer() then return end
    self:SetStackCount(kv.stack or 0)
end

function modifier_zombie_power:OnRefresh(kv)
    if not IsServer() then return end
    self:SetStackCount((kv.stack or 0) + self:GetStackCount())
end


function modifier_zombie_power:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    }
    return funcs
end



function modifier_zombie_power:GetModifierPhysicalArmorBonus()
    return 0.5 * self:GetStackCount()
end

function modifier_zombie_power:GetModifierAttackSpeedBonus_Constant()
    return 0.5 * self:GetStackCount()
end

function modifier_zombie_power:GetModifierPreAttack_BonusDamage()
    return 2.0 * self:GetStackCount()
end

function modifier_zombie_power:GetModifierConstantHealthRegen()
    return 0.75 * self:GetStackCount()
end

function modifier_zombie_power:GetModifierExtraHealthBonus()
    return 10 * self:GetStackCount()
end

function modifier_zombie_power:GetModifierConstantManaRegen()
    return 0.75 * self:GetStackCount()
end

function modifier_zombie_power:GetModifierExtraManaBonus()
    return 5 * self:GetStackCount()
end

function modifier_zombie_power:GetModifierMoveSpeedBonus_Constant()
    return 0.2 * self:GetStackCount()
end
