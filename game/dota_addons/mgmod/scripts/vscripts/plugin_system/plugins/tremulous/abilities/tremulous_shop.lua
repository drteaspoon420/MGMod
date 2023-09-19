LinkLuaModifier( "modifier_tremulous_shop", "plugin_system/plugins/tremulous/abilities/tremulous_shop", LUA_MODIFIER_MOTION_NONE )
tremulous_shop = class({})
function tremulous_shop:GetIntrinsicModifierName() return "modifier_tremulous_shop" end
modifier_tremulous_shop = class({})
function modifier_tremulous_shop:IsHidden() return true end

function modifier_tremulous_shop:OnCreated(event)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_tremulous_shop:OnIntervalThink()
	if not IsServer() then return end

    local hAbility = self:GetAbility()
    if hAbility == nil then return end

    if not self:GetParent():IsAlive() then return end

    if self:GetParent():HasModifier("modifier_building_inprogress") then return end
    --requires 'power aura' from ancient
    if not self:GetParent():HasModifier("modifier_tremulous_power_aura") and self.shop ~= nil then
        self.shop:Destroy()
        self.shop = nil
    elseif self:GetParent():HasModifier("modifier_tremulous_power_aura") and self.shop == nil then
        self.shop = SpawnDOTAShopTriggerRadiusApproximate(self:GetParent():GetAbsOrigin(),self:GetAbility():GetSpecialValueFor("radius"))
        self.shop:SetShopType(DOTA_SHOP_HOME)
    end

end
function modifier_tremulous_shop:OnDestroy(event)
	if not IsServer() then return end
    if self.shop ~= nil then
        self.shop:Destroy()
        self.shop = nil
    end
end