modifier_rune_bounty = class({})

--function modifier_rune_bounty:GetTexture() return "kumamoto" end
function modifier_rune_bounty:IsPermanent() return true end
function modifier_rune_bounty:RemoveOnDeath() return false end
function modifier_rune_bounty:IsHidden() return true end
function modifier_rune_bounty:IsDebuff() return false end
function modifier_rune_bounty:IsPurgable() return false end
function modifier_rune_bounty:IsPurgeException() return false end
function modifier_rune_bounty:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_rune_bounty:OnCreated(kv)
    if not IsServer() then return end
    self:Destroy()
end