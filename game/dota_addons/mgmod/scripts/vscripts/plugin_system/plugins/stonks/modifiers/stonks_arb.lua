stonks_arb = stonks_arb or class({})



function stonks_arb:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_arb:IsPermanent() return true end
function stonks_arb:RemoveOnDeath() return false end
function stonks_arb:IsHidden() return false end
function stonks_arb:IsDebuff() return false end
function stonks_arb:AllowIllusionDuplicate() return true end

function stonks_arb:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_arb:OnCreated(event)
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

function stonks_arb:OnRefresh(event)
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
function stonks_arb:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
	return funcs
end
function stonks_arb:GetModifierAttackRangeBonus()
    return self:GetStackCount()*3
end