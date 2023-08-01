TowerBuffsPlugin = class({})
_G.TowerBuffsPlugin = TowerBuffsPlugin
TowerBuffsPlugin.settings = {}
TowerBuffsPlugin.unit_cache = {}

function TowerBuffsPlugin:Init()
    print("[TowerBuffsPlugin] found")
end

function TowerBuffsPlugin:ApplySettings()
    TowerBuffsPlugin.settings = PluginSystem:GetAllSetting("tower_buffs")
    LinkLuaModifier("tower_buffs_no_backdoor", "plugin_system/plugins/tower_buffs/tower_buffs_no_backdoor.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("tower_buffs_bonus_hp", "plugin_system/plugins/tower_buffs/tower_buffs_bonus_hp.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("tower_buffs_bonus_hp_regen", "plugin_system/plugins/tower_buffs/tower_buffs_bonus_hp_regen.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("tower_buffs_bonus_damage", "plugin_system/plugins/tower_buffs/tower_buffs_bonus_damage.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("tower_buffs_bonus_armor", "plugin_system/plugins/tower_buffs/tower_buffs_bonus_armor.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("tower_buffs_bonus_magic_resistance", "plugin_system/plugins/tower_buffs/tower_buffs_bonus_magic_resistance.lua", LUA_MODIFIER_MOTION_NONE)
    for _, building in pairs(Toolbox:AllTowers()) do
        if TowerBuffsPlugin.settings.backdoor_immunity then
            building:AddNewModifier(building, nil, "tower_buffs_no_backdoor", {})
        end
        if TowerBuffsPlugin.settings.bonus_hp > 0 then
            local hMod = building:AddNewModifier(building, nil, "tower_buffs_bonus_hp", {})
            if hMod ~= nil then hMod:SetStackCount(TowerBuffsPlugin.settings.bonus_hp) end
        end
        if TowerBuffsPlugin.settings.bonus_hp_regen > 0 then
            local hMod = building:AddNewModifier(building, nil, "tower_buffs_bonus_hp_regen", {})
            if hMod ~= nil then hMod:SetStackCount(TowerBuffsPlugin.settings.bonus_hp_regen) end
        end
        if TowerBuffsPlugin.settings.bonus_damage > 0 then
            local hMod = building:AddNewModifier(building, nil, "tower_buffs_bonus_damage", {})
            if hMod ~= nil then hMod:SetStackCount(TowerBuffsPlugin.settings.bonus_damage) end
        end
        if TowerBuffsPlugin.settings.bonus_armor > 0 then
            local hMod = building:AddNewModifier(building, nil, "tower_buffs_bonus_armor", {})
            if hMod ~= nil then hMod:SetStackCount(TowerBuffsPlugin.settings.bonus_armor) end
        end

        if TowerBuffsPlugin.settings.bonus_magic_resistance > 0 then
            local hMod = building:AddNewModifier(building, nil, "tower_buffs_bonus_magic_resistance", {})
            if hMod ~= nil then hMod:SetStackCount(TowerBuffsPlugin.settings.bonus_magic_resistance) end
        end
        if TowerBuffsPlugin.settings.unyielding_shield then
            local hAbility = building:AddAbility("miniboss_unyielding_shield")
            if hAbility ~= nil then
                hAbility:SetLevel(1)
            end
        end
    end
end