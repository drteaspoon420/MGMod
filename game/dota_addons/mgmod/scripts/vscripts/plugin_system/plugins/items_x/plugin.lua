ItemsXPlugin = class({})
_G.ItemsXPlugin = ItemsXPlugin

function ItemsXPlugin:Init()
    print("[ItemsXPlugin] found")
end

function ItemsXPlugin:ApplySettings()
    ItemsXPlugin.settings = PluginSystem:GetAllSetting("items_x")
    LinkLuaModifier( "modifier_items_x", "plugin_system/plugins/items_x/modifier_items_x", LUA_MODIFIER_MOTION_NONE )
    print("items_x settings!")
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            ItemsXPlugin:SpawnEvent(event)
    end,nil)
end

function ItemsXPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.HasInventory then return end
    if hUnit:HasInventory() then
        local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_items_x",{
            mod_duration = ItemsXPlugin.settings.mod_duration,
            mod_chance = ItemsXPlugin.settings.mod_chance,
            mod_radius = ItemsXPlugin.settings.mod_radius,
            core_multiplier = ItemsXPlugin.settings.multiplier
        })
    end
end
