modifier_courier_speed = class({})
function modifier_courier_speed:IsPermanent() return true end
function modifier_courier_speed:RemoveOnDeath() return false end
function modifier_courier_speed:IsHidden() return true end
function modifier_courier_speed:IsDebuff() return false end
function modifier_courier_speed:IsPurgeException() return false end
function modifier_courier_speed:AllowIllusionDuplicate() return true end
function modifier_courier_speed:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_courier_speed:OnCreated(kv)
	if not IsServer() then return end
	self:SetStackCount(kv.stack)
end

function modifier_courier_speed:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_courier_speed:GetModifierMoveSpeedBonus_Percentage()
    return self:GetStackCount() - 100
end