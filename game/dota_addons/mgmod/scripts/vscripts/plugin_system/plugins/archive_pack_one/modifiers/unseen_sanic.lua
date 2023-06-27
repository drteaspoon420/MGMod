unseen_sanic = class({})


function unseen_sanic:GetTexture() return "kumamoto" end
function unseen_sanic:IsPermanent() return true end
function unseen_sanic:RemoveOnDeath() return false end
function unseen_sanic:IsHidden() return self:GetStackCount() > 0 end
function unseen_sanic:IsDebuff() return false end
function unseen_sanic:IsPurgable() return false end
function unseen_sanic:IsPurgeException() return false end
function unseen_sanic:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function unseen_sanic:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	}
	return funcs
end

function unseen_sanic:OnCreated(kv)
    if not IsServer() then return end
	self.speed = 5000
	self.tick_rate = 0.3
    self:StartIntervalThink(self.tick_rate)
end

function unseen_sanic:OnIntervalThink()
    if not IsServer() then return end
    if self:GetStackCount() > 0 then
        if self:GetParent():CanBeSeenByAnyOpposingTeam() then
            self:SetStackCount(0)
        end
    else
        if not self:GetParent():CanBeSeenByAnyOpposingTeam() then
            self:SetStackCount(self.speed)
        end
    end
end

function unseen_sanic:GetModifierMoveSpeedBonus_Constant()
    return self:GetStackCount()
end

function unseen_sanic:GetModifierIgnoreMovespeedLimit()
    return 1
end