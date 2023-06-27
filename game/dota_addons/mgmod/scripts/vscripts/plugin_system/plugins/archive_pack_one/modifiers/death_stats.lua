death_stats = death_stats or class({})

function death_stats:IsPermanent() return true end
function death_stats:RemoveOnDeath() return false end
function death_stats:IsHidden() return true end
function death_stats:IsDebuff() return false end

function death_stats:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function death_stats:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH ,
	}
	return funcs
end

function death_stats:OnDeath(event)
	if IsClient() then return end
	if event.attacker~=self:GetParent() then return end
    if not event.unit:IsRealHero() then return end
    local primary = event.unit:GetPrimaryAttribute()
	if DOTA_ATTRIBUTE_ALL  == primary then
		self:GetParent():ModifyAgility(event.unit:GetAgility()*0.1)
		self:GetParent():ModifyIntellect(event.unit:GetIntellect()*0.1)
		self:GetParent():ModifyStrength(event.unit:GetStrength()*0.1)
	else
		if DOTA_ATTRIBUTE_AGILITY == primary then
			self:GetParent():ModifyAgility(event.unit:GetAgility()*0.2)
		else
			self:GetParent():ModifyAgility(event.unit:GetAgility()*0.05)
		end
		if DOTA_ATTRIBUTE_INTELLECT == primary then
			self:GetParent():ModifyIntellect(event.unit:GetIntellect()*0.2)
		else
			self:GetParent():ModifyIntellect(event.unit:GetIntellect()*0.05)
		end
		if DOTA_ATTRIBUTE_STRENGTH == primary then
			self:GetParent():ModifyStrength(event.unit:GetStrength()*0.2)
		else
			self:GetParent():ModifyStrength(event.unit:GetStrength()*0.05)
		end
	end
end
