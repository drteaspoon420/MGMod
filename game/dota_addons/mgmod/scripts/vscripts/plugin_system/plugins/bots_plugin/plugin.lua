BotsPlugin = class({})
_G.BotsPlugin = BotsPlugin
BotsPlugin.settings = {
}

function BotsPlugin:Init()
    print("[BotsPlugin] found")
end

function BotsPlugin:ApplySettings()
    BotsPlugin.settings = PluginSystem:GetAllSetting("bots_plugin")
    if BotsPlugin.settings.pre_random then
        BotsPlugin:ApplySettings3()
    end
end

function BotsPlugin:ApplySettings2()
    if not BotsPlugin.settings.pre_random then
        BotsPlugin:ApplySettings3()
    end
end

function BotsPlugin:ApplySettings3()
    local num = 0
    local used_hero_name = "npc_dota_hero_luna"

--[[     for i=0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayer(i) then
            local player = PlayerResource:GetPlayer(i)
            local steamid = PlayerResource:GetSteamID(i)
            if steamid ~= nil and steamid == "0" then
                if PlayerResource:HasSelectedHero(i) == false then
                    player:MakeRandomHeroSelection()
                end
                used_hero_name = PlayerResource:GetSelectedHeroName(i)
                num = num + 1
        end
    end ]]
    local total_slots = GameRules:GetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS) + GameRules:GetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS)
    local name_index = 0
    for i=1, GameRules:GetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS) - PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) do
        Tutorial:AddBot(used_hero_name, "", "", true)
        --local hero = GameRules:AddBotPlayerWithEntityScript("npc_dota_hero_legion_commander", "bot_" .. name_index, DOTA_TEAM_GOODGUYS, "bots/generic_ai.lua", true)
    end
    for i=1, GameRules:GetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS) - PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS) do
        --local hero = GameRules:AddBotPlayerWithEntityScript("npc_dota_hero_legion_commander", "bot_" .. name_index, DOTA_TEAM_BADGUYS, "bots/generic_ai.lua", true)
        Tutorial:AddBot(used_hero_name, "", "", false)
    end
    GameRules:GetGameModeEntity():SetBotThinkingEnabled(true)
    SendToServerConsole("dota_bot_set_difficulty 4")
    SendToConsole("dota_bot_set_difficulty 4")
    SendToServerConsole("dota_bot_populate")
    SendToServerConsole("dota_bot_mode 1")
    SendToServerConsole("dota_bot_takeover_disconnected 1")
    SendToServerConsole("dota_bot_match_difficulty 4")
    SendToServerConsole("dota_bot_use_machine_learned_weights 1")
end