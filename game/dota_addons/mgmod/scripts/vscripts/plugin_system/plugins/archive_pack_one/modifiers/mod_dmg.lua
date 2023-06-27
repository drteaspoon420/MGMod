mod_dmg = mod_dmg or class({})


function mod_dmg:GetTexture() return "mod_dmg" end

function mod_dmg:IsPermanent() return true end
function mod_dmg:RemoveOnDeath() return false end
function mod_dmg:IsHidden() return true end
function mod_dmg:IsDebuff() return false end

function mod_dmg:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function mod_dmg:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
	return funcs
end

function mod_dmg:OnCreated(event)
	if IsServer() then
		self:SetStackCount(event.bonus)
		self:GetParent():CalculateGenericBonuses()
	end
end

function mod_dmg:OnRefresh(event)
	if IsServer() then
		self:SetStackCount(self:GetStackCount() + event.bonus)
		self:GetParent():CalculateGenericBonuses()
	end
end

function mod_dmg:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end