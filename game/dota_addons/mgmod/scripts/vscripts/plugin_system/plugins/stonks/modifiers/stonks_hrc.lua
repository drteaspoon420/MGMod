stonks_hrc = stonks_hrc or class({})



function stonks_hrc:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_hrc:IsPermanent() return true end
function stonks_hrc:RemoveOnDeath() return false end
function stonks_hrc:IsHidden() return false end
function stonks_hrc:IsDebuff() return false end
function stonks_hrc:AllowIllusionDuplicate() return true end

function stonks_hrc:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_hrc:OnCreated(event)
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

function stonks_hrc:OnRefresh(event)
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
function stonks_hrc:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
	return funcs
end
function stonks_hrc:GetModifierConstantHealthRegen()
    return self:GetStackCount()
end