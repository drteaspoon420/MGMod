MammonitePlugin = class({})
_G.MammonitePlugin = MammonitePlugin
MammonitePlugin.unit_cache = {}

function MammonitePlugin:Init()
    --print("[MammonitePlugin] found")
end

function MammonitePlugin:ApplySettings()
    MammonitePlugin.settings = PluginSystem:GetAllSetting("mammonite")
    LinkLuaModifier( "modifier_mammonite_shield", "plugin_system/plugins/mammonite/modifier_mammonite_shield", LUA_MODIFIER_MOTION_NONE )
    --print("mammonite settings!")
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            MammonitePlugin:SpawnEvent(event)
    end,nil)
end

function MammonitePlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        if MammonitePlugin.unit_cache[event.entindex] ~= nil then return end
        MammonitePlugin.unit_cache[event.entindex] = true
        local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_mammonite_shield",{})
        --print("added mammonite")
    end
end
