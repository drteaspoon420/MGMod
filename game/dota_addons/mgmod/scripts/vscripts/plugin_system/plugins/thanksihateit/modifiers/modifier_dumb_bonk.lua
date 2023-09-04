modifier_dumb_bonk = modifier_dumb_bonk or class({})


function modifier_dumb_bonk:IsPermanent() return true end
function modifier_dumb_bonk:RemoveOnDeath() return false end
function modifier_dumb_bonk:IsHidden() return self:GetStackCount() < 1 end
function modifier_dumb_bonk:IsDebuff() return false end

function modifier_dumb_bonk:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_dumb_bonk:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
	return funcs
end

function modifier_dumb_bonk:OnCreated(event)
	if not IsServer() then return end
	self:StartIntervalThink(0.3)
end

function modifier_dumb_bonk:OnRefresh(event)
end

function modifier_dumb_bonk:CheckState()
	return {
	}
end

function modifier_dumb_bonk:GetModifierBonusStats_Intellect()
	return -self:GetStackCount()
end


function modifier_dumb_bonk:OnAttackLanded(event)
	if not IsServer() then return end
	if not event.target or event.target ~= self:GetParent() then return end
	local hAttacker = event.attacker
	local hUnit = event.target
	if hUnit == hAttacker then return end
	self:SetDuration(10,true)
	self:SetStackCount(self:GetStackCount() + 1)
	hUnit:CalculateStatBonus(true)
end
function modifier_dumb_bonk:DestroyOnExpire() return false end

function modifier_dumb_bonk:OnIntervalThink()
	if not IsServer() then return end
	if self:GetStackCount() > 0 and self:GetRemainingTime() < 0.01 then
		self:SetStackCount(0)
		self:GetParent():CalculateStatBonus(true)
	end
end