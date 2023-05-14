stonks_mrc = stonks_mrc or class({})



function stonks_mrc:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_mrc:IsPermanent() return true end
function stonks_mrc:RemoveOnDeath() return false end
function stonks_mrc:IsHidden() return false end
function stonks_mrc:IsDebuff() return false end
function stonks_mrc:AllowIllusionDuplicate() return true end

function stonks_mrc:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_mrc:OnCreated(event)
    if not IsServer() then return end
    if (event.stack ~= nil) then
        local total = event.stack
        if (total == 0) then
            self:SetStackCount(0)
            self:GetParent():CalculateStatBonus(true)
            self:GetParent():CalculateGenericBonuses()
            self:Destroy()
        else
            self:SetStackCount(total)
            self:GetParent():CalculateStatBonus(true)
            self:GetParent():CalculateGenericBonuses()
        end
    end
    if self:GetParent():IsIllusion() then
        self:SetStackCount(self:GetParent():GetPlayerOwner():GetAssignedHero():FindModifierByName(self:GetName()):GetStackCount())
    end
end

function stonks_mrc:OnRefresh(event)
    if not IsServer() then return end
    if (event.stack ~= nil) then
        local total = event.stack + self:GetStackCount()
        if (total == 0) then
            self:SetStackCount(0)
            self:GetParent():CalculateStatBonus(true)
            self:GetParent():CalculateGenericBonuses()
            self:Destroy()
        else
            self:SetStackCount(total)
            self:GetParent():CalculateStatBonus(true)
            self:GetParent():CalculateGenericBonuses()
        end
    end
end 
function stonks_mrc:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
	return funcs
end
function stonks_mrc:GetModifierConstantManaRegen()
    return self:GetStackCount()
end