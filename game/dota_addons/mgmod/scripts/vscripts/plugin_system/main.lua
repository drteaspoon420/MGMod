

PluginSystem = class({})
_G.PluginSystem = PluginSystem
PluginSystem.StateRegistry = {}
PluginSystem.CommandRegistery = {}
PluginSystem.PluginsFile = {}
PluginSystem.LobbySettings = {}
PluginSystem.LobbySettingsSaves = {}
PluginSystem.InternalEvents = {}
PluginSystem.unit_cache = {}
PluginSystem.current_save_slot = 0
PluginSystem.presets = {}
PluginSystem.forced = {}
PluginSystem.locked = 0
PluginSystem.dvd = {}


PluginSystem.core_abilities = {}
PluginSystem.core_items = {}
PluginSystem.core_units = {}

local JSON = require("utils/dkjson")
GAMEMODE_SAVE_ID = "mgmod"

tStates = {}
tStates["DOTA_GAMERULES_STATE_INIT"] = DOTA_GAMERULES_STATE_INIT
tStates["DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD"] = DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD
tStates["DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP"] = DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP
tStates["DOTA_GAMERULES_STATE_HERO_SELECTION"] = DOTA_GAMERULES_STATE_HERO_SELECTION
tStates["DOTA_GAMERULES_STATE_STRATEGY_TIME"] = DOTA_GAMERULES_STATE_STRATEGY_TIME
tStates["DOTA_GAMERULES_STATE_TEAM_SHOWCASE"] = DOTA_GAMERULES_STATE_TEAM_SHOWCASE
tStates["DOTA_GAMERULES_STATE_WAIT_FOR_MAP_TO_LOAD"] = DOTA_GAMERULES_STATE_WAIT_FOR_MAP_TO_LOAD
tStates["DOTA_GAMERULES_STATE_PRE_GAME"] = DOTA_GAMERULES_STATE_PRE_GAME
tStates["DOTA_GAMERULES_STATE_SCENARIO_SETUP"] = DOTA_GAMERULES_STATE_SCENARIO_SETUP
tStates["DOTA_GAMERULES_STATE_GAME_IN_PROGRESS"] = DOTA_GAMERULES_STATE_GAME_IN_PROGRESS
tStates["DOTA_GAMERULES_STATE_POST_GAME"] = DOTA_GAMERULES_STATE_POST_GAME
tStates["DOTA_GAMERULES_STATE_DISCONNECT"] = DOTA_GAMERULES_STATE_DISCONNECT

tFilters = {}
    
tFilters["AbilityTuningValueFilter"] = "AbilityTuningValueFilters"
tFilters["BountyRunePickupFilter"] = "BountyRunePickupFilters"
tFilters["DamageFilter"] = "DamageFilters"
tFilters["ExecuteOrderFilter"] = "ExecuteOrderFilters"
tFilters["HealingFilter"] = "HealingFilters"
tFilters["ItemAddedToInventoryFilter"] = "ItemAddedToInventoryFilters"
tFilters["ModifierGainedFilter"] = "ModifierGainedFilters"
tFilters["ModifyExperienceFilter"] = "ModifyExperienceFilters"
tFilters["ModifyGoldFilter"] = "ModifyGoldFilters"
tFilters["RuneSpawnFilter"] = "RuneSpawnFilters"
tFilters["TrackingProjectileFilter"] = "TrackingProjectileFilters"

--Loading all plugins
function PluginSystem:Init()
    --print("[PluginSystem] init")

    --core data
    PluginSystem:load_abilities()
    PluginSystem:load_items()
    PluginSystem:load_units()
    --PluginSystem:load_modifiers()
    PluginSystem:load_credits()

    --dvd
	PluginSystem.dvd = LoadKeyValues('scripts/vscripts/plugin_system/dvd.txt')

    CustomGameEventManager:RegisterListener("settings_save_slot",function(i,tEvent) PluginSystem:settings_save_slot(tEvent) end)
    CustomGameEventManager:RegisterListener("setting_change",PluginSystem.setting_change)
    CustomGameEventManager:RegisterListener("settings_vote_unlock",function(i,tEvent) PluginSystem:settings_vote_unlock(tEvent) end)
    CustomGameEventManager:RegisterListener("setting_activate_mutator",PluginSystem.setting_activate_mutator)
    CustomGameEventManager:RegisterListener("setting_team_rescale",PluginSystem.setting_team_rescale)
    
    CustomGameEventManager:RegisterListener("core_ability_indexer",PluginSystem.core_ability_indexer)
    CustomGameEventManager:RegisterListener("plugin_system_show_abilities",PluginSystem.plugin_system_show_abilities)
    CustomGameEventManager:RegisterListener("core_item_indexer",PluginSystem.core_item_indexer)
    CustomGameEventManager:RegisterListener("plugin_system_show_items",PluginSystem.plugin_system_show_items)
    CustomGameEventManager:RegisterListener("core_unit_indexer",PluginSystem.core_unit_indexer)
    CustomGameEventManager:RegisterListener("plugin_system_show_units",PluginSystem.plugin_system_show_units)

    
    
    GameRules:SetSafeToLeave(true)
    --GameRules:SetCustomGameAccountRecordSaveFunction( Dynamic_Wrap( PluginSystem, "SaveHostSettings_PartA" ), self )
    GameRules:SetCustomGameEndDelay(15)
    GameRules:SetCustomGameSetupAutoLaunchDelay(60)
    --GameRules:SetCustomGameSetupAutoLaunchDelay(420)
    GameRules:SetCustomGameSetupRemainingTime(-1)
    GameRules:SetCustomGameSetupTimeout(-1)
    GameRules:SetCustomGameTeamMaxPlayers(1,10)

    --GameRules:SetStrategyTime(DotaSettingsPlugin.settings.strategy_time)
    --GameRules:SetShowcaseTime(DotaSettingsPlugin.settings.showcase_time)
    --GameRules:SetPreGameTime(DotaSettingsPlugin.settings.pregame_time)

	local forced_file = LoadKeyValues('scripts/vscripts/plugin_system/map_presets/' .. GetMapName() .. '.txt')
    if not (forced_file == nil or not next(forced_file)) then
        PluginSystem.forced = forced_file
        --print("Preset file found, " .. GetMapName())
        if PluginSystem.forced.teams ~= nil then
            for k,v in pairs(PluginSystem.forced.teams) do
                GameRules:SetCustomGameTeamMaxPlayers(tonumber(k),tonumber(v))
            end
        end
    end
    if PluginSystem.forced.lock_level ~= nil then PluginSystem.locked = PluginSystem.forced.lock_level end
	local presets_file = LoadKeyValues('scripts/vscripts/plugin_system/mutators/main.txt')
    if not (presets_file == nil or not next(presets_file)) then
        PluginSystem.presets = presets_file
        for k,v in pairs(PluginSystem.presets) do
            CustomNetTables:SetTableValue("mutator_presets",k,v)
        end
    end

    if PluginSystem.forced ~= nil then
        if not (PluginSystem.forced.lock_level == nil or PluginSystem.forced.lock_level == -1) then
