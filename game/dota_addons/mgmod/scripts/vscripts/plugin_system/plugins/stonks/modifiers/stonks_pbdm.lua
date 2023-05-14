stonks_pbdm = stonks_pbdm or class({})



function stonks_pbdm:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_pbdm:IsPermanent() return true end
function stonks_pbdm:RemoveOnDeath() return false end
function stonks_pbdm:IsHidden() return false end
function stonks_pbdm:IsDebuff() return false end
function stonks_pbdm:AllowIllusionDuplicate() return true end

function stonks_pbdm:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_pbdm:OnCreated(event)
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

function stonks_pbdm:OnRefresh(event)
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

function stonks_pbdm:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
	}
	return funcs
end

function stonks_pbdm:GetModifierProcAttack_BonusDamage_Magical()
    return self:GetStackCount()
end