ThanksIHateItPlugin = class({})
_G.ThanksIHateItPlugin = ThanksIHateItPlugin

function ThanksIHateItPlugin:Init()
    print("[ThanksIHateItPlugin] found")
end

function ThanksIHateItPlugin:ApplySettings()
    ThanksIHateItPlugin.settings = PluginSystem:GetAllSetting("thanksihateit")

    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        ThanksIHateItPlugin:SpawnEvent(event)
    end,nil)

    
end


function ThanksIHateItPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end

    if hUnit:IsRealHero() then
        if ThanksIHateItPlugin.settings.killstreak_power then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_death_item_loss",{})
        end
    end
    
end

