modifier_rounds_core = class({})

--function modifier_rounds_core:GetTexture() return "kumamoto" end
function modifier_rounds_core:IsPermanent() return true end
function modifier_rounds_core:RemoveOnDeath() return false end
function modifier_rounds_core:IsHidden() return true end
function modifier_rounds_core:IsDebuff() return false end
function modifier_rounds_core:IsPurgable() return false end
function modifier_rounds_core:IsPurgeException() return false end
function modifier_rounds_core:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_rounds_core:DeclareFunctions()
	local funcs = {
	}
	return funcs
end

function modifier_rounds_core:OnCreated(kv)
    if not IsServer() then return end
    self.team = kv.team or self:GetParent():GetTeam()
end