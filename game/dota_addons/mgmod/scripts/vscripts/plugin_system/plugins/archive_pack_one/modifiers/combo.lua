combo = combo or class({})


function combo:IsPermanent() return true end
function combo:RemoveOnDeath() return false end
function combo:IsHidden() return self:GetStackCount() < 1 end
function combo:IsDebuff() return false end

function combo:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function combo:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
	return funcs
end

function combo:OnCreated(event)
	if not IsServer() then return end
	self:StartIntervalThink(0.3)
end

function combo:OnRefresh(event)
end

function combo:CheckState()
	return {
	}
end

function combo:GetModifierTotalDamageOutgoing_Percentage()
	return self:GetStackCount()
end


function combo:OnTakeDamage(event)
	if not IsServer() then return end
	local hAttacker = event.attacker
	if not hAttacker or hAttacker ~= self:GetParent() then return end
	if event.unit == hAttacker then return end
	self:SetDuration(5,true)
	self:SetStackCount(self:GetStackCount() + 10)
end
function combo:DestroyOnExpire() return false end

function combo:OnIntervalThink()
	if not IsServer() then return end
	if self:GetRemainingTime() < 0.01 then
		self:SetStackCount(0)
	end
end