modifier_death_percentage = modifier_death_percentage or class({})
function modifier_death_percentage:IsPermanent() return true end
function modifier_death_percentage:RemoveOnDeath() return false end
function modifier_death_percentage:IsHidden() return true end
function modifier_death_percentage:IsDebuff() return false end
function modifier_death_percentage:IsPurgeException() return false end
function modifier_death_percentage:AllowIllusionDuplicate() return true end
function modifier_death_percentage:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_death_percentage:OnCreated(kv)
	if not IsServer() then return end
	self:SetStackCount(kv.stack)
end

function modifier_death_percentage:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_RESPAWNTIME_PERCENTAGE,
	}
	return funcs
end

function modifier_death_percentage:GetModifierPercentageRespawnTime()
	return 1 - self:GetStackCount() * 0.01
end