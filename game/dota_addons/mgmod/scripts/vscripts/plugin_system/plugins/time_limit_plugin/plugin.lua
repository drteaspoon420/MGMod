TimeLimitPlugin = class({})
_G.TimeLimitPlugin = TimeLimitPlugin
TimeLimitPlugin.settings = {
}

function TimeLimitPlugin:Init()
    print("[TimeLimitPlugin] found")
end

function TimeLimitPlugin:ApplySettings()
    local iTime = tonumber(PluginSystem:GetSetting("time_limit_plugin","time_limit") or 25)
    Timers:CreateTimer(iTime*60,function()
        TimeLimitPlugin:GameEnd()
    end)
end

function TimeLimitPlugin:GameEnd()
    local iRadiant = PlayerResource:GetTeamKills(DOTA_TEAM_GOODGUYS)
    local iDire = PlayerResource:GetTeamKills(DOTA_TEAM_BADGUYS)
    if iDire == iRadiant then
        Timers:CreateTimer(60,function()
            TimeLimitPlugin:GameEnd()
        end)
    else
        if iRadiant > iDire then
            GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
        else
            GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
        end
    end
end