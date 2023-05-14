stonks_hp = stonks_hp or class({})



function stonks_hp:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_hp:IsPermanent() return true end
function stonks_hp:RemoveOnDeath() return false end
function stonks_hp:IsHidden() return false end
function stonks_hp:IsDebuff() return false end
function stonks_hp:AllowIllusionDuplicate() return true end

function stonks_hp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_hp:OnCreated(event)
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

function stonks_hp:OnRefresh(event)
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
function stonks_hp:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS,
	}
	return funcs
end
function stonks_hp:GetModifierHealthBonus()
    return self:GetStackCount()*10
end