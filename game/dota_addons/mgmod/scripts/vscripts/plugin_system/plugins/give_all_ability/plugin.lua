ExtraAbilityPlugin = class({})
_G.ExtraAbilityPlugin = ExtraAbilityPlugin
ExtraAbilityPlugin.unit_cache = {}
ExtraAbilityPlugin.extra_ability_towers = {}
ExtraAbilityPlugin.extra_item_towers = {}
ExtraAbilityPlugin.extra_ability_heroes = {}
ExtraAbilityPlugin.extra_item_heroes = {}
ExtraAbilityPlugin.extra_ability_creeps = {}
ExtraAbilityPlugin.extra_item_creeps = {}

function ExtraAbilityPlugin:Init()
    --print("[ExtraAbilityPlugin] found")
end

function ExtraAbilityPlugin:ApplySettings()
    
    ExtraAbilityPlugin.settings = PluginSystem:GetAllSetting("give_all_ability")

    if (ExtraAbilityPlugin.settings.extra_ability_towers ~= "") then
        ExtraAbilityPlugin.extra_ability_towers = Toolbox:split(ExtraAbilityPlugin.settings.extra_ability_towers,",")
    end
    if (ExtraAbilityPlugin.settings.extra_item_towers ~= "") then
        ExtraAbilityPlugin.extra_item_towers = Toolbox:split(ExtraAbilityPlugin.settings.extra_item_towers,",")
    end
    if (ExtraAbilityPlugin.settings.extra_ability_heroes ~= "") then
        ExtraAbilityPlugin.extra_ability_heroes = Toolbox:split(ExtraAbilityPlugin.settings.extra_ability_heroes,",")
    end
    if (ExtraAbilityPlugin.settings.extra_item_heroes ~= "") then
        ExtraAbilityPlugin.extra_item_heroes = Toolbox:split(ExtraAbilityPlugin.settings.extra_item_heroes,",")
    end
    if (ExtraAbilityPlugin.settings.extra_ability_creeps ~= "") then
        ExtraAbilityPlugin.extra_ability_creeps = Toolbox:split(ExtraAbilityPlugin.settings.extra_ability_creeps,",")
    end
    if (ExtraAbilityPlugin.settings.extra_item_creeps ~= "") then
        ExtraAbilityPlugin.extra_item_creeps = Toolbox:split(ExtraAbilityPlugin.settings.extra_item_creeps,",")
    end
    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        ExtraAbilityPlugin:SpawnEvent(event)
end,nil)
    local towers = Toolbox:AllTowers()
    for _,hTower in pairs(towers) do
        for _,sAbility in pairs(ExtraAbilityPlugin.extra_ability_towers) do
            ExtraAbilityPlugin:AddAbility(hTower,sAbility)
        end
        for _,sItem in pairs(ExtraAbilityPlugin.extra_item_towers) do
            ExtraAbilityPlugin:AddItem(hTower,sItem)
        end
    end
end
 
    
function ExtraAbilityPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end
    if hUnit:UnitCanRespawn() then
        if ExtraAbilityPlugin.unit_cache[event.entindex] ~= nil then return end
        ExtraAbilityPlugin.unit_cache[event.entindex] = true
    end
    if hUnit:IsRealHero() then
        for _,sAbility in pairs(ExtraAbilityPlugin.extra_ability_heroes) do
            ExtraAbilityPlugin:AddAbility(hUnit,sAbility)
        end
        for _,sItem in pairs(ExtraAbilityPlugin.extra_item_heroes) do
            ExtraAbilityPlugin:AddItem(hUnit,sItem)
        end
    end
    if hUnit:IsCreep() then
        for _,sAbility in pairs(ExtraAbilityPlugin.extra_ability_creeps) do
            ExtraAbilityPlugin:AddAbility(hUnit,sAbility)
        end
        for _,sItem in pairs(ExtraAbilityPlugin.extra_item_creeps) do
            ExtraAbilityPlugin:AddItem(hUnit,sItem)
        end
    end
    
end


function ExtraAbilityPlugin:AddAbility(hUnit,sAbility)
    if sAbility == "" then return end
    if not (ExtraAbilityPlugin.settings.core_apply_team == 0 or hUnit:GetTeam() == ExtraAbilityPlugin.settings.core_apply_team) then return end
    if hUnit:HasAbility(sAbility) then return end
    local hAbility = hUnit:AddAbility(sAbility)
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

function ExtraAbilityPlugin:AddItem(hUnit,sItem)
    if sAbility == "" then return end
    if not (ExtraAbilityPlugin.settings.core_apply_team == 0 or hUnit:GetTeam() == ExtraAbilityPlugin.settings.core_apply_team) then return end
    hUnit:AddItemByName(sItem)
end