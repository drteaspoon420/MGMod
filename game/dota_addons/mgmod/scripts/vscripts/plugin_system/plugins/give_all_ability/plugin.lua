ExtraAbilityPlugin = class({})
_G.ExtraAbilityPlugin = ExtraAbilityPlugin
ExtraAbilityPlugin.unit_cache = {}

function ExtraAbilityPlugin:Init()
    print("[ExtraAbilityPlugin] found")
end

function ExtraAbilityPlugin:ApplySettings()
    
    ExtraAbilityPlugin.settings = PluginSystem:GetAllSetting("give_all_ability")
    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        ExtraAbilityPlugin:SpawnEvent(event)
end,nil)
end
 
    
function ExtraAbilityPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end
    if hUnit:IsRealHero() then
        if hUnit:HasAbility(ExtraAbilityPlugin.settings.extra_ability_heroes) then return end
        if ExtraAbilityPlugin.unit_cache[event.entindex] ~= nil then return end
        ExtraAbilityPlugin.unit_cache[event.entindex] = true
        local hAbility = hUnit:AddAbility(ExtraAbilityPlugin.settings.extra_ability_heroes)
        if hAbility ~= nil then
            hAbility:SetLevel(hAbility:GetMaxLevel())
        end
    end
    if hUnit:IsCreep() then
        if hUnit:HasAbility(ExtraAbilityPlugin.settings.extra_ability_creeps) then return end
        local hAbility = hUnit:AddAbility(ExtraAbilityPlugin.settings.extra_ability_creeps)
        if hAbility ~= nil then
            hAbility:SetLevel(hAbility:GetMaxLevel())
        end
    end
end
