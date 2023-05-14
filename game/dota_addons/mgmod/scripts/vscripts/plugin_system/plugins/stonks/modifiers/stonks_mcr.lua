stonks_mcr = stonks_mcr or class({})



function stonks_mcr:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_mcr:IsPermanent() return true end
function stonks_mcr:RemoveOnDeath() return false end
function stonks_mcr:IsHidden() return false end
function stonks_mcr:IsDebuff() return false end
function stonks_mcr:AllowIllusionDuplicate() return true end

function stonks_mcr:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_mcr:OnCreated(event)
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

function stonks_mcr:OnRefresh(event)
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

function stonks_mcr:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_MANACOST_REDUCTION_CONSTANT,
	}
	return funcs
end

function stonks_mcr:GetModifierManacostReduction_Constant()
    return self:GetStackCount()
end