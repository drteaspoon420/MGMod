BasicCommandsPlugin = class({})
_G.BasicCommandsPlugin = BasicCommandsPlugin
BasicCommandsPlugin.settings = {}
BasicCommandsPlugin.unit_cache = {}

function BasicCommandsPlugin:Init()
    --print("[BasicCommandsPlugin] found")
end

function BasicCommandsPlugin:ApplySettings()
    BasicCommandsPlugin.settings = PluginSystem:GetAllSetting("basic_commands")
    BasicCommandsPlugin.gg_called = {}
    BasicCommandsPlugin.gg_called[DOTA_TEAM_GOODGUYS] = {}
    BasicCommandsPlugin.gg_called[DOTA_TEAM_BADGUYS] = {}
end
    

function BasicCommandsPlugin:CallGG(tArgs,bTeam,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    local iTeam = PlayerResource:GetCustomTeamAssignment(iPlayer)

    if PlayerResource:GetConnectionState(iPlayer) == DOTA_CONNECTION_STATE_CONNECTED then
        BasicCommandsPlugin.gg_called[iTeam][iPlayer] = true
    end

    local iCount = 0
    local iYes = 0
	for p=0,DOTA_MAX_PLAYERS do
		if (PlayerResource:IsValidPlayer(p)) then
            local iConnectionState = PlayerResource:GetConnectionState(p)
            local oTeam = PlayerResource:GetCustomTeamAssignment(p)
            if iTeam == oTeam then 
                if BasicCommandsPlugin.gg_called[iTeam] ~= nil then
                    if iConnectionState == DOTA_CONNECTION_STATE_CONNECTED then
                        iCount = iCount + 1
                        if BasicCommandsPlugin.gg_called[iTeam][p] ~= nil and BasicCommandsPlugin.gg_called[iTeam][p] == true then
                            iYes = iYes + 1
                        end
                    end
                end
            end
		end
	end
    
    if DOTA_TEAM_GOODGUYS == iTeam then
        GameRules:SendCustomMessageToTeam("Radiant GG votes: " .. iYes .. "/" .. iCount, iTeam, 0, 0)
    else
        GameRules:SendCustomMessageToTeam("Dire GG votes: " .. iYes .. "/" .. iCount, iTeam, 0, 0)
    end
    if iCount == iYes then
        local iOtherTeam = ((iTeam+1) % 2)+2
        GameRules:SetGameWinner(iOtherTeam)
    end
end

