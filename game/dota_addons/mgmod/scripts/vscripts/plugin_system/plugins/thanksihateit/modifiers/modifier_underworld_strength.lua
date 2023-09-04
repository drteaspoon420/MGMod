modifier_underworld_strength = modifier_underworld_strength or class({})


function modifier_underworld_strength:IsPermanent() return true end
function modifier_underworld_strength:RemoveOnDeath() return false end
function modifier_underworld_strength:IsHidden() return self:GetStackCount() < 1 end
function modifier_underworld_strength:IsDebuff() return false end

function modifier_underworld_strength:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_underworld_strength:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
	return funcs
end

function modifier_underworld_strength:OnCreated(event)
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end

function modifier_underworld_strength:OnRefresh(event)
end

function modifier_underworld_strength:CheckState()
	return {
	}
end

function modifier_underworld_strength:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end


function modifier_underworld_strength:DestroyOnExpire() return false end

function modifier_underworld_strength:OnIntervalThink()
	if not IsServer() then return end
	if self:GetParent():IsAlive() then return end
	self:SetStackCount(self:GetStackCount() + 1)
    self:GetParent():CalculateStatBonus(true)
end