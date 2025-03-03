LevelTimingsPlugin = class({})
_G.LevelTimingsPlugin = LevelTimingsPlugin
LevelTimingsPlugin.settings = {
}

function LevelTimingsPlugin:Init()
    --print("[LevelTimingsPlugin] found")
end

function LevelTimingsPlugin:ApplySettings()
    LevelTimingsPlugin.settings = PluginSystem:GetAllSetting("level_timings")

    ListenToGameEvent('dota_player_gained_level', function(keys)
        if not keys.player then return end
    
        local player = EntIndexToHScript(keys.player)
        local hero = player:GetAssignedHero()
        if hero == nil then
            return
        end
        local level = keys.level
        if (level == LevelTimingsPlugin.settings.level) then
            hero:SetAbilityPoints(hero:GetAbilityPoints()+LevelTimingsPlugin.settings.ability_points)
        end
    end, nil)
end