stonks_agi = stonks_agi or class({})



function stonks_agi:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_agi:IsPermanent() return true end
function stonks_agi:RemoveOnDeath() return false end
function stonks_agi:IsHidden() return false end
function stonks_agi:IsDebuff() return false end
function stonks_agi:AllowIllusionDuplicate() return true end

function stonks_agi:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_agi:OnCreated(event)
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

function stonks_agi:OnRefresh(event)
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

function stonks_agi:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	}
	return funcs
end

function stonks_agi:GetModifierBonusStats_Agility()
    return self:GetStackCount()
end