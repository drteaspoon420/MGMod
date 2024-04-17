modifier_rounds_wait = class({})

--function modifier_rounds_wait:GetTexture() return "kumamoto" end
function modifier_rounds_wait:IsPermanent() return false end
function modifier_rounds_wait:RemoveOnDeath() return false end
function modifier_rounds_wait:IsHidden() return false end
function modifier_rounds_wait:IsDebuff() return false end
function modifier_rounds_wait:IsPurgable() return false end
function modifier_rounds_wait:IsPurgeException() return false end
function modifier_rounds_wait:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_rounds_wait:DeclareFunctions()
	local funcs = {
	}
	return funcs
end

function modifier_rounds_wait:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_INVULNERABLE] = true
	}

	return state
end

function modifier_rounds_wait:OnCreated(kv)
    if not IsServer() then return end
end