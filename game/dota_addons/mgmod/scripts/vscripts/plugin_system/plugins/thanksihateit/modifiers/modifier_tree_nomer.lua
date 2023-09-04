modifier_tree_nomer = modifier_tree_nomer or class({})


function modifier_tree_nomer:IsPermanent() return true end
function modifier_tree_nomer:RemoveOnDeath() return false end
function modifier_tree_nomer:IsHidden() return self:GetStackCount() < 1 end
function modifier_tree_nomer:IsDebuff() return false end

function modifier_tree_nomer:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_tree_nomer:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS
	}
	return funcs
end

function modifier_tree_nomer:OnCreated(event)
	if not IsServer() then return end
	self:IncrementStackCount()
end

function modifier_tree_nomer:OnRefresh(event)
	if not IsServer() then return end
	self:IncrementStackCount()
end

function modifier_tree_nomer:CheckState()
	return {
	}
end

function modifier_tree_nomer:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end

function modifier_tree_nomer:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end

function modifier_tree_nomer:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end


function modifier_tree_nomer:DestroyOnExpire() return false end
