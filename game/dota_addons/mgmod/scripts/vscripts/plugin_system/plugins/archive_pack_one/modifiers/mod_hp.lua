mod_hp = mod_hp or class({})


function mod_hp:GetTexture() return "mod_hp" end

function mod_hp:IsPermanent() return true end
function mod_hp:RemoveOnDeath() return false end
function mod_hp:IsHidden() return true end
function mod_hp:IsDebuff() return false end

function mod_hp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function mod_hp:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
	}
	return funcs
end

function mod_hp:OnCreated(event)
	if IsServer() then
		self:SetStackCount(event.bonus)
		self:GetParent():CalculateGenericBonuses()
	end
end

function mod_hp:OnRefresh(event)
	if IsServer() then
		self:SetStackCount(self:GetStackCount() + event.bonus)
		self:GetParent():CalculateGenericBonuses()
	end
end

function mod_hp:GetModifierExtraHealthBonus()
	return self:GetStackCount()
end