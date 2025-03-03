ZombiesPlugin = class({})
_G.ZombiesPlugin = ZombiesPlugin
ZombiesPlugin.settings = {
}

function ZombiesPlugin:Init()
    --print("[ZombiesPlugin] found")
end

function ZombiesPlugin:ApplySettings()
    ZombiesPlugin.settings = PluginSystem:GetAllSetting("zombies")
    LinkLuaModifier( "modifier_zombie_power", "plugin_system/plugins/zombies/modifier_zombie_power", LUA_MODIFIER_MOTION_NONE )
    ZombiesPlugin.power = ZombiesPlugin.settings.initial_power
    if (ZombiesPlugin.power < 0) then ZombiesPlugin.power = 0 end
    ZombiesPlugin.wave_treshold = ZombiesPlugin.settings.wave_treshold
    if (ZombiesPlugin.wave_treshold < 1) then ZombiesPlugin.wave_treshold = 1 end
    if (ZombiesPlugin.settings.max_zombies < 1) then ZombiesPlugin.settings.max_zombies = 1 end
    if (ZombiesPlugin.settings.zombies_per_spawn < 1) then ZombiesPlugin.settings.zombies_per_spawn = 1 end
    if (ZombiesPlugin.settings.spawn_rate < 1) then ZombiesPlugin.settings.spawn_rate = 1 end
    if (ZombiesPlugin.settings.boss_multiplier < 1) then ZombiesPlugin.settings.boss_multiplier = 1 end
    ZombiesPlugin.count = 0
    ZombiesPlugin.wave = 0
    Timers:CreateTimer(0,function()
        return ZombiesPlugin:SpawnZombies()
    end)
end

function ZombiesPlugin:SpawnZombies()
    local hTarget = self:FindRandomHero()
    local vPos = self:FindRandomPosition(hTarget:GetAbsOrigin())
    local sUnitName = "npc_dota_zombies_basic_"
    local iii = (ZombiesPlugin.wave % 12) + 1
    local iUnitCount = math.min(ZombiesPlugin.settings.max_zombies-ZombiesPlugin.count,ZombiesPlugin.settings.zombies_per_spawn)
    if iUnitCount > 0 then
        for i=1,iUnitCount do
        CreateUnitByNameAsync(sUnitName .. iii,vPos, false, nil, nil, DOTA_TEAM_NEUTRALS,
            function (hUnit)
                ZombiesPlugin.count = ZombiesPlugin.count + 1
                hUnit:GiveMana(hUnit:GetMaxMana())
                FindClearSpaceForUnit(hUnit,vPos,false)
                hUnit:AddNewModifier(hUnit,nil,"modifier_zombie_power",{stack = ZombiesPlugin.power})
                Timers:CreateTimer(3,function()
                    if hUnit ~= nil and hTarget ~= nil then
                        if hUnit:IsAlive() then
                            if hUnit:IsIdle() then
                                local tOrder = {
                                    UnitIndex = hUnit:entindex(),
                                    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
                                    Position = hTarget:GetAbsOrigin()
                                }
                                ExecuteOrderFromTable(tOrder)
                            end
                            return 3
                        else
                            ZombiesPlugin.count = ZombiesPlugin.count - 1
                            return
                        end
                    else
                        return
                    end
                end)
            end)
        end
    else
        ZombiesPlugin:CombineZombies()
    end

    ZombiesPlugin.wave = ZombiesPlugin.wave + 1
    if (ZombiesPlugin.wave % ZombiesPlugin.wave_treshold == 0) then ZombiesPlugin.power = ZombiesPlugin.power + 1 end
    return ZombiesPlugin.settings.spawn_rate
end


function ZombiesPlugin:FindRandomPosition(vPos)
    local nPos = vPos
    local c = 0
    while IsLocationVisible(DOTA_TEAM_GOODGUYS,vPos) or IsLocationVisible(DOTA_TEAM_BADGUYS,vPos) or c > 100 do
        vPos = nPos + RandomVector(50*c)
        c = c + 1
    end
    return vPos
end


function ZombiesPlugin:FindRandomHero()
    local hEnt = Entities:First()
    local t = {}
    while hEnt do
        if hEnt:IsDOTANPC() and hEnt:IsRealHero() then
            table.insert(t,hEnt)
        end
        hEnt = Entities:Next(hEnt)
    end
    if #t > 0 then
        return t[RandomInt(1,#t)]
    else
        return nil
    end
end


function ZombiesPlugin:CombineZombies()
    
    local e = Entities:Next(nil)
    local t = {}
    while e do
        if e.HasModifier and e:HasModifier("modifier_zombie_power") then
            table.insert(t,e)
        end
        e = Entities:Next(e)
    end

    if #t > 1 then
        local big = t[1]
        big:SetModelScale(1.2)
        local c = 0
        for i=2,#t do
            local small = t[i]
            local hMod = small:FindModifierByName("modifier_zombie_power")
            c = c + hMod:GetStackCount() + 1
            small:Kill(nil,big)
        end
        local hModBig = big:FindModifierByName("modifier_zombie_power")
        hModBig:SetStackCount((hModBig:GetStackCount() + c)*ZombiesPlugin.settings.boss_multiplier)
        big:CalculateGenericBonuses()
    end
end

--[[ 
    NOTES:
    try bigger hull. make it more like legion
    more units?
    random extra ability list
    
    buff for 'power' level.

    more models?
 ]]