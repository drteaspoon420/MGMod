KillLimitPlugin = class({})
_G.KillLimitPlugin = KillLimitPlugin
KillLimitPlugin.settings = {
}

function KillLimitPlugin:Init()
    print("[KillLimitPlugin] found")
end

function KillLimitPlugin:ApplySettings()
    local iKills = tonumber(PluginSystem:GetSetting("kill_limit_plugin","kill_limit") or 50)
    KillLimitPlugin.settings.kills = iKills
    ListenToGameEvent("entity_killed", function(event)
        KillLimitPlugin:GameEnd()
    end,nil)
end

function KillLimitPlugin:GameEnd()
    local iKills = KillLimitPlugin.settings.kills
    local iRadiant = PlayerResource:GetTeamKills(DOTA_TEAM_GOODGUYS)
    local iDire = PlayerResource:GetTeamKills(DOTA_TEAM_BADGUYS)
    if iRadiant >= iKills then
        GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
        KillLimitPlugin.settings.kills = 999999
        return
    end
    if iDire >= iKills then
        GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
        KillLimitPlugin.settings.kills = 999999
        return
    end
end