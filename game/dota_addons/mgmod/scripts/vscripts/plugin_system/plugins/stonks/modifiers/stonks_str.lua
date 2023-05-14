stonks_str = stonks_str or class({})



function stonks_str:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_str:IsPermanent() return true end
function stonks_str:RemoveOnDeath() return false end
function stonks_str:IsHidden() return false end
function stonks_str:IsDebuff() return false end
function stonks_str:AllowIllusionDuplicate() return true end

function stonks_str:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_str:OnCreated(event)
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

function stonks_str:OnRefresh(event)
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

function stonks_str:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
	return funcs
end

function stonks_str:GetModifierBonusStats_Strength()
    return self:GetStackCount()
end