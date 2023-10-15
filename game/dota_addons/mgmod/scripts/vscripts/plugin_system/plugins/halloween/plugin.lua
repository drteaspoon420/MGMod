HalloweenPlugin = class({})
_G.HalloweenPlugin = HalloweenPlugin
HalloweenPlugin.settings = {
}

function HalloweenPlugin:Init()
    print("[HalloweenPlugin] found")
end

function HalloweenPlugin:ApplySettings()
    HalloweenPlugin.settings = PluginSystem:GetAllSetting("halloween")

    local vPos = Vector(0,0,0)
    local iTeam = DOTA_TEAM_NEUTRALS
    CreateUnitByNameAsync("npc_mgmod_halloween_fishmaster",vPos,true,nil,nil,iTeam,
    function(hNpc)
        for i=0,hNpc:GetAbilityCount() do
            local hAbility = hNpc:GetAbilityByIndex(i)
            if hAbility ~= nil then
                hAbility:SetLevel(1)
            end
        end
        FindClearSpaceForUnit(hNpc,vPos,true)
        HalloweenPlugin.fish_master = hNpc
        Timers:CreateTimer(1,function()
            HalloweenPlugin:FishmasterAi()
            return 1
        end)
    end)
end


function HalloweenPlugin:FishmasterAi()
    if HalloweenPlugin.fish_master == nil then return 1 end

    if HalloweenPlugin.beg_target == nil then
        --find target hero that does not have conga hex curse
        local t = {}
        for iPlayer = 0,DOTA_MAX_PLAYERS do
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer ~= nil then
                local hHero = hPlayer:GetAssignedHero()
                if hHero ~= nil then
                    if not hHero:HasModifier("modifier_fish_master_curse") then
                        table.insert(t,hHero)
                    end
                end
            end
        end
        local hTarget = Toolbox:GetRandomValue(t)
        HalloweenPlugin.beg_target = hTarget
    else
        local vPos = HalloweenPlugin.beg_target:GetAbsOrigin()
        local vMPos = HalloweenPlugin.fish_master:GetAbsOrigin()
        --check if near a target
        if (vPos - vMPos):Length2D() > 350 then
            --start asking for candy
            if HalloweenPlugin.fish_master:HasModifier("modifier_fish_master_beg") then
                local hMod =  HalloweenPlugin.fish_master:FindModifierByName("modifier_fish_master_beg")
                --check if asked three times
                if hMod:GetStackCount() > 3 then
                    --curse
                    local tOrder = {
                        UnitIndex = HalloweenPlugin.fish_master:entindex(),
                        OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
                        AbilityIndex = HalloweenPlugin.fish_master:FindAbilityByName("fish_master_curse"):entindex(),
                        TargetIndex = HalloweenPlugin.beg_target:entindex()
                    }
                    ExecuteOrderFromTable(tOrder)
                    HalloweenPlugin.beg_target = nil
                    return 3
                else
                    local tOrder = {
                        UnitIndex = HalloweenPlugin.fish_master:entindex(),
                        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
                        AbilityIndex = HalloweenPlugin.fish_master:FindAbilityByName("fish_master_beg"):entindex()
                    }
                    ExecuteOrderFromTable(tOrder)
                    return 3
                end
            else
                local tOrder = {
                    UnitIndex = HalloweenPlugin.fish_master:entindex(),
                    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
                    AbilityIndex = HalloweenPlugin.fish_master:FindAbilityByName("fish_master_beg"):entindex()
                }
                ExecuteOrderFromTable(tOrder)
                return 3
            end
        else
            --follow target
            local tOrder = {
                UnitIndex = HalloweenPlugin.fish_master:entindex(),
                OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                Position = vPos
            }
            ExecuteOrderFromTable(tOrder)
            return 1
        end
    end
    return 1
end
