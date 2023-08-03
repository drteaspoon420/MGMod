

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
    print("[PluginSystem] init")

    CustomGameEventManager:RegisterListener("settings_save_slot",function(i,tEvent) PluginSystem:settings_save_slot(tEvent) end)
    CustomGameEventManager:RegisterListener("setting_change",PluginSystem.setting_change)
    CustomGameEventManager:RegisterListener("settings_vote_unlock",function(i,tEvent) PluginSystem:settings_vote_unlock(tEvent) end)
    
    GameRules:SetSafeToLeave(true)
    --GameRules:SetCustomGameAccountRecordSaveFunction( Dynamic_Wrap( PluginSystem, "SaveHostSettings_PartA" ), self )
    GameRules:SetCustomGameEndDelay(15)
    GameRules:SetCustomGameSetupAutoLaunchDelay(60)
    --GameRules:SetCustomGameSetupAutoLaunchDelay(420)
    GameRules:SetCustomGameSetupRemainingTime(-1)
    GameRules:SetCustomGameSetupTimeout(-1)

	local forced_file = LoadKeyValues('scripts/vscripts/plugin_system/forced.txt')
    if not (forced_file == nil or not next(forced_file)) then
        PluginSystem.forced = forced_file
    end
    if PluginSystem.forced.lock_level ~= nil then PluginSystem.locked = PluginSystem.forced.lock_level end
	local presets_file = LoadKeyValues('scripts/vscripts/plugin_system/presets/main.txt')
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
        print("file loaded " .. sPlugin)
        local main_class = tSettings.MainClass
        local state_regs = tSettings.StateRegistrations or {}
        local cmd_regs = tSettings.CmdRegistrations or {}
        local filter_regs = tSettings.FilterRegistrations or {}
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
            and PluginSystem.forced.preset ~= nil and
            PluginSystem.presets ~= nil and PluginSystem.presets[PluginSystem.forced.preset] ~= nil and PluginSystem.presets[PluginSystem.forced.preset].settings ~= nil
            then
                PluginSystem:LoadDefaultSettings(sPlugin,settings,PluginSystem.presets[PluginSystem.forced.preset].settings)
            else
                PluginSystem:LoadDefaultSettings(sPlugin,settings)
            end
        else
            PluginSystem.LobbySettings[sPlugin].enabled = {}
            PluginSystem.LobbySettings[sPlugin].enabled.DEFAULT = 0
            PluginSystem.LobbySettings[sPlugin].enabled.TYPE = "boolean"
            PluginSystem.LobbySettings[sPlugin].enabled.VALUE = 0
        end
        for state_function,state_string in pairs(state_regs) do
            PluginSystem:RegisterState(tStates[state_string],_G[main_class],state_function,sPlugin)
        end
        for cmd_regs_string,cmd_regs_function in pairs(cmd_regs) do
            PluginSystem:RegisterCmd(cmd_regs_string,_G[main_class],cmd_regs_function,sPlugin)
        end
        for filter_regs_string,filter_regs_function in pairs(filter_regs) do
            PluginSystem:RegisterFilter(filter_regs_string,_G[main_class],filter_regs_function,sPlugin)
        end
    end
    for sPlugin,tSettings in pairs(PluginSystem.PluginsFile) do
        local init_function = tSettings.InitFunction or nil
        if init_function ~= nil then
            local main_class = tSettings.MainClass
            _G[main_class][init_function]()
        end
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
        print(iCount,iVotes,PluginSystem.forced.vote_treshold)
        if (PluginSystem.forced.vote_treshold * 0.01 < iVotes/iCount) then
            PluginSystem.forced.lock_level = 0
        end
        CustomNetTables:SetTableValue("forced_mode","initial",PluginSystem.forced)
    end
end
--settings
function PluginSystem:ApplyPreset(sPreset)
    print("loading preset",sPreset)
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
    print("loading preset",sPreset)
    if PluginSystem.presets == nil or PluginSystem.presets[sPreset] == nil then return end
    local tSettings = PluginSystem.presets[sPreset]
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
                if v.TYPE == "dropdown" then
                    t[k] = v.VALUE
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
    end
    if PluginSystem.StateRegistry[iState] ~= nil then
        for k,v in pairs(PluginSystem.StateRegistry[iState]) do
            if PluginSystem.LobbySettings[v.plugin_name].enabled.VALUE == 1 then
                v.plugin[v.method](v.plugin)
            end
        end
    end
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
    print(tEvent)
    for k,v in pairs(PluginSystem.InternalEvents[sEvent]) do
        v(tEvent)
    end
end

function PluginSystem:RegisterCmd(sMain,hPlugin,hMethod,sPlugin)
    print("registering",sMain,"for",sPlugin)
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
	print(s)
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
			print(res.Body)
            print("something went wrong")
        else
            print("all ok")
			CustomNetTables:SetTableValue("save_slots", "slot_" .. slot, {data = save})
        end
    end)
end

function PluginSystem:GetSettingSave(slot)
	local host = Toolbox:GetHostId()
    local steamid = tostring(PlayerResource:GetSteamID(host))
    if steamid == "0" then
        print("nope, it's a bot!")
        return
    end
    local url = "http://drteaspoon.fi:3000/butmodes/settings?steamid=" .. steamid .. "&modeid=" .. GAMEMODE_SAVE_ID .. "&slot=" .. slot
    local req = CreateHTTPRequestScriptVM("GET", url)
    req:SetHTTPRequestHeaderValue("Dedicated-Server-Key", GetDedicatedServerKeyV3(GAMEMODE_SAVE_ID))

    req:Send(function(res)
        if res.StatusCode ~= 200 then
			print(res.Body)
            print("something went wrong")
        else
			local data = JSON.decode(res.Body)
            print(res.Body)
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
        print(sPlugin,"plugin tried to register non existant filter",sFilter)
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
