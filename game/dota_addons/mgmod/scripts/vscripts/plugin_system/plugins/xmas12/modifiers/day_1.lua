day_1 = class({})


--function day_1:GetTexture() return "kumamoto" end
function day_1:IsPermanent() return true end
function day_1:RemoveOnDeath() return false end
function day_1:IsHidden() return true end
function day_1:IsDebuff() return false end
function day_1:IsPurgable() return false end
function day_1:IsPurgeException() return false end
function day_1:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function day_1:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE
	}
	return funcs
end

function day_1:OnCreated(kv)
    if not IsServer() then return end
    self.regen = self:GetParent():GetBaseManaRegen()
    self:SetHasCustomTransmitterData(true)
    self:StartIntervalThink(1)
end

function day_1:AddCustomTransmitterData()
    return {
        regen = self.regen,
    }
end
function day_1:HandleCustomTransmitterData( data )
    self.regen = data.regen
end

function day_1:OnIntervalThink()
    if not IsServer() then return end

    self.regen = self:GetParent():GetBaseManaRegen()
    if self:GetStackCount() > 0 then
        if self:GetParent():HasModifier("modifier_tower_aura_bonus")then
            self:SetStackCount(0)
        end
    else
        if not self:GetParent():HasModifier("modifier_tower_aura_bonus")then
            self:SetStackCount(1)
        end
    end
    self:SendBuffRefreshToClients()
end

function day_1:GetModifierConstantManaRegen()
    if self:GetStackCount() == 1 then
        return -100
    else
        return 100
    end
end

function day_1:GetModifierTotalPercentageManaRegen()
    if self:GetStackCount() == 1 then
        return -0.415
    else
        return 10
    end
end

