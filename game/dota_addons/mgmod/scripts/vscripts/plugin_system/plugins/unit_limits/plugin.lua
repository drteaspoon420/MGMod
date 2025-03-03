UnitLimitsPlugin = class({})
_G.UnitLimitsPlugin = UnitLimitsPlugin
UnitLimitsPlugin.settings = {}
UnitLimitsPlugin.unit_cache = {}

function UnitLimitsPlugin:Init()
    --print("[UnitLimitsPlugin] found")
end

function UnitLimitsPlugin:ApplySettings()
    UnitLimitsPlugin.settings = PluginSystem:GetAllSetting("unit_limits")
    
    Timers:CreateTimer(UnitLimitsPlugin.settings.check_invernal,function()
        UnitLimitsPlugin:CheckUnitCount()
        return UnitLimitsPlugin.settings.check_invernal
    end)
end

function UnitLimitsPlugin:CheckUnitCount()
    local hUnit = Entities:Next(nil)
    local count = 0
    while hUnit do
        if hUnit:IsDOTANPC() then
            count = count + 1
        end
        hUnit = Entities:Next(hUnit)
    end
    local to_remove = count - UnitLimitsPlugin.settings.max_units
    hUnit = Entities:Next(nil)
    while hUnit and to_remove > 0 do
        if hUnit:IsDOTANPC() and not hUnit:IsRealHero() and not hUnit:IsAlive() then
            UnitLimitsPlugin:NpcDestroy(hUnit)
            to_remove = to_remove - 1
        end
        hUnit = Entities:Next(hUnit)
    end

    hUnit = Entities:Next(nil)
    while hUnit and to_remove > 0 do
        if hUnit:IsDOTANPC() and not hUnit:IsRealHero() and (hUnit:IsIllusion() or hUnit:IsSummoned()) then
            UnitLimitsPlugin:NpcDestroy(hUnit)
            to_remove = to_remove - 1
        end
        hUnit = Entities:Next(hUnit)
    end

    hUnit = Entities:Next(nil)
    while hUnit and to_remove > 0 do
        if hUnit:IsDOTANPC() and hUnit:IsWard() then
            UnitLimitsPlugin:NpcDestroy(hUnit)
            to_remove = to_remove - 1
        end
        hUnit = Entities:Next(hUnit)
    end

    hUnit = Entities:Next(nil)
    while hUnit and to_remove > 0 do
        if hUnit:IsDOTANPC() and hUnit:IsCreep() then
            UnitLimitsPlugin:NpcDestroy(hUnit)
            to_remove = to_remove - 1
        end
        hUnit = Entities:Next(hUnit)
    end
end

function UnitLimitsPlugin:NpcDestroy(hUnit)
    --print("[Unit limit reached, deleting]: ",hUnit:GetName())
    hUnit:Destroy()
end