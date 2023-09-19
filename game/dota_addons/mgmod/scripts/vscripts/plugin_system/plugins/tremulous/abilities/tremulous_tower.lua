LinkLuaModifier( "modifier_tremulous_tower", "plugin_system/plugins/tremulous/abilities/tremulous_tower", LUA_MODIFIER_MOTION_NONE )
tremulous_tower = class({})
function tremulous_tower:GetIntrinsicModifierName() return "modifier_tremulous_tower" end
modifier_tremulous_tower = class({})
function modifier_tremulous_tower:IsHidden() return true end

function modifier_tremulous_tower:OnCreated(event)
	if not IsServer() then return end
	self:StartIntervalThink(1)
    self:SetStackCount(1)
end

function modifier_tremulous_tower:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = self:GetStackCount() > 0
    }
end


function modifier_tremulous_tower:OnIntervalThink()
	if not IsServer() then return end

    local hAbility = self:GetAbility()
    if hAbility == nil then return end

    if not self:GetParent():IsAlive() then return end
    if self:GetParent():HasModifier("modifier_building_inprogress") then return end

    --requires 'power aura' from ancient
    if not self:GetParent():HasModifier("modifier_tremulous_power_aura") and self:GetStackCount() < 1 then
        self:SetStackCount(1)
    elseif self:GetParent():HasModifier("modifier_tremulous_power_aura") and self:GetStackCount() > 0 then
        self:SetStackCount(0)
    end

end