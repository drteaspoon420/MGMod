stonks_bnv = stonks_bnv or class({})



function stonks_bnv:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_bnv:IsPermanent() return true end
function stonks_bnv:RemoveOnDeath() return false end
function stonks_bnv:IsHidden() return false end
function stonks_bnv:IsDebuff() return false end
function stonks_bnv:AllowIllusionDuplicate() return true end

function stonks_bnv:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_bnv:OnCreated(event)
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

function stonks_bnv:OnRefresh(event)
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

function stonks_bnv:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
	}
	return funcs
end

function stonks_bnv:GetBonusNightVision()
    return self:GetStackCount()*10
end