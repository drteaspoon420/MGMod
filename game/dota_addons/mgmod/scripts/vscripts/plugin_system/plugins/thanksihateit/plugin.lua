ThanksIHateItPlugin = class({})
_G.ThanksIHateItPlugin = ThanksIHateItPlugin

function ThanksIHateItPlugin:Init()
    print("[ThanksIHateItPlugin] found")
end

function ThanksIHateItPlugin:ApplySettings()
    ThanksIHateItPlugin.settings = PluginSystem:GetAllSetting("thanksihateit")

    if ThanksIHateItPlugin.settings.death_item_loss then
        LinkLuaModifier( "modifier_death_item_loss", "plugin_system/plugins/thanksihateit/modifiers/modifier_death_item_loss", LUA_MODIFIER_MOTION_NONE )
    end
    if ThanksIHateItPlugin.settings.clumsy_bonk then
        LinkLuaModifier( "modifier_clumsy_bonk", "plugin_system/plugins/thanksihateit/modifiers/modifier_clumsy_bonk", LUA_MODIFIER_MOTION_NONE )
    end
    if ThanksIHateItPlugin.settings.dumb_bonk then
        LinkLuaModifier( "modifier_dumb_bonk", "plugin_system/plugins/thanksihateit/modifiers/modifier_dumb_bonk", LUA_MODIFIER_MOTION_NONE )
    end
    if ThanksIHateItPlugin.settings.underworld_strength then
        LinkLuaModifier( "modifier_underworld_strength", "plugin_system/plugins/thanksihateit/modifiers/modifier_underworld_strength", LUA_MODIFIER_MOTION_NONE )
    end
    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        ThanksIHateItPlugin:npc_spawned(event)
    end,nil)

--[[     if ThanksIHateItPlugin.settings.tree_nomer then
        LinkLuaModifier( "modifier_tree_nomer", "plugin_system/plugins/thanksihateit/modifiers/modifier_tree_nomer", LUA_MODIFIER_MOTION_NONE )
        ListenToGameEvent("nommed_tree", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            ThanksIHateItPlugin:nommed_tree(event)
        end,nil)
    end ]]
--[[     if ThanksIHateItPlugin.settings.shop_closed_at_night then
        Tutorial:SetShopOpen(false)
         Timers:CreateTimer(20,function()
            ThanksIHateItPlugin:ShopsClosed()
            return 1
        end)
    end ]]
end


function ThanksIHateItPlugin:nommed_tree(event)
    local hPlayer = PlayerResource:GetPlayer(event.PlayerID)
    if hPlayer == nil or not hPlayer:IsPlayer() then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil or not hHero:IsDOTANPC() then return end
    local hModifier = hHero:AddNewModifier(hHero,nil,"modifier_tree_nomer",{})
end


function ThanksIHateItPlugin:npc_spawned(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end

    if hUnit:IsRealHero() then
        if ThanksIHateItPlugin.settings.death_item_loss then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_death_item_loss",{})
        end
        if ThanksIHateItPlugin.settings.clumsy_bonk then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_clumsy_bonk",{})
        end
        if ThanksIHateItPlugin.settings.dumb_bonk then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_dumb_bonk",{})
        end
        if ThanksIHateItPlugin.settings.underworld_strength then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_underworld_strength",{})
        end
    end
    
end
function ThanksIHateItPlugin:ShopsClosed()
end

