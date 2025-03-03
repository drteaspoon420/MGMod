KillLimitPlugin = class({})
_G.KillLimitPlugin = KillLimitPlugin
KillLimitPlugin.settings = {
}

function KillLimitPlugin:Init()
    --print("[KillLimitPlugin] found")
end

function KillLimitPlugin:ApplySettings()
    local iKills = tonumber(PluginSystem:GetSetting("kill_limit_plugin","kill_limit") or 50)
    KillLimitPlugin.settings.kills = iKills
    ListenToGameEvent("entity_killed", function(event)
        KillLimitPlugin:GameEnd()
    end,nil)
end

function KillLimitPlugin:GameEnd()
    local iLimit = KillLimitPlugin.settings.kills
    for k,v in pairs(PluginSystem.teams) do
        local iKills = PlayerResource:GetTeamKills(v)
        if iKills >= iLimit then
            GameRules:SetGameWinner(v)
            KillLimitPlugin.settings.kills = 999999
            return
        end
    end
end