BoostScalingPlugin = class({})
_G.BoostScalingPlugin = BoostScalingPlugin
BoostScalingPlugin.settings = {}
BoostScalingPlugin.unit_cache = {}

function BoostScalingPlugin:Init()
    print("[BoostScalingPlugin] found")
end

function BoostScalingPlugin:ApplySettings()
    BoostScalingPlugin.settings = PluginSystem:GetAllSetting("boost_scaling")

    -- tower scaling
    LinkLuaModifier("modifier_boost_scaling_tower", "plugin_system/plugins/boost_scaling/modifier_boost_scaling_tower.lua", LUA_MODIFIER_MOTION_NONE)
    for _, building in pairs(Toolbox:AllTowers()) do
        building:AddNewModifier(building, nil, "modifier_boost_scaling_tower", {
            tower_bonus_damage = BoostScalingPlugin.settings.tower_bonus_damage,
            tower_bonus_magic_resistance = BoostScalingPlugin.settings.tower_bonus_magic_resistance,
            tower_bonus_armor = BoostScalingPlugin.settings.tower_bonus_armor,
            tower_bonus_hp_regen = BoostScalingPlugin.settings.tower_bonus_hp_regen,
            tower_bonus_hp = BoostScalingPlugin.settings.tower_bonus_hp
        })
    end

    -- unit scaling    
    LinkLuaModifier("modifier_boost_scaling_creep_aura", "plugin_system/plugins/boost_scaling/modifier_boost_scaling_creep_aura.lua", LUA_MODIFIER_MOTION_NONE)
    for _, building in pairs(Toolbox:AllAncients()) do
        print("adding creep aura to tower")
        building:AddNewModifier(building, nil, "modifier_boost_scaling_creep_aura", {
            creep_bonus_hp = BoostScalingPlugin.settings.creep_bonus_hp,
            creep_bonus_hp_regen = BoostScalingPlugin.settings.creep_bonus_hp_regen,
            creep_bonus_armor = BoostScalingPlugin.settings.creep_bonus_armor,
            creep_bonus_magic_resistance = BoostScalingPlugin.settings.creep_bonus_magic_resistance,
            creep_bonus_damage = BoostScalingPlugin.settings.creep_bonus_damage,
            creep_bonus_building_damage = BoostScalingPlugin.settings.creep_bonus_building_damage,
        })
    end

    PluginSystem:InternalEvent_Register("boost_grant_all",function()
        BoostScalingPlugin:BoostTowersAll()
        BoostScalingPlugin:BoostCreepsAll()
    end)

    PluginSystem:InternalEvent_Register("boost_grant_team",function(event)
        BoostScalingPlugin:BoostTowersTeam(event.team)
        BoostScalingPlugin:BoostCreepsTeam(event.team)
    end)
end

function BoostScalingPlugin:BoostTowersAll()
    for _, building in pairs(Toolbox:AllTowers()) do
        BoostScalingPlugin:BoostTower(building)
    end
end

function BoostScalingPlugin:BoostTowersTeam(iTeam)
    for _, building in pairs(Toolbox:AllTowers()) do
        if building:GetTeam() == iTeam then
            BoostScalingPlugin:BoostTower(building)
        end
    end
end

function BoostScalingPlugin:BoostCreepsAll()
    for _, building in pairs(Toolbox:AllAncients()) do
        BoostScalingPlugin:BoostCreeps(building)
    end
end

function BoostScalingPlugin:BoostCreepsTeam(iTeam)
    for _, building in pairs(Toolbox:AllAncients()) do
        if building:GetTeam() == iTeam then
            BoostScalingPlugin:BoostCreeps(building)
        end
    end
end

function BoostScalingPlugin:BoostTower(tower)
    local hMod = tower:FindAllModifiersByName("modifier_boost_scaling_tower")[1]
    if hMod ~= nil then
        hMod:SetStackCount(hMod:GetStackCount() + 1)
        tower:CalculateGenericBonuses()
    end
end

function BoostScalingPlugin:BoostCreeps(ancient)
    local hMod = ancient:FindAllModifiersByName("modifier_boost_scaling_creep_aura")[1]
    if hMod ~= nil then
        hMod:SetStackCount(hMod:GetStackCount() + 1)
    end
end