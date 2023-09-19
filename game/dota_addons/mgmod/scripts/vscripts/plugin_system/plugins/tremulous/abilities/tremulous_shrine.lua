LinkLuaModifier( "modifier_tremulous_shrine", "plugin_system/plugins/tremulous/abilities/tremulous_shrine", LUA_MODIFIER_MOTION_NONE )
tremulous_shrine = class({})
function tremulous_shrine:GetIntrinsicModifierName() return "modifier_tremulous_shrine" end
modifier_tremulous_shrine = class({})
function modifier_tremulous_shrine:IsHidden() return true end

function modifier_tremulous_shrine:OnCreated(event)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_tremulous_shrine:OnIntervalThink()
	if not IsServer() then return end

    local hAbility = self:GetAbility()
    if hAbility == nil then return end

    if not self:GetParent():IsAlive() then return end

    --requires 'power aura' from ancient
    if not self:GetParent():HasModifier("modifier_tremulous_power_aura") then
        return
    end

    if self:GetParent():HasModifier("modifier_building_inprogress") then return end
    
	local tUnits = FindUnitsInRadius(
        self:GetParent():GetTeam(),
        self:GetParent():GetOrigin(),
        nil, self:GetAbility():GetSpecialValueFor("radius"),
        DOTA_UNIT_TARGET_TEAM_FRIENDLY ,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE ,
        FIND_ANY_ORDER ,
        false)
    if #tUnits > 0 then
        for i=1,#tUnits do
            tUnits[i]:Heal(self:GetAbility():GetSpecialValueFor("heal"),self:GetAbility())
            tUnits[i]:GiveMana(self:GetAbility():GetSpecialValueFor("mana"))
        end
    end

end