SudoPlugin = class({})
_G.SudoPlugin = SudoPlugin
SudoPlugin.settings = {}

function SudoPlugin:Init()
    --print("[SudoPlugin] found")
end

function SudoPlugin:PreGameStuff()
    SudoPlugin.settings = PluginSystem:GetAllSetting("sudo")
    DeepPrintTable(SudoPlugin.settings)
    local contxt = {}
    ListenToGameEvent("player_chat", function(keys)
        local sText = keys.text
        local bTeam = keys.teamonly
        if string.sub(sText, 1, 5) == "sudo " then
            local iPlayer = keys.userid
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if SudoPlugin:Allowed(hPlayer,bTeam) then
                local fn = load(string.sub(sText,6))
                fn()
            end
        end
    end,nil)
end

function SudoPlugin:Allowed(hPlayer,bTeam)
    if SudoPlugin.settings.team_only_allowed and not bTeam then
        return false
    end
    if SudoPlugin.settings.host_allowed then
        if GameRules:PlayerHasCustomGameHostPrivileges(hPlayer) then
            return true
        else
            return false
        end
    else
        if SudoPlugin.settings.core_apply_team ~= 0 then
            if hPlayer:GetTeam() == SudoPlugin.settings.core_apply_team then
                return true
            else
                return false
            end
        else
            return true
        end
    end
    return false
end
