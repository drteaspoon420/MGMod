modifier_mammonite_shield = class({
    GetTexture = function() return "alchemist_goblins_greed" end,
    IsPermanent = function() return true end,
    RemoveOnDeath = function() return false end,
    IsHidden = function() return false end,
    IsDebuff = function() return false end,
    IsPurgable = function() return false end,
    IsPurgeException = function() return false end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_mammonite_shield:OnCreated(kv)
    if not IsServer() then return end
    self.shield = self:GetParent():GetGold()
    self:SetHasCustomTransmitterData(true)
    self:StartIntervalThink(0.3)
end


function modifier_mammonite_shield:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
    }
    return funcs
end

function modifier_mammonite_shield:GetModifierIncomingDamageConstant(event)
    if not IsServer() then
        return self.shield
    end
    if self:GetParent():IsRealHero() then
        local iGold = self:GetParent():GetGold()
        if event.damage - iGold > 0 then
            self:GetParent():SpendGold(iGold,DOTA_ModifyGold_AbilityCost)
            return -iGold
        else
            self:GetParent():SpendGold(event.damage,DOTA_ModifyGold_AbilityCost)
            return -event.damage
        end
    else
        return 0
    end
end

function modifier_mammonite_shield:OnIntervalThink()
    self.shield = self:GetParent():GetGold()
    self:SendBuffRefreshToClients()
end
function modifier_mammonite_shield:AddCustomTransmitterData()
    return {
        shield = self.shield,
    }
end
function modifier_mammonite_shield:HandleCustomTransmitterData( data )
    self.shield = data.shield
end