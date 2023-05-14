stonks_mp = stonks_mp or class({})



function stonks_mp:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_mp:IsPermanent() return true end
function stonks_mp:RemoveOnDeath() return false end
function stonks_mp:IsHidden() return false end
function stonks_mp:IsDebuff() return false end
function stonks_mp:AllowIllusionDuplicate() return true end

function stonks_mp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_mp:OnCreated(event)
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

function stonks_mp:OnRefresh(event)
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
function stonks_mp:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_MANA_BONUS,
	}
	return funcs
end
function stonks_mp:GetModifierManaBonus()
    return self:GetStackCount()*10
end