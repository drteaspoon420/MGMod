TimeLimitPlugin = class({})
_G.TimeLimitPlugin = TimeLimitPlugin
TimeLimitPlugin.settings = {
}

function TimeLimitPlugin:Init()
    --print("[TimeLimitPlugin] found")
end

function TimeLimitPlugin:ApplySettings()
    local iTime = tonumber(PluginSystem:GetSetting("time_limit_plugin","time_limit") or 25)
    Timers:CreateTimer(iTime*60,function()
        TimeLimitPlugin:GameEnd()
    end)
end

function TimeLimitPlugin:GameEnd()
    local iBest = 0
    local tWinningTeams = {}
    for k,v in pairs(PluginSystem.teams) do
        local iKills = PlayerResource:GetTeamKills(v)
        if iKills == iBest then
            table.insert(tWinningTeams,v)
        elseif iKills > iBest then
            iBest = iKills
            tWinningTeams = {}
            table.insert(tWinningTeams,v)
        end
    end

    if #tWinningTeams > 1 then
        Timers:CreateTimer(60,function()
            TimeLimitPlugin:GameEnd()
        end)
    else
        GameRules:SetGameWinner(tWinningTeams[1])
    end
end