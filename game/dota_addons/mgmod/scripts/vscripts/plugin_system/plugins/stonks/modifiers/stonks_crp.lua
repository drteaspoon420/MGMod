stonks_crp = stonks_crp or class({})



function stonks_crp:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_crp:IsPermanent() return true end
function stonks_crp:RemoveOnDeath() return false end
function stonks_crp:IsHidden() return false end
function stonks_crp:IsDebuff() return false end
function stonks_crp:AllowIllusionDuplicate() return true end

function stonks_crp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_crp:OnCreated(event)
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

function stonks_crp:OnRefresh(event)
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

function stonks_crp:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
	}
	return funcs
end

function stonks_crp:GetModifierPercentageCooldown()
    return self:GetStackCount()*0.1
end