--[[             if PluginSystem.forced.preset ~= nil then
                PluginSystem:ApplyPreset(PluginSystem.forced.preset)
            end ]]
            PluginSystem.forced.votes = {}
            --print("[PluginSystem] Forced mode table set")
            CustomNetTables:SetTableValue("forced_mode","initial",PluginSystem.forced)
        end
    end

	local file = LoadKeyValues('scripts/vscripts/plugin_system/plugins.txt')
    if not (file == nil or not next(file)) then
        PluginSystem.PluginsFile = file
    end

    for sPlugin,tSettings in pairs(PluginSystem.PluginsFile) do
        if tSettings.Path then --if you really want custom path
            require(tSettings.Path .. "/plugin")
        else
            require("plugin_system/plugins/" ..sPlugin .. "/plugin")
        end
        --print("file loaded " .. sPlugin)
        local main_class = tSettings.MainClass
        local state_regs = tSettings.StateRegistrations or {}
        local cmd_regs = tSettings.CmdRegistrations or {}
        local filter_regs = tSettings.FilterRegistrations or {}
        if tSettings.IsCheatMode ~= nil and tSettings.IsCheatMode == 1 then
            if not GameRules:IsCheatMode() then
                goto continue_1
                --did you know, this is the only way to 'skip' iteration of loop to the end of it.
                --how dumb is this?! Like, in what scope is the 'continue' and 'goto'?
                --Thats why for safety reasons I have _1 and _2. Who ever came up with this really must hate any code analyzers.
            end
        end
        PluginSystem.LobbySettings[sPlugin] = {}
        local settings
        if tSettings.Path then
            settings = LoadKeyValues("scripts/vscripts/".. tSettings.Path .."/settings.txt")
        else
            settings = LoadKeyValues("scripts/vscripts/plugin_system/plugins/".. sPlugin .."/settings.txt")
        end
        if not (settings == nil or not next(settings)) then
            if PluginSystem.forced ~= nil
            and PluginSystem.forced.lock_level ~= nil and PluginSystem.forced.lock_level > -1
            and PluginSystem.forced.settings ~= nil
            then
                PluginSystem:LoadDefaultSettings(sPlugin,settings,PluginSystem.forced.settings)
            else
                PluginSystem:LoadDefaultSettings(sPlugin,settings)
            end
        else
            PluginSystem.LobbySettings[sPlugin].enabled = {}
            PluginSystem.LobbySettings[sPlugin].enabled.DEFAULT = 0
            PluginSystem.LobbySettings[sPlugin].enabled.TYPE = "boolean"
            PluginSystem.LobbySettings[sPlugin].enabled.VALUE = 0
        end
        PluginSystem.LobbySettings["core_teams"] = {}
        for state_function,state_string in pairs(state_regs) do
            PluginSystem:RegisterState(tStates[state_string],_G[main_class],state_function,sPlugin)
        end
        for cmd_regs_string,cmd_regs_function in pairs(cmd_regs) do
            PluginSystem:RegisterCmd(cmd_regs_string,_G[main_class],cmd_regs_function,sPlugin)
        end
        for filter_regs_string,filter_regs_function in pairs(filter_regs) do
            PluginSystem:RegisterFilter(filter_regs_string,_G[main_class],filter_regs_function,sPlugin)
        end
        ::continue_1::
    end
    for sPlugin,tSettings in pairs(PluginSystem.PluginsFile) do
        if tSettings.IsCheatMode ~= nil and tSettings.IsCheatMode == 1 then
            if not GameRules:IsCheatMode() then
                goto continue_2
            end
        end
        local init_function = tSettings.InitFunction or nil
        if init_function ~= nil then
            local main_class = tSettings.MainClass
            _G[main_class][init_function]()
        end
        ::continue_2::
    end
        
    for i=1,#PluginSystem.teams do
        local iTeam = PluginSystem.teams[i]
        PluginSystem.LobbySettings["core_teams"][tostring(iTeam)] = {
            TYPE = "number",
            DEFAULT = GameRules:GetCustomGameTeamMaxPlayers(tonumber(iTeam)),
            VALUE = GameRules:GetCustomGameTeamMaxPlayers(tonumber(iTeam))
        }
    end

    PluginSystem:SetFilters()

end

