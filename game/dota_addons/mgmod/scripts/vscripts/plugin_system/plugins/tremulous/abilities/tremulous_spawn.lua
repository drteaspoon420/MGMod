LinkLuaModifier( "modifier_tremulous_spawn", "plugin_system/plugins/tremulous/abilities/tremulous_spawn", LUA_MODIFIER_MOTION_NONE )
tremulous_spawn = class({})
function tremulous_spawn:GetIntrinsicModifierName() return "modifier_tremulous_spawn" end
modifier_tremulous_spawn = class({})
function modifier_tremulous_spawn:IsHidden() return true end

function modifier_tremulous_spawn:OnCreated(event)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_tremulous_spawn:CheckState()
    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end

function modifier_tremulous_spawn:OnIntervalThink()
	if not IsServer() then return end

    --checking if everything is fine
    if TremulousPlugin == nil then return end
    if TremulousPlugin.SpawnPointTryRespawn == nil then return end

    --is connected to ability like it should?
    local hAbility = self:GetAbility()
    if hAbility == nil then return end

    --dead node should not spawn
    if not self:GetParent():IsAlive() then return end

    --requires 'power aura' from ancient
    if not self:GetParent():HasModifier("modifier_tremulous_power_aura") then
        return
    end

    --is it on cooldown?
    if not hAbility:IsCooldownReady() then return end

    --is there any actual dead players
    if not TremulousPlugin:SpawnPointTryRespawn(self:GetParent()) then return end
    hAbility:StartCooldown(hAbility:GetCooldown(1))
end