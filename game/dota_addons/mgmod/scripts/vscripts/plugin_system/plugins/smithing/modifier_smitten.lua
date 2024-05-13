modifier_smitten = modifier_smitten or class({})


function modifier_smitten:GetTexture() return "alchemist_chemical_rage" end

function modifier_smitten:IsPermanent() return true end
function modifier_smitten:RemoveOnDeath() return false end
function modifier_smitten:IsHidden() return true end
function modifier_smitten:IsDebuff() return false end
function modifier_smitten:IsPurgeException() return false end
function modifier_smitten:AllowIllusionDuplicate() return true end

function modifier_smitten:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_smitten:OnCreated(kv)
    if not IsServer() then return end
    self:SetStackCount(self:GetParent():GetTeam())
end

function modifier_smitten:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
        MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
    }
    return funcs
end

modifier_smitten.bans = {
	item_ward_observer = true,
	item_ward_sentry = true,
	item_ward_dispenser = true,
}
function modifier_smitten:GetModifierOverrideAbilitySpecial( params )
    if self:GetParent() == nil or params.ability == nil then
        return 0
    end
    if not params.ability:IsItem() then return 0 end
    local szAbilityName = params.ability:GetAbilityName()
    if modifier_smitten.bans[szAbilityName] ~= nil then return 0 end
    if string.find(string.lower(params.ability_special_value),"cooldown") ~= nil then return 0 end
    if string.find(string.lower(params.ability_special_value),"chance") ~= nil then return 0 end
    return 1
end

function modifier_smitten:GetModifierOverrideAbilitySpecialValue( params )
    local szAbilityName = params.ability:GetAbilityName() 
    local szSpecialValueName = params.ability_special_value
    local nSpecialLevel = params.ability_special_level
    local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( szSpecialValueName, nSpecialLevel )
    local charges = params.ability:GetSecondaryCharges()
    return flBaseValue * (charges*0.50+1)
end