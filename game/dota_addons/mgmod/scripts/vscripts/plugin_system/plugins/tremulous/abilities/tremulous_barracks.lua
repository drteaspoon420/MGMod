LinkLuaModifier( "modifier_tremulous_barracks", "plugin_system/plugins/tremulous/abilities/tremulous_barracks", LUA_MODIFIER_MOTION_NONE )
tremulous_barracks = class({})
function tremulous_barracks:GetIntrinsicModifierName() return "modifier_tremulous_barracks" end
modifier_tremulous_barracks = class({})
function modifier_tremulous_barracks:IsHidden() return true end

function modifier_tremulous_barracks:OnCreated(event)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_tremulous_barracks:OnIntervalThink()
	if not IsServer() then return end

    local hAbility = self:GetAbility()
    if hAbility == nil then return end

    if not self:GetParent():IsAlive() then return end
    if self:GetParent():HasModifier("modifier_building_inprogress") then return end

    --requires 'power aura' from ancient
    if not self:GetParent():HasModifier("modifier_tremulous_power_aura") then return end
    self:FindEnemyBase()
    if not hAbility:IsCooldownReady() then return end
    hAbility:StartCooldown(hAbility:GetCooldown(1))

    

    local sUnit = "npc_tremulous_creep"

    local vcPos = self:GetParent():GetAbsOrigin()
    local icTeam = self:GetParent():GetTeam()
    local hMod = self

    for i=1,4 do
        CreateUnitByNameAsync(sUnit,vcPos,true,nil,nil,icTeam,
            function(hNpc)
            hNpc.owner = hMod
            Timers:CreateTimer(5,function()
                if hNpc ~= nil then
                    if hNpc:IsAlive() then
                        if hNpc:IsIdle() then
                            if hNpc.owner ~= nil then
                                if hNpc.owner.enemy_base ~= nil then
                                    local tOrder = {
                                        UnitIndex = hNpc:entindex(),
                                        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
                                        Position = hNpc.owner.enemy_base
                                    }
                                    ExecuteOrderFromTable(tOrder)
                                end
                            end
                        end
                        return 5
                    else
                        return
                    end
                else
                    return
                end
            end)

        end)
    end


end

function modifier_tremulous_barracks:FindEnemyBase()
    local hUnit = self:GetParent()
    local vPos = hUnit:GetAbsOrigin()
    local iTeam = hUnit:GetTeam()
    local tUnits = FindUnitsInRadius(
        iTeam,
        vPos,
        nil,
        FIND_UNITS_EVERYWHERE,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_ALL,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_CLOSEST,
        false
    )
    if #tUnits > 0 then
        for i=1,#tUnits do
            if tUnits[i]:HasModifier("modifier_tremulous_power_aura") then
                self.enemy_base = tUnits[i]:GetAbsOrigin()
                break
            end
        end
    end
end