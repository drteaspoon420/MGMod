AttacksCastSpellsPlugin = class({})
_G.AttacksCastSpellsPlugin = AttacksCastSpellsPlugin
AttacksCastSpellsPlugin.unit_cache = {}

function AttacksCastSpellsPlugin:Init()
    print("[AttacksCastSpellsPlugin] found")
end

function AttacksCastSpellsPlugin:ApplySettings()

    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        AttacksCastSpellsPlugin:SpawnEvent(event)
end,nil)
end
 
    
function AttacksCastSpellsPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        if AttacksCastSpellsPlugin.unit_cache[event.entindex] ~= nil then return end
        AttacksCastSpellsPlugin.unit_cache[event.entindex] = true
        local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_attacks_cast_spells",{})
    end
end
