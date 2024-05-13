modifier_rune_water = class({})

--function modifier_rune_water:GetTexture() return "kumamoto" end
function modifier_rune_water:IsPermanent() return true end
function modifier_rune_water:RemoveOnDeath() return false end
function modifier_rune_water:IsHidden() return true end
function modifier_rune_water:IsDebuff() return false end
function modifier_rune_water:IsPurgable() return false end
function modifier_rune_water:IsPurgeException() return false end
function modifier_rune_water:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_rune_water:OnCreated(kv)
    if not IsServer() then return end
    self:GetParent():Heal(40,nil)
    self:GetParent():GiveMana(80)
    self:Destroy()
end