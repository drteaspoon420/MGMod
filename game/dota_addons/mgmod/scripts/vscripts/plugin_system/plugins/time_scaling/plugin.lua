TimeScalingPlugin = class({})
_G.TimeScalingPlugin = TimeScalingPlugin
TimeScalingPlugin.unit_cache = {}

function TimeScalingPlugin:Init()
    print("[TimeScalingPlugin] found")
end

function TimeScalingPlugin:ApplySettings()
    TimeScalingPlugin.settings = PluginSystem:GetAllSetting("time_scaling")
    LinkLuaModifier( "modifier_time_scaling_heroes", "plugin_system/plugins/time_scaling/modifier_time_scaling_heroes", LUA_MODIFIER_MOTION_NONE )
    print("time_scaling settings!")
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            TimeScalingPlugin:SpawnEvent(event)
    end,nil)
end

function TimeScalingPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        if TimeScalingPlugin.unit_cache[event.entindex] ~= nil then return end
        TimeScalingPlugin.unit_cache[event.entindex] = true
        local kv = {}
        kv.hp_max =             TimeScalingPlugin.settings.hp_max
        kv.mp_max =             TimeScalingPlugin.settings.mp_max
        kv.str =                TimeScalingPlugin.settings.str
        kv.agi =                TimeScalingPlugin.settings.agi
        kv.int =                TimeScalingPlugin.settings.int
        kv.armor =              TimeScalingPlugin.settings.armor
        kv.magic_resist =       TimeScalingPlugin.settings.magic_resist
        kv.status_resist =      TimeScalingPlugin.settings.status_resist
        kv.attack_speed =       TimeScalingPlugin.settings.attack_speed
        kv.attack_damage =      TimeScalingPlugin.settings.attack_damage
        kv.interval =           TimeScalingPlugin.settings.interval
        local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_time_scaling_heroes",kv)
    end
end
