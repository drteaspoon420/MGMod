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

    --requires 'power aura' from ancient
    if not self:GetParent():HasModifier("modifier_tremulous_power_aura") then return end
    if not hAbility:IsCooldownReady() then return end
    hAbility:StartCooldown(hAbility:GetCooldown(1))

    

    local sUnit = "npc_tremulous_creep"

    local vcPos = self:GetParent():GetAbsOrigin()
    local icTeam = self:GetParent():GetTeam()

    for i=1,4 do
        CreateUnitByNameAsync(sUnit,vcPos,true,nil,nil,icTeam,
            function(hNpc)
            Timers:CreateTimer(3,function()
                if hNpc ~= nil then
                    if hNpc:IsAlive() then
                        if hNpc:IsIdle() then
                            local vPos = hNpc:GetAbsOrigin()
                            local iTeam = hNpc:GetTeam()
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
                                local vTarget = hNpc:GetAbsOrigin()
                                for i=1,#tUnits do
                                    if tUnits[i]:HasModifier("modifier_tremulous_power_aura") then
                                        vTarget = tUnits[i]:GetAbsOrigin()
                                        break
                                    end
                                end
                                local tOrder = {
                                    UnitIndex = hNpc:entindex(),
                                    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
                                    Position = vTarget
                                }
                                ExecuteOrderFromTable(tOrder)
                            end
                        end
                        return 3
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