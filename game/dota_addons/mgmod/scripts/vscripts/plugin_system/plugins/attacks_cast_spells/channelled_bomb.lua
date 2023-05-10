channelled_bomb = class({})

function channelled_bomb:GetIntrinsicModifierName()
	return "channelled_bomb_modifier"
end

LinkLuaModifier( "channelled_bomb_modifier", "plugin_system/plugins/attacks_cast_spells/channelled_bomb", LUA_MODIFIER_MOTION_NONE )
channelled_bomb_modifier = class({})
function channelled_bomb_modifier:IsPermanent() return true end
function channelled_bomb_modifier:RemoveOnDeath() return false end
function channelled_bomb_modifier:IsHidden() return true end
function channelled_bomb_modifier:IsDebuff() return false end
function channelled_bomb_modifier:DestroyOnExpire() return false end
function channelled_bomb_modifier:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function channelled_bomb_modifier:OnDestroy(keys)
	if not IsServer() then return end
end

function channelled_bomb_modifier:OnCreated(event)
	if not IsServer() then return end
    self.life = 5
end

function channelled_bomb_modifier:SetTarget(hAbility,hTarget)
    self:GetParent():AddNoDraw()
    self:StartIntervalThink(1)
    self.ability = hAbility
    self.target = hTarget
    self:GetParent():SetCursorCastTarget(self.target)
    self:GetParent():SetCursorPosition(self.target:GetAbsOrigin())
    if bit.band(self.ability:GetBehavior(), DOTA_ABILITY_BEHAVIOR_POINT) == DOTA_ABILITY_BEHAVIOR_POINT then
        ExecuteOrderFromTable({
            UnitIndex = self:GetParent():entindex(),
            OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
            TargetIndex = self.target:entindex(),
            AbilityIndex = self.ability:entindex(),
            Position = self.target:GetAbsOrigin(),
            Queue = false
        })
    elseif bit.band(self.ability:GetBehavior(), DOTA_ABILITY_BEHAVIOR_NO_TARGET) == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
            ExecuteOrderFromTable({
                UnitIndex = self:GetParent():entindex(),
                OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
                AbilityIndex = self.ability:entindex(),
                Queue = false
            })
    else
        ExecuteOrderFromTable({
            UnitIndex = self:GetParent():entindex(),
            OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
            TargetIndex = self.target:entindex(),
            AbilityIndex = self.ability:entindex(),
            Queue = false
        })
    end
end

function channelled_bomb_modifier:OnIntervalThink()
	if not IsServer() then return end
    if self:GetParent():IsChanneling() then return end
    self.life = self.life - 1
    if self.life == 0 then
        self:SetStackCount(1)
    end
    if self.life == -30 then
        self:GetParent():ForceKill(false)
    end
end

function channelled_bomb_modifier:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
    }
end

function channelled_bomb_modifier:CheckState()
    return {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_BLIND] = self:GetStackCount() == 1,
    }
end
function channelled_bomb_modifier:GetModifierIgnoreMovespeedLimit()
    return 1
end
