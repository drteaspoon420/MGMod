modifier_rune_xp = class({})

--function modifier_rune_xp:GetTexture() return "kumamoto" end
function modifier_rune_xp:IsPermanent() return true end
function modifier_rune_xp:RemoveOnDeath() return false end
function modifier_rune_xp:IsHidden() return true end
function modifier_rune_xp:IsDebuff() return false end
function modifier_rune_xp:IsPurgable() return false end
function modifier_rune_xp:IsPurgeException() return false end
function modifier_rune_xp:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_rune_xp:OnCreated(kv)
    if not IsServer() then return end
    if self:GetParent():IsRealHero() then
        local xp = 280
        local intervals = math.floor(GameRules:GetGameTime()/420) + 1
        self:GetParent():AddExperience(xp * intervals,DOTA_ModifyXP_TomeOfKnowledge,false,true)
    end
    self:Destroy()
end