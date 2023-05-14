stonks_bad = stonks_bad or class({})



function stonks_bad:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_bad:IsPermanent() return true end
function stonks_bad:RemoveOnDeath() return false end
function stonks_bad:IsHidden() return false end
function stonks_bad:IsDebuff() return false end
function stonks_bad:AllowIllusionDuplicate() return true end

function stonks_bad:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_bad:OnCreated(event)
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

function stonks_bad:OnRefresh(event)
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

function stonks_bad:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE ,
	}
	return funcs
end

function stonks_bad:GetModifierBaseAttack_BonusDamage()
    return self:GetStackCount()
end