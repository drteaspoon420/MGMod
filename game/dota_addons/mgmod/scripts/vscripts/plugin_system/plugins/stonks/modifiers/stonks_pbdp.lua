stonks_pbdp = stonks_pbdp or class({})



function stonks_pbdp:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_pbdp:IsPermanent() return true end
function stonks_pbdp:RemoveOnDeath() return false end
function stonks_pbdp:IsHidden() return false end
function stonks_pbdp:IsDebuff() return false end
function stonks_pbdp:AllowIllusionDuplicate() return true end

function stonks_pbdp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_pbdp:OnCreated(event)
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

function stonks_pbdp:OnRefresh(event)
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

function stonks_pbdp:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE ,
	}
	return funcs
end

function stonks_pbdp:GetModifierProcAttack_BonusDamage_Pure()
    return self:GetStackCount()
end