function PluginSystem:settings_vote_unlock(tEvent)
    local iPlayer = tEvent.PlayerID
    --PluginSystem.forced.votes[#PluginSystem.forced.votes + 1] = true
    PluginSystem.forced.votes["v" .. iPlayer] = true
    local iCount = 0
    for iPlayer = 0,DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(iPlayer) then
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer ~= nil then
                iCount = iCount + 1
            end
        end
    end
    local iVotes = 0
    for k,v in pairs(PluginSystem.forced.votes) do
        iVotes = iVotes + 1
    end
    if iCount > 0 then
        --print(iCount,iVotes,PluginSystem.forced.vote_treshold)
        if (PluginSystem.forced.vote_treshold * 0.01 < iVotes/iCount) then
            PluginSystem.forced.lock_level = 0
        end
        CustomNetTables:SetTableValue("forced_mode","initial",PluginSystem.forced)
    end
end
--settings
function PluginSystem:ApplyPreset(sPreset)
    --print("loading preset",sPreset)
    if PluginSystem.presets == nil or PluginSystem.presets[sPreset] == nil then return end
    local tSettings = PluginSystem.presets[sPreset].settings
    if tSettings and type(tSettings) == "table" then
        if not next(tSettings) then return end
        for sPlugin,tSetting in pairs(PluginSystem.LobbySettings) do
            if type(tSetting) == "table" then
                if tSettings[sPlugin] == nil then
                    for key,val in pairs(tSetting) do
                        if type(val) == "table" then
                            PluginSystem:SetSetting(sPlugin,key,val.DEFAULT,true)
                        end
                    end
                else
                    for key,val in pairs(tSetting) do
                        if type(val) == "table" then
                            if tSettings[sPlugin][key] ~= nil and val.DEFAULT ~= tSettings[sPlugin][key] then
                                PluginSystem:SetSetting(sPlugin,key,tSettings[sPlugin][key],true)
                            else
                                PluginSystem:SetSetting(sPlugin,key,val.DEFAULT,true)
                            end
                        end
                    end
                end
            end
            CustomNetTables:SetTableValue("plugin_settings",sPlugin,PluginSystem.LobbySettings[sPlugin])
        end
    end
end

function PluginSystem:ApplyPresetAdditive(sPreset)
    --print("loading preset",sPreset)
    if PluginSystem.presets == nil or PluginSystem.presets[sPreset] == nil then return end
    local tSettings = PluginSystem.presets[sPreset].settings
    if tSettings and type(tSettings) == "table" then
        if not next(tSettings) then return end
        for sPlugin,tSetting in pairs(PluginSystem.LobbySettings) do
            if type(tSetting) == "table" then
                if tSettings[sPlugin] ~= nil then
                    for key,val in pairs(tSetting) do
                        if type(val) == "table" then
                            if tSettings[sPlugin][key] ~= nil and val.DEFAULT ~= tSettings[sPlugin][key] then
                                PluginSystem:SetSetting(sPlugin,key,tSettings[sPlugin][key])
                            end
                        end
                    end
                end
            end
            CustomNetTables:SetTableValue("plugin_settings",sPlugin,PluginSystem.LobbySettings[sPlugin])
        end
    end
end



function PluginSystem:setting_change(tEvent)
    local iPlayer = tEvent.PlayerID
    local sPlugin = tEvent.plugin
    local sSetting = tEvent.setting
    local sValue = tEvent.value
    if not PluginSystem:Sanitize(sPlugin,sSetting,sValue) then return end
    CustomNetTables:SetTableValue("plugin_settings",sPlugin,PluginSystem.LobbySettings[sPlugin])
end

function PluginSystem:Reflect(tEvent)
    local iOrigin = tEvent.PlayerID
    tEvent.PlayerID = nil
    for iPlayer = 0,DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(iPlayer) then
            if iOrigin ~= iPlayer then
                local hPlayer = PlayerResource:GetPlayer(iPlayer)
                if hPlayer ~= nil then
                    CustomGameEventManager:Send_ServerToPlayer(hPlayer,"setting_change",tEvent)
                end
            end
        end
    end
end

function PluginSystem:GetSetting(sPlugin,sSetting)
    if PluginSystem.LobbySettings[sPlugin] == nil then return nil end
    if PluginSystem.LobbySettings[sPlugin][sSetting] == nil then return nil end
    if PluginSystem.LobbySettings[sPlugin][sSetting].VALUE == nil then return nil end
    return PluginSystem.LobbySettings[sPlugin][sSetting].VALUE
end

function PluginSystem:GetAllSetting(sPlugin)
    if PluginSystem.LobbySettings[sPlugin] == nil then return {} end
    local t = {}
    for k,v in pairs(PluginSystem.LobbySettings[sPlugin]) do
        if type(v) == "table" then
            if v.VALUE ~= nil then
                if v.TYPE == "boolean" then
                    t[k] = v.VALUE == 1
                end
                if v.TYPE == "number" then
                    t[k] = tonumber(v.VALUE)
                end
                if v.TYPE == "text" then
                    t[k] = v.VALUE
                end
                if v.TYPE == "core_picker" then
                    t[k] = v.VALUE
                end
                if v.TYPE == "dropdown" then
                    if tonumber(v.VALUE) then
                        t[k] = tonumber(v.VALUE)
                    else
                        t[k] = v.VALUE
                    end
                end
            end
        end
    end
    return t
end

function PluginSystem:Sanitize(sPlugin,sSetting,sValue,bOverride)
    bOverride = bOverride or false
    if PluginSystem.LobbySettings[sPlugin] == nil then return false end
    if PluginSystem.LobbySettings[sPlugin][sSetting] == nil then return false end
    if PluginSystem.LobbySettings[sPlugin][sSetting].VALUE == nil then return false end
    if not bOverride then
        if PluginSystem.forced ~= nil and PluginSystem.forced.lock_level > 0 then
            if PluginSystem.forced.unlocked ~= nil then
                if PluginSystem.forced.unlocked[sPlugin] == nil then return false end
                if type(PluginSystem.forced.unlocked[sPlugin]) == "table" then
                    if PluginSystem.forced.unlocked[sPlugin][sSetting] == nil then return false end
                elseif type(PluginSystem.forced.unlocked[sPlugin]) ~= "number" then
                    return false
                end 
            end
        end
    end

    if PluginSystem.LobbySettings[sPlugin][sSetting].TYPE == "number" then
        if tonumber(sValue) == nil then
            return false
        end
        PluginSystem.LobbySettings[sPlugin][sSetting].VALUE = sValue
    elseif PluginSystem.LobbySettings[sPlugin][sSetting].TYPE == "text" then
        PluginSystem.LobbySettings[sPlugin][sSetting].VALUE = sValue
    elseif PluginSystem.LobbySettings[sPlugin][sSetting].TYPE == "core_picker" then
        PluginSystem.LobbySettings[sPlugin][sSetting].VALUE = sValue
    elseif PluginSystem.LobbySettings[sPlugin][sSetting].TYPE == "boolean" then
        if sValue == "1" or sValue == "true" or sValue == "TRUE" or sValue == "True" or sValue == 1 or sValue == true then
            PluginSystem.LobbySettings[sPlugin][sSetting].VALUE = 1
        elseif sValue == "0" or sValue == "false" or sValue == "FALSE" or sValue == "False" or sValue == 0 or sValue == false then
            PluginSystem.LobbySettings[sPlugin][sSetting].VALUE = 0
        else
            return false
        end
    elseif PluginSystem.LobbySettings[sPlugin][sSetting].TYPE == "dropdown" then
        PluginSystem.LobbySettings[sPlugin][sSetting].VALUE = sValue
    else
        if tonumber(sValue) == nil then
            PluginSystem.LobbySettings[sPlugin][sSetting].VALUE = sValue
        else
            PluginSystem.LobbySettings[sPlugin][sSetting].VALUE = tonumber(sValue)
        end
    end
    return true
end

function PluginSystem:SetSetting(sPlugin,sSetting,sValue,bOverride)
    bOverride = bOverride or false
    if not PluginSystem:Sanitize(sPlugin,sSetting,sValue,bOverride) then return end
    if sPlugin == "core_teams" then
        local tEvent = {
            PlayerID = Toolbox:GetHostId(),
            team = tonumber(sSetting),
            number = tonumber(sValue),
        }
        PluginSystem:setting_team_rescale(tEvent)
    else
        local tEvent = {
            plugin = sPlugin,
            setting = sSetting,
            value = tostring(sValue),
        }
        for iPlayer = 0,DOTA_MAX_PLAYERS do
            if PlayerResource:IsValidPlayer(iPlayer) then
                local hPlayer = PlayerResource:GetPlayer(iPlayer)
                if hPlayer ~= nil then
                    CustomGameEventManager:Send_ServerToPlayer(hPlayer,"setting_change",tEvent)
                end
            end
        end
    end
end

function PluginSystem:LoadDefaultSettings(sPlugin,tSettings,tPreset)
    if tSettings.enabled == nil then
        tSettings.enabled = {}
        tSettings.enabled.DEFAULT = 0
        tSettings.enabled.TYPE = "boolean"
    end
    for k,_ in pairs(tSettings) do
        if type(tSettings[k]) == "table" then
            if tPreset ~= nil and tPreset[sPlugin] ~= nil and tPreset[sPlugin][k] ~= nil then
                tSettings[k].DEFAULT = tPreset[sPlugin][k]
            end
            tSettings[k].VALUE = tSettings[k].DEFAULT
        end
    end
    PluginSystem.LobbySettings[sPlugin] = tSettings
    CustomNetTables:SetTableValue("plugin_settings",sPlugin,tSettings)
end

--Plugin Registration and Calling
---
function PluginSystem:ProcRegisteredGameStates(iState)
    
    if DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP == iState then
        PluginSystem:LoadHostSettings()
    end
    if DOTA_GAMERULES_STATE_HERO_SELECTION  == iState then
        PluginSystem:SaveHostSettings()
        if PluginSystem.mutator_picks ~= nil then
            for k,v in pairs(PluginSystem.mutator_picks) do
                PluginSystem:ApplyPresetAdditive(v)
            end
        end
    end
    if PluginSystem.StateRegistry[iState] ~= nil then
        for k,v in pairs(PluginSystem.StateRegistry[iState]) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                --print(v.plugin_name,v.method)
                v.plugin[v.method](v.plugin)
            end
        end
    end
--[[     if DOTA_GAMERULES_STATE_GAME_IN_PROGRESS == iState then
        for iPlayer = 0,DOTA_MAX_PLAYERS do
            if PlayerResource:IsValidPlayer(iPlayer) then
                local steamid = tostring(PlayerResource:GetSteamID(iPlayer))
                if steamid ~= "0" then
                    if PluginSystem.dvd[steamid] ~= nil then
                        PluginSystem:DvdCheck()
                        break
                    end
                end
            end
        end
    end ]]
end

function PluginSystem:RegisterState(iState,hPlugin,hMethod,sPlugin)
    if PluginSystem.StateRegistry[iState] == nil then PluginSystem.StateRegistry[iState] = {} end
    table.insert(PluginSystem.StateRegistry[iState],{plugin = hPlugin, method = hMethod, plugin_name = sPlugin})
end


function PluginSystem:InternalEvent_Register(sEvent,fCallback)
    if PluginSystem.InternalEvents[sEvent] == nil then PluginSystem.InternalEvents[sEvent] = {} end
    table.insert(PluginSystem.InternalEvents[sEvent],fCallback)
end

function PluginSystem:InternalEvent_Call(sEvent,tEvent)
    if PluginSystem.InternalEvents[sEvent] == nil then return end
    --print(tEvent)
    for k,v in pairs(PluginSystem.InternalEvents[sEvent]) do
        v(tEvent)
    end
end

function PluginSystem:RegisterCmd(sMain,hPlugin,hMethod,sPlugin)
    --print("registering",sMain,"for",sPlugin)
    if PluginSystem.CommandRegistery[sMain] == nil then PluginSystem.CommandRegistery[sMain] = {} end
    table.insert(PluginSystem.CommandRegistery[sMain],{plugin = hPlugin, method = hMethod, plugin_name = sPlugin})
end

function PluginSystem:ProcRegisteredCommands(bTeam,iPlayer,sText)
    local tCmdParts = Toolbox:split(sText," ")
    local sMain = tCmdParts[1]
    if PluginSystem.CommandRegistery[sMain] ~= nil then
        for k,v in pairs(PluginSystem.CommandRegistery[sMain]) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                v.plugin[v.method](v.plugin,tCmdParts,bTeam,iPlayer)
            end
        end
    end
end

ListenToGameEvent("game_rules_state_change", function()
    local iState = GameRules:State_Get()
    PluginSystem:ProcRegisteredGameStates(iState)
end,nil)

ListenToGameEvent("player_chat", function(keys)
	local sText = keys.text
    if string.sub(sText, 1, 1) == "-" then
        local bTeam = keys.teamonly
        local iPlayer = keys.userid
        PluginSystem:ProcRegisteredCommands(bTeam,iPlayer,sText)
        if GameRules:IsCheatMode() then
            PluginSystem:TestCommands(bTeam,iPlayer,sText)
        end
    end
end,nil)


---
--Online save system
function PluginSystem:GenerateSave()
	local s = ""
    for sPlugin,tSetting in pairs(PluginSystem.LobbySettings) do
		if type(tSetting) == "table" then
			for key,val in pairs(tSetting) do
                if type(val) == "table" then
                    if val.DEFAULT ~= val.VALUE then
                        s = s .. sPlugin .. "&" .. key .. "&" .. val.VALUE .. "|"
                    end
                end
			end
		end
	end
	if string.len(s)  > 0 then
		s = string.sub(s,1,-2)
	end
	--print(s)
	return s
end


function PluginSystem:SendSettingSave(slot)
	local host = Toolbox:GetHostId()
    local steamid = tostring(PlayerResource:GetSteamID(host))
    if steamid == "0" then
        return
    end
    local url = "http://drteaspoon.fi:3000/butmodes/settings"
    local req = CreateHTTPRequestScriptVM("POST", url)
	local save = PluginSystem:GenerateSave()
	
    local hParams = {
        player = steamid,
        modeid = tostring(GAMEMODE_SAVE_ID),
		slot = tonumber(slot),
		data = save
    }
    req:SetHTTPRequestHeaderValue("Dedicated-Server-Key", GetDedicatedServerKeyV3(GAMEMODE_SAVE_ID))
	req:SetHTTPRequestHeaderValue("Content-Type", "application/json;charset=UTF-8")
	req:SetHTTPRequestRawPostBody("application/json", json.encode(hParams))

    req:Send(function(res)
        if res.StatusCode ~= 200 then
			--print(res.Body)
            --print("something went wrong")
        else
            --print("all ok")
			CustomNetTables:SetTableValue("save_slots", "slot_" .. slot, {data = save})
        end
    end)
end

function PluginSystem:GetSettingSave(slot)
	local host = Toolbox:GetHostId()
    local steamid = tostring(PlayerResource:GetSteamID(host))
    if steamid == "0" then
        --print("nope, it's a bot!")
        return
    end
    local url = "http://drteaspoon.fi:3000/butmodes/settings?steamid=" .. steamid .. "&modeid=" .. GAMEMODE_SAVE_ID .. "&slot=" .. slot
    local req = CreateHTTPRequestScriptVM("GET", url)
    req:SetHTTPRequestHeaderValue("Dedicated-Server-Key", GetDedicatedServerKeyV3(GAMEMODE_SAVE_ID))

    req:Send(function(res)
        if res.StatusCode ~= 200 then
			--print(res.Body)
            --print("something went wrong")
        else
			local data = JSON.decode(res.Body)
            --print(res.Body)
			if (#data == 1 and data[1] and data[1].result and #data[1].result == 1 and data[1].result[1].data) then
				CustomNetTables:SetTableValue("save_slots", "slot_" .. slot, {data = data[1].result[1].data})
			end
        end
    end)
end

function PluginSystem:LoadHostSettings()
    for i=0,10 do
        PluginSystem:GetSettingSave(i)
    end
end

function PluginSystem:SaveHostSettings()
    PluginSystem:SendSettingSave(PluginSystem.current_save_slot)
end

function PluginSystem:settings_save_slot(tEvent)
    local iPlayer = tEvent.PlayerID
	if not Toolbox:IsHost(iPlayer) then return end
    local iSlot = tEvent.slot
    if iSlot == nil then return end
    PluginSystem.current_save_slot = iSlot
    if tEvent.fn == 2 then
        --do nothing! (user wanted to select slot without activating it)
    elseif tEvent.fn == 1 then
        PluginSystem:ApplySaveSlot(iSlot,true)
    else
        PluginSystem:ApplySaveSlot(iSlot,false)
    end
end

function PluginSystem:ApplySaveSlot(iSlot,bAdditive)
    local sSettings = CustomNetTables:GetTableValue("save_slots", "slot_" .. iSlot)
    if not (sSettings and sSettings.data and type(sSettings.data) == "string") then return end
    local tSettings = PluginSystem:LoadSettingsString(sSettings.data)
    if tSettings and type(tSettings) == "table" then
        if not next(tSettings) then return end
        for sPlugin,tSetting in pairs(PluginSystem.LobbySettings) do
            if type(tSetting) == "table" then
                if tSettings[sPlugin] == nil then
                    for key,val in pairs(tSetting) do
                        if type(val) == "table" then
                            if not bAdditive then
                                PluginSystem:SetSetting(sPlugin,key,val.DEFAULT)
                            end
                        end
                    end
                else
                    for key,val in pairs(tSetting) do
                        if type(val) == "table" then
                            if tSettings[sPlugin][key] ~= nil and val.DEFAULT ~= tSettings[sPlugin][key] then
                                PluginSystem:SetSetting(sPlugin,key,tSettings[sPlugin][key])
                            else
                                if not bAdditive then
                                    PluginSystem:SetSetting(sPlugin,key,val.DEFAULT)
                                end
                            end
                        end
                    end
                end
            end
            CustomNetTables:SetTableValue("plugin_settings",sPlugin,PluginSystem.LobbySettings[sPlugin])
        end
    end
end

function PluginSystem:LoadSettingsString(s)
	local t = Toolbox:split(s,"|")
    local r = {}
	for i=1,#t do
		local o = Toolbox:split(t[i],"&")
        if r[o[1]] == nil then
            r[o[1]] = {}
        end
        r[o[1]][o[2]] = o[3]
	end
    return r
end

--Filters

function PluginSystem:SetFilters()
    local contxt = {}
    GameRules:GetGameModeEntity():SetUseDefaultDOTARuneSpawnLogic(true)
    GameRules:GetGameModeEntity():SetAbilityTuningValueFilter( PluginSystem.AbilityTuningValueFilter, contxt )
    GameRules:GetGameModeEntity():SetBountyRunePickupFilter( PluginSystem.BountyRunePickupFilter, contxt )
    GameRules:GetGameModeEntity():SetDamageFilter( PluginSystem.DamageFilter, contxt )
    GameRules:GetGameModeEntity():SetExecuteOrderFilter( PluginSystem.ExecuteOrderFilter, contxt )
    GameRules:GetGameModeEntity():SetHealingFilter( PluginSystem.HealingFilter, contxt )
    GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter( PluginSystem.ItemAddedToInventoryFilter, contxt )
    GameRules:GetGameModeEntity():SetModifierGainedFilter( PluginSystem.ModifierGainedFilter, contxt )
    GameRules:GetGameModeEntity():SetModifyExperienceFilter( PluginSystem.ModifyExperienceFilter, contxt )
    GameRules:GetGameModeEntity():SetModifyGoldFilter( PluginSystem.ModifyGoldFilter, contxt )
    GameRules:GetGameModeEntity():SetRuneSpawnFilter( PluginSystem.RuneSpawnFilter, contxt )
    GameRules:GetGameModeEntity():SetTrackingProjectileFilter( PluginSystem.TrackingProjectileFilter, contxt )
end

function PluginSystem:RegisterFilter(sFilter,hPlugin,hMethod,sPlugin)
    if tFilters[sFilter] == nil then
        --print(sPlugin,"plugin tried to register non existant filter",sFilter)
        return
    end
    if PluginSystem[tFilters[sFilter]] == nil then PluginSystem[tFilters[sFilter]] = {} end
    table.insert(PluginSystem[tFilters[sFilter]],{plugin = hPlugin, method = hMethod, plugin_name = sPlugin})
end

function PluginSystem:AbilityTuningValueFilter(event)
    if PluginSystem.AbilityTuningValueFilters ~= nil then
        for k,v in pairs(PluginSystem.AbilityTuningValueFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end

function PluginSystem:BountyRunePickupFilter(event)
    if PluginSystem.BountyRunePickupFilters ~= nil then
        for k,v in pairs(PluginSystem.BountyRunePickupFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end

function PluginSystem:DamageFilter(event)
    if PluginSystem.DamageFilters ~= nil then
        for k,v in pairs(PluginSystem.DamageFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end

function PluginSystem:ExecuteOrderFilter(event)
    if PluginSystem.ExecuteOrderFilters ~= nil then
        for k,v in pairs(PluginSystem.ExecuteOrderFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end

function PluginSystem:HealingFilter(event)
    if PluginSystem.HealingFilters ~= nil then
        for k,v in pairs(PluginSystem.HealingFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end

function PluginSystem:ItemAddedToInventoryFilter(event)
    if PluginSystem.ItemAddedToInventoryFilters ~= nil then
        for k,v in pairs(PluginSystem.ItemAddedToInventoryFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end

function PluginSystem:ModifierGainedFilter(event)
    if PluginSystem.ModifierGainedFilters ~= nil then
        for k,v in pairs(PluginSystem.ModifierGainedFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end

function PluginSystem:ModifyExperienceFilter(event)
    if PluginSystem.ModifyExperienceFilters ~= nil then
        for k,v in pairs(PluginSystem.ModifyExperienceFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end
function PluginSystem:ModifyGoldFilter(event)
    if PluginSystem.ModifyGoldFilters ~= nil then
        for k,v in pairs(PluginSystem.ModifyGoldFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end
function PluginSystem:RuneSpawnFilter(event)
    if PluginSystem.RuneSpawnFilters ~= nil then
        for k,v in pairs(PluginSystem.RuneSpawnFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end
function PluginSystem:TrackingProjectileFilter(event)
    if PluginSystem.TrackingProjectileFilters ~= nil then
        for k,v in pairs(PluginSystem.TrackingProjectileFilters) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                local tResult = v.plugin[v.method](v.plugin,event)
                if not tResult[1] then return false end
                event = tResult[2]
            end
        end
    end
    return true
end


function PluginSystem:setting_activate_mutator(tEvent)
    local iPlayer = tEvent.PlayerID
	if not Toolbox:IsHost(iPlayer) then return end
    PluginSystem:ApplyPresetAdditive(tEvent.mutator)
end

function PluginSystem:MutatorModeSelect(iCount)
    local tAvailable = {}
    for k,v in pairs(PluginSystem.presets) do
        --print(k)
        table.insert(tAvailable,k)
    end
    local tPicks = {}
    local tTags = {}
    local tNoTags = {}
    local iTries = 0
    while iTries < 100 do
        local p = PluginSystem:PickRng(tAvailable)
        --print(p[1])
        if not (PluginSystem.presets[p[1]].overlap_tags ~= nil and Toolbox:table_contains(tTags,PluginSystem.presets[p[1]].overlap_tags)) then
            if not (PluginSystem.presets[p[1]].no_tags ~= nil and Toolbox:table_contains(tTags,PluginSystem.presets[p[1]].no_tags)) then
                if not (PluginSystem.presets[p[1]].add_tags ~= nil and Toolbox:table_contains(tNoTags,PluginSystem.presets[p[1]].add_tags)) then
                    if (PluginSystem.presets[p[1]].overlap_tags ~= nil) then
                        local tOverlap = Toolbox:split(PluginSystem.presets[p[1]].overlap_tags, " ")
                        for k,v in pairs(tOverlap) do
                            if not Toolbox:table_contains(tTags,v) then
                                table.insert(tTags,v)
                            end
                        end
                    end
                    if (PluginSystem.presets[p[1]].no_tags ~= nil) then
                        local tNopes = Toolbox:split(PluginSystem.presets[p[1]].no_tags, " ")
                        for k,v in pairs(tNopes) do
                            if not Toolbox:table_contains(tNoTags,v) then
                                table.insert(tNoTags,v)
                            end
                        end
                    end
                    if (PluginSystem.presets[p[1]].add_tags ~= nil) then
                        local tAdd = Toolbox:split(PluginSystem.presets[p[1]].add_tags, " ")
                        for k,v in pairs(tAdd) do
                            if not Toolbox:table_contains(tTags,v) then
                                table.insert(tTags,v)
                            end
                        end
                    end
                    table.insert(tPicks,p[1])
                    tAvailable = p[2]
                end
            end
        end
        if #tPicks > (iCount-1) then
            iTries = 200
        else
            iTries = iTries + 1
        end
    end
    PluginSystem.mutator_picks = tPicks
end

function PluginSystem:PickRng(t)
    local p = RandomInt(1, #t)
    local r = t[p]
    table.remove(t,p)
    return {r,t}
end

PluginSystem.teams = {
    DOTA_TEAM_GOODGUYS,
    DOTA_TEAM_BADGUYS,
    DOTA_TEAM_CUSTOM_1,
    DOTA_TEAM_CUSTOM_2,
    DOTA_TEAM_CUSTOM_3,
    DOTA_TEAM_CUSTOM_4,
    DOTA_TEAM_CUSTOM_5,
    DOTA_TEAM_CUSTOM_6,
    DOTA_TEAM_CUSTOM_7,
    DOTA_TEAM_CUSTOM_8
}

function PluginSystem:TestCommands(bTeam,iPlayer,sText)
    local tCmdParts = Toolbox:split(sText," ")
    local sMain = tCmdParts[1]
    if sMain == "-teams" then
        local iTeam = tonumber(tCmdParts[2])
        local iNum = tonumber(tCmdParts[3])
        tEvent = {
            PlayerID = iPlayer,
            team = iTeam,
            number = iNum
        }
        PluginSystem:setting_team_rescale(tEvent)
    end
end

function PluginSystem:setting_team_rescale(tEvent)
    local iPlayer = tEvent.PlayerID
	if not Toolbox:IsHost(iPlayer) then return end
    local iTeam = tEvent.team
    local iNum = tEvent.number
    GameRules:SetCustomGameTeamMaxPlayers(iTeam,iNum)
    PluginSystem.LobbySettings["core_teams"][tostring(iTeam)].VALUE = iNum
    
    local iCount = 0
    for iPlayer = 0,DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(iPlayer) then
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer ~= nil then
                local iTeamPlayer = PlayerResource:GetCustomTeamAssignment(iPlayer)
                if iTeamPlayer == iTeam then
                    if iCount <= iNum then
                        PluginSystem:MoveToValidTeam(iPlayer)
                    end
                    iCount = iCount + 1
                end
            end
        end
    end
    CustomGameEventManager:Send_ServerToAllClients("setting_team_rescale",{team = tEvent.team, number = tEvent.number})
end

function PluginSystem:MoveToValidTeam(iPlayer)
    for i=1,#PluginSystem.teams do
        local iTeam = PluginSystem.teams[i]
        if GameRules:GetCustomGameTeamMaxPlayers(iTeam) > PlayerResource:GetPlayerCountForTeam(iTeam) then
            PlayerResource:SetCustomTeamAssignment(iPlayer,iTeam)
            return
        end
    end
    PlayerResource:SetCustomTeamAssignment(iPlayer,1)
end

function PluginSystem:DvdCheck()
    
    ListenToGameEvent("entity_killed", function(tEvent)
        local hAttacker = tEvent.entindex_attacker and EntIndexToHScript(tEvent.entindex_attacker)
        local hKilled = tEvent.entindex_killed and EntIndexToHScript(tEvent.entindex_killed)
        local iDamageBits = tEvent.damagebits
        if (not hAttacker:IsBaseNPC() or not hKilled:IsBaseNPC()) then return end
        if (not hAttacker:IsRealHero() or not hKilled:IsRealHero()) then return end
        local iPlayer = hAttacker:GetPlayerID()
        if PluginSystem.dvd_done == nil then PluginSystem.dvd_done = {} end

        if PluginSystem.dvd_done[iPlayer] ~= nil and PluginSystem.dvd_done[iPlayer] == 0 then return end

        if not RollPseudoRandomPercentage(20,DOTA_PSEUDO_RANDOM_CUSTOM_GAME_9,hAttacker) then return end

        local steamid = tostring(PlayerResource:GetSteamID(iPlayer))
        if steamid ~= "0" then
            if PluginSystem.dvd_done[iPlayer] == nil then
                PluginSystem.dvd_done[iPlayer] = tonumber(PluginSystem.dvd[steamid])
            else
                PluginSystem.dvd_done[iPlayer] = PluginSystem.dvd_done[iPlayer] - 1
            end
            PluginSystem:Dvd(iPlayer)
        end

    end,nil)
end

function PluginSystem:Dvd(iPlayer)
    CustomUI:DynamicHud_Create(iPlayer,"dvd","file://{resources}/layout/custom_game/dvd.xml",nil)
    Timers:CreateTimer( Script_RandomFloat(10.0,20.0), function()
        CustomUI:DynamicHud_Destroy(iPlayer,"dvd")
        return nil
    end)
end


    
function PluginSystem:load_kv_file_headers(file)
    local t = {}
    for k,v in pairs(file) do
        if type(v) == "table" then
            table.insert(t,k)
        end
    end
    return t
end

function PluginSystem:load_kv_file_headers_custom(file)
    local t = {}
    for k,v in pairs(file) do
        if type(v) == "table" then
            if v.CustomList ~= nil then --some 
                table.insert(t,k)
            end
        end
    end
    return t
end


function PluginSystem:load_abilities()
    PluginSystem.core_abilities = {}
	local file = LoadKeyValues('scripts/npc/npc_abilities.txt')
    if not (file == nil or not next(file)) then
        PluginSystem.core_abilities['neutral'] = PluginSystem:load_kv_file_headers(file)
    end
	local heroes_enabled = LoadKeyValues('scripts/npc/activelist.txt')
    if not (heroes_enabled == nil or not next(heroes_enabled)) then
        for k,v in pairs(heroes_enabled) do
            local file = LoadKeyValues('scripts/npc/heroes/' .. k .. '.txt')
            if not (file == nil or not next(file)) then
                PluginSystem.core_abilities[k] = PluginSystem:load_kv_file_headers(file)
            end
        end
    end
    
	local file_custom = LoadKeyValues('scripts/npc/npc_abilities_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        PluginSystem.core_abilities["zcustom"] = PluginSystem:load_kv_file_headers_custom(file_custom)
    end
    local t_all = {}
    for k,v in pairs(PluginSystem.core_abilities) do
        CustomNetTables:SetTableValue("core_data_abilities",k,v)
        for j,l in pairs(v) do
            table.insert(t_all,l)
        end
    end
end



function PluginSystem:load_items()
    PluginSystem.core_items = {}
	local file = LoadKeyValues('scripts/npc/items.txt')
    if not (file == nil or not next(file)) then
        PluginSystem.core_items['normal'] = PluginSystem:load_kv_file_headers(file)
    end
    
	local file_custom = LoadKeyValues('scripts/npc/npc_items_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        PluginSystem.core_items["zcustom"] = PluginSystem:load_kv_file_headers_custom(file_custom)
    end
    local t_all = {}
    for k,v in pairs(PluginSystem.core_items) do
        CustomNetTables:SetTableValue("core_data_items",k,v)
        for j,l in pairs(v) do
            table.insert(t_all,l)
        end
    end
end

function PluginSystem:load_units()
    PluginSystem.core_units = {}
	local file = LoadKeyValues('scripts/npc/npc_units.txt')
    if not (file == nil or not next(file)) then
        PluginSystem.core_units['normal'] = PluginSystem:load_kv_file_headers(file)
    end
    
	local file = LoadKeyValues('scripts/npc/npc_heroes.txt')
    if not (file == nil or not next(file)) then
        PluginSystem.core_units['heroes'] = PluginSystem:load_kv_file_headers(file)
    end
    
	local file_custom = LoadKeyValues('scripts/npc/npc_units_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        PluginSystem.core_units["zcustom"] = PluginSystem:load_kv_file_headers_custom(file_custom)
    end
    local t_all = {}
    for k,v in pairs(PluginSystem.core_units) do
        CustomNetTables:SetTableValue("core_data_units",k,v)
        for j,l in pairs(v) do
            table.insert(t_all,l)
        end
    end
end

function PluginSystem:load_modifiers()
end

function PluginSystem:paginate_send(data_table,sub_name,table_name,page_size)
    table.sort(data_table)
    local page_size = page_size or 20
    local current_page = {}
    local current_page_index = 0
    local current_size = 0
    for k,v in pairs(data_table) do
        table.insert(current_page,v)
        current_size = current_size + 1
        v.page = current_page_index
        if current_size > page_size then
            CustomNetTables:SetTableValue(table_name,sub_name .. "_" .. current_page_index,v)
            current_page_index = current_page_index + 1
            current_size = 0
            current_page = {}
        end
    end
    if #current_page > 0 then
        CustomNetTables:SetTableValue(table_name,sub_name .. "_" .. current_page_index,v)
        current_page_index = current_page_index + 1
    end
end


PluginSystem.ability_requests = {}
function PluginSystem:ask_for_ability(category,callback,uuid,iPlayer)
    if PluginSystem.ability_requests[uuid] ~= nil then return end
    PluginSystem.ability_requests[uuid] = callback
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    local tEvent = {
        name = category,
        caller = uuid
    }
    if hPlayer ~= nil then
        CustomGameEventManager:Send_ServerToPlayer(hPlayer,"core_ability_indexer",tEvent)
    end

end

function PluginSystem:core_ability_indexer(tEvent)
    local uuid = tEvent.caller
    if PluginSystem.ability_requests[uuid] == nil then return end
    PluginSystem.ability_requests[uuid](tEvent)
    PluginSystem.ability_requests[uuid] = nil
end

function PluginSystem:plugin_system_show_abilities(tEvent)
    local iPlayer = tEvent.PlayerID
    local sCategory = tEvent.name
    PluginSystem:ask_for_ability(sCategory,function(tData)
        local hPlayer = PlayerResource:GetPlayer(iPlayer)
        if hPlayer ~= nil then
            local tEvent = {
                name = tData.name
            }
            CustomGameEventManager:Send_ServerToPlayer(hPlayer,"plugin_system_show_abilities",tEvent)
        end
    end,"plugin_sys_" .. GetSystemTimeMS(),iPlayer)
end


PluginSystem.item_requests = {}
function PluginSystem:ask_for_item(category,callback,uuid,iPlayer)
    if PluginSystem.item_requests[uuid] ~= nil then return end
    PluginSystem.item_requests[uuid] = callback
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    local tEvent = {
        name = category,
        caller = uuid
    }
    if hPlayer ~= nil then
        CustomGameEventManager:Send_ServerToPlayer(hPlayer,"core_item_indexer",tEvent)
    end
end

function PluginSystem:core_item_indexer(tEvent)
    local uuid = tEvent.caller
    if PluginSystem.item_requests[uuid] == nil then return end
    PluginSystem.item_requests[uuid](tEvent)
    PluginSystem.item_requests[uuid] = nil
end

function PluginSystem:plugin_system_show_items(tEvent)
    local iPlayer = tEvent.PlayerID
    local sCategory = tEvent.name
    PluginSystem:ask_for_item(sCategory,function(tData)
        local hPlayer = PlayerResource:GetPlayer(iPlayer)
        if hPlayer ~= nil then
            local tEvent = {
                name = tData.name
            }
            CustomGameEventManager:Send_ServerToPlayer(hPlayer,"plugin_system_show_items",tEvent)
        end
    end,"plugin_sys_" .. GetSystemTimeMS(),iPlayer)
end


PluginSystem.unit_requests = {}
function PluginSystem:ask_for_unit(category,callback,uuid,iPlayer)
    if PluginSystem.unit_requests[uuid] ~= nil then return end
    PluginSystem.unit_requests[uuid] = callback
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    local tEvent = {
        name = category,
        caller = uuid
    }
    if hPlayer ~= nil then
        CustomGameEventManager:Send_ServerToPlayer(hPlayer,"core_unit_indexer",tEvent)
    end

end

function PluginSystem:core_unit_indexer(tEvent)
    local uuid = tEvent.caller
    if PluginSystem.unit_requests[uuid] == nil then return end
    PluginSystem.unit_requests[uuid](tEvent)
    PluginSystem.unit_requests[uuid] = nil
end

function PluginSystem:plugin_system_show_units(tEvent)
    local iPlayer = tEvent.PlayerID
    local sCategory = tEvent.name
    PluginSystem:ask_for_unit(sCategory,function(tData)
        local hPlayer = PlayerResource:GetPlayer(iPlayer)
        if hPlayer ~= nil then
            local tEvent = {
                name = tData.name
            }
            CustomGameEventManager:Send_ServerToPlayer(hPlayer,"plugin_system_show_units",tEvent)
        end
    end,"plugin_sys_" .. GetSystemTimeMS(),iPlayer)
end


PluginSystem.credits = {}
function PluginSystem:load_credits()
	PluginSystem.credits = LoadKeyValues('scripts/credits.txt')
    CustomNetTables:SetTableValue("credits","credits",PluginSystem.credits)
end