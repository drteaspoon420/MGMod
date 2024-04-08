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
    
    if ExtraAbilityPlugin.settings.extra_ability_towers ~= nil and ExtraAbilityPlugin.settings.extra_ability_towers ~= "" then
        local towers = Toolbox:AllTowers()
        for _,hTower in pairs(towers) do
            if hTower:HasAbility(ExtraAbilityPlugin.settings.extra_ability_towers) then return end
            local hAbility = hTower:AddAbility(ExtraAbilityPlugin.settings.extra_ability_towers)
            if hAbility ~= nil then
                hAbility:SetLevel(hAbility:GetMaxLevel())
            end
        end
    end
end
 
    
function ExtraAbilityPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end
    if hUnit:IsRealHero() then
        if ExtraAbilityPlugin.settings.extra_ability_heroes == nil or ExtraAbilityPlugin.settings.extra_ability_heroes == "" then return end
        if hUnit:HasAbility(ExtraAbilityPlugin.settings.extra_ability_heroes) then return end
        if ExtraAbilityPlugin.unit_cache[event.entindex] ~= nil then return end
        ExtraAbilityPlugin.unit_cache[event.entindex] = true
        local hAbility = hUnit:AddAbility(ExtraAbilityPlugin.settings.extra_ability_heroes)
        if hAbility ~= nil then
            hAbility:SetLevel(hAbility:GetMaxLevel())
            if hUnit.IsRealHero ~= nil and hUnit:IsRealHero() then
                local iPlayer = hUnit:GetPlayerOwnerID()
                PluginSystem:InternalEvent_Call("hero_build_change",{
                    iPlayer = iPlayer
                })
            end
        end
    end
    if hUnit:IsCreep() then
        if ExtraAbilityPlugin.settings.extra_ability_creeps == nil or ExtraAbilityPlugin.settings.extra_ability_creeps == "" then return end
        if hUnit:HasAbility(ExtraAbilityPlugin.settings.extra_ability_creeps) then return end
        local hAbility = hUnit:AddAbility(ExtraAbilityPlugin.settings.extra_ability_creeps)
        if hAbility ~= nil then
            hAbility:SetLevel(hAbility:GetMaxLevel())
        end
    end
    
end
