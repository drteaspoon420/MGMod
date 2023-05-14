stonks_exp = stonks_exp or class({})



function stonks_exp:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_exp:IsPermanent() return true end
function stonks_exp:RemoveOnDeath() return false end
function stonks_exp:IsHidden() return false end
function stonks_exp:IsDebuff() return false end
function stonks_exp:AllowIllusionDuplicate() return true end

function stonks_exp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_exp:OnCreated(event)
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

function stonks_exp:OnRefresh(event)
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

function stonks_exp:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_EXP_RATE_BOOST,
	}
	return funcs
end

function stonks_exp:GetModifierPercentageExpRateBoost()
    return self:GetStackCount()
end