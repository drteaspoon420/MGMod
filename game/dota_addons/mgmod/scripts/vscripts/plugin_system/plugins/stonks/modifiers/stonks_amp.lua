stonks_amp = stonks_amp or class({})



function stonks_amp:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_amp:IsPermanent() return true end
function stonks_amp:RemoveOnDeath() return false end
function stonks_amp:IsHidden() return false end
function stonks_amp:IsDebuff() return false end
function stonks_amp:AllowIllusionDuplicate() return true end

function stonks_amp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_amp:OnCreated(event)
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

function stonks_amp:OnRefresh(event)
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

function stonks_amp:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
	return funcs
end

function stonks_amp:GetModifierSpellAmplify_Percentage()
    return self:GetStackCount()
end