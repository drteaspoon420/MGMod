stonks_evc = stonks_evc or class({})



function stonks_evc:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_evc:IsPermanent() return true end
function stonks_evc:RemoveOnDeath() return false end
function stonks_evc:IsHidden() return false end
function stonks_evc:IsDebuff() return false end
function stonks_evc:AllowIllusionDuplicate() return true end

function stonks_evc:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_evc:OnCreated(event)
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

function stonks_evc:OnRefresh(event)
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
function stonks_evc:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_EVASION_CONSTANT,
	}
	return funcs
end
function stonks_evc:GetModifierEvasion_Constant()
    return self:GetStackCount()*0.05
end