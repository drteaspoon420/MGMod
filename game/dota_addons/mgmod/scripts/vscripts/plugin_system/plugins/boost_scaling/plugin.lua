BoostScalingPlugin = class({})
_G.BoostScalingPlugin = BoostScalingPlugin
BoostScalingPlugin.settings = {}
BoostScalingPlugin.unit_cache = {}

function BoostScalingPlugin:Init()
    print("[BoostScalingPlugin] found")
end

function BoostScalingPlugin:ApplySettings()
    BoostScalingPlugin.settings = PluginSystem:GetAllSetting("boost_scaling")
    LinkLuaModifier("boost_scaling_bonus_hp", "plugin_system/plugins/boost_scaling/boost_scaling_bonus_hp.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("boost_scaling_bonus_hp_regen", "plugin_system/plugins/boost_scaling/boost_scaling_bonus_hp_regen.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("boost_scaling_bonus_damage", "plugin_system/plugins/boost_scaling/boost_scaling_bonus_damage.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("boost_scaling_bonus_armor", "plugin_system/plugins/boost_scaling/boost_scaling_bonus_armor.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("boost_scaling_bonus_magic_resistance", "plugin_system/plugins/boost_scaling/boost_scaling_bonus_magic_resistance.lua", LUA_MODIFIER_MOTION_NONE)
    for _, building in pairs(Toolbox:AllTowers()) do
        if BoostScalingPlugin.settings.tower_bonus_hp > 0 then
            building:AddNewModifier(building, nil, "boost_scaling_bonus_hp", {})
        end
        if BoostScalingPlugin.settings.tower_bonus_hp_regen > 0 then
            building:AddNewModifier(building, nil, "boost_scaling_bonus_hp_regen", {})
        end
        if BoostScalingPlugin.settings.tower_bonus_damage > 0 then
            building:AddNewModifier(building, nil, "boost_scaling_bonus_damage", {})
        end
        if BoostScalingPlugin.settings.tower_bonus_armor > 0 then
            building:AddNewModifier(building, nil, "boost_scaling_bonus_armor", {})
        end

        if BoostScalingPlugin.settings.tower_bonus_magic_resistance > 0 then
            building:AddNewModifier(building, nil, "boost_scaling_bonus_magic_resistance", {})
        end
    end

    PluginSystem:InternalEvent_Register("boost_grant_all",function()
        BoostScalingPlugin:BoostTowersAll()
    end)

    PluginSystem:InternalEvent_Register("boost_grant_team",function(event)
        DeepPrintTable(event)
        BoostScalingPlugin:BoostTowersTeam(event.team)
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

function BoostScalingPlugin:BoostTower(tower)
    if BoostScalingPlugin.settings.tower_bonus_hp > 0 then
        local hMod = tower:FindAllModifiersByName("boost_scaling_bonus_hp")[1]
        if hMod ~= nil then hMod:SetStackCount(hMod:GetStackCount() + BoostScalingPlugin.settings.tower_bonus_hp) end
    end
    if BoostScalingPlugin.settings.tower_bonus_hp_regen > 0 then
        local hMod = tower:FindAllModifiersByName("boost_scaling_bonus_hp_regen")[1]
        if hMod ~= nil then hMod:SetStackCount(hMod:GetStackCount() + BoostScalingPlugin.settings.tower_bonus_hp_regen) end
    end
    if BoostScalingPlugin.settings.tower_bonus_damage > 0 then
        local hMod = tower:FindAllModifiersByName("boost_scaling_bonus_damage")[1]
        if hMod ~= nil then hMod:SetStackCount(hMod:GetStackCount() + BoostScalingPlugin.settings.tower_bonus_damage) end
    end
    if BoostScalingPlugin.settings.tower_bonus_armor > 0 then
        local hMod = tower:FindAllModifiersByName("boost_scaling_bonus_armor")[1]
        if hMod ~= nil then hMod:SetStackCount(hMod:GetStackCount() + BoostScalingPlugin.settings.tower_bonus_armor) end
    end
    if BoostScalingPlugin.settings.tower_bonus_magic_resistance > 0 then
        local hMod = tower:FindAllModifiersByName("boost_scaling_bonus_magic_resistance")[1]
        if hMod ~= nil then hMod:SetStackCount(hMod:GetStackCount() + BoostScalingPlugin.settings.tower_bonus_magic_resistance) end
    end
end