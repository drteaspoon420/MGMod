mod_mp = mod_mp or class({})


function mod_mp:GetTexture() return "mod_mp" end

function mod_mp:IsPermanent() return true end
function mod_mp:RemoveOnDeath() return false end
function mod_mp:IsHidden() return true end
function mod_mp:IsDebuff() return false end

function mod_mp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function mod_mp:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MANA_BONUS,
	}
	return funcs
end

function mod_mp:OnCreated(event)
	if IsServer() then
		self:SetStackCount(event.bonus)
		self:GetParent():CalculateGenericBonuses()
	end
end

function mod_mp:OnRefresh(event)
	if IsServer() then
		self:SetStackCount(self:GetStackCount() + event.bonus)
		self:GetParent():CalculateGenericBonuses()
	end
end

function mod_mp:GetModifierManaBonus()
	return self:GetStackCount()
end