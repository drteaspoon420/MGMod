LegendsOfDotaPlugin = class({})
_G.LegendsOfDotaPlugin = LegendsOfDotaPlugin
local JSON = require("utils/dkjson")
LegendsOfDotaPlugin.settings = {}

LegendsOfDotaPlugin.heroes = {}
LegendsOfDotaPlugin.npc_abilities = {}
LegendsOfDotaPlugin.npc_abilities_custom = {}
LegendsOfDotaPlugin.no_duplication = {}
LegendsOfDotaPlugin.ban_list = {}

LegendsOfDotaPlugin.player_build = {}

LegendsOfDotaPlugin.ability_pools = {}
LegendsOfDotaPlugin.ability_pools_sorted = {}
LegendsOfDotaPlugin.hero_definitions = {}
LegendsOfDotaPlugin.test_dummy_attempts = 0
LegendsOfDotaPlugin.cache = {}

LegendsOfDotaPlugin.player_data = {}

function LegendsOfDotaPlugin:Init()
    print("[LegendsOfDotaPlugin] found")
end

function LegendsOfDotaPlugin:ApplySettings()
    LegendsOfDotaPlugin.settings = PluginSystem:GetAllSetting("legends_of_dota")
	local gm = GameRules:GetGameModeEntity()
    GameRules:SetHeroSelectionTime(10*60)
    GameRules:SetHeroSelectPenaltyTime(0)
    GameRules:SetStrategyTime(30)
	gm:SetDraftingBanningTimeOverride(0)
	--gm:SetDraftingHeroPickSelectTimeOverride(60)
	gm:SetDraftingHeroPickSelectTimeOverride(10*60)
    LegendsOfDotaPlugin:LoadHeroes()
    LegendsOfDotaPlugin:LoadAbilities()
    CustomGameEventManager:RegisterListener("hero_pick",LegendsOfDotaPlugin.hero_pick)
    CustomGameEventManager:RegisterListener("ability_pick",LegendsOfDotaPlugin.ability_pick)
    CustomGameEventManager:RegisterListener("player_ready",LegendsOfDotaPlugin.player_ready)
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            LegendsOfDotaPlugin:SpawnEvent(event)
    end,nil)
    LegendsOfDotaPlugin:SpawnTestDummy()
end

function LegendsOfDotaPlugin:LoadHeroes()
    LegendsOfDotaPlugin.heroes = {
        {},		-- strength_heroes
        {},		-- agility_heroes
        {},		-- intelligence_heroes
        {}		-- universal
    }
    LegendsOfDotaPlugin.hero_definitions = LoadKeyValues('scripts/npc/npc_heroes.txt')
    local process_hero = function(hero_data,hero_name)
        if hero_data.Enabled ~= 1 then return end
        local hero_attribute = _G[hero_data.AttributePrimary]
        local attribute = hero_attribute + 1
        local tHero = {
            name = hero_name,
            banned = false,
            id = hero_data.HeroID,
        }
        table.insert(LegendsOfDotaPlugin.heroes[attribute], tHero)
    end
    for hero_name,_ in pairs(LegendsOfDotaPlugin.hero_definitions) do
        if (type(LegendsOfDotaPlugin.hero_definitions[hero_name]) == "table") then
            if LegendsOfDotaPlugin.hero_definitions[hero_name].HeroID ~= nil then
                process_hero(LegendsOfDotaPlugin.hero_definitions[hero_name],hero_name)
            end
        end
    end
    
    
    CustomNetTables:SetTableValue("heroselection_rework", "hero_pools", LegendsOfDotaPlugin.heroes)
end


function LegendsOfDotaPlugin:LoadAbilities()
	local file = LoadKeyValues('scripts/npc/npc_abilities.txt')
    if not (file == nil or not next(file)) then
        LegendsOfDotaPlugin.npc_abilities = file
    end
	local file_custom = LoadKeyValues('scripts/npc/npc_abilities_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        LegendsOfDotaPlugin.npc_abilities_custom = file_custom
    end
	local no_duplication = LoadKeyValues('scripts/vscripts/plugin_system/plugins/legends_of_dota/no_duplication.txt')
    if not (no_duplication == nil or not next(no_duplication)) then
        LegendsOfDotaPlugin.no_duplication = no_duplication
    end
	local ban_list = LoadKeyValues('scripts/vscripts/plugin_system/plugins/legends_of_dota/ban_list.txt')
    if not (ban_list == nil or not next(ban_list)) then
        LegendsOfDotaPlugin.ban_list = ban_list
    end
    if LegendsOfDotaPlugin.settings.custom_bans ~= nil then
        if string.len(LegendsOfDotaPlugin.settings.custom_bans) > 1 and string.len(LegendsOfDotaPlugin.settings.custom_bans) < 20 then
            LegendsOfDotaPlugin:LoadBanList(LegendsOfDotaPlugin.settings.custom_bans)
        else
            LegendsOfDotaPlugin:PrepStageTwo()
        end
    else
        LegendsOfDotaPlugin:PrepStageTwo()
    end
end


function LegendsOfDotaPlugin:AllDonePreping()
    table.sort(LegendsOfDotaPlugin.ability_pools_sorted, function (k1, k2) return k1.name < k2.name end )
    
    for k,v in pairs(LegendsOfDotaPlugin.ability_pools) do
        CustomNetTables:SetTableValue("heroselection_rework_abilities", k, v)
    end
end

function LegendsOfDotaPlugin:LoadBanList(pastebin)
    local url = "https://pastebin.com/raw/" .. pastebin
    local req = CreateHTTPRequestScriptVM("GET", url)
    req:Send(function(res)
        if res.StatusCode ~= 200 then
            print(res.Body)
            print("something went wrong")
        else
            print(res.Body)
			local data = JSON.decode(res.Body)
            LegendsOfDotaPlugin.ban_list = data.ban_list
        end
        LegendsOfDotaPlugin:PrepStageTwo()
    end)
end

function LegendsOfDotaPlugin:CustomAbilityLists(v)
    if LegendsOfDotaPlugin.settings["custom_abilities_" .. v] ~= nil and LegendsOfDotaPlugin.settings["custom_abilities_" .. v] == true then
        return true
    end
    return false
end

function LegendsOfDotaPlugin:PrepStageTwo()
    local bStrict = (not LegendsOfDotaPlugin.settings.allow_extended)
    for k,v in pairs(LegendsOfDotaPlugin.npc_abilities) do
        if v ~= nil and type(v) == 'table' then
            if v.AbilityType ~= nil then
                if v.AbilityType == "DOTA_ABILITY_TYPE_ATTRIBUTES" then
                    LegendsOfDotaPlugin:AddTalent(k,v,bStrict,nil)
                elseif v.AbilityType == "DOTA_ABILITY_TYPE_ULTIMATE" then
                    LegendsOfDotaPlugin:AddUltimate(k,v,bStrict,nil)
                else
                    LegendsOfDotaPlugin:AddBasic(k,v,bStrict,nil)
                end
            else
                LegendsOfDotaPlugin:AddBasic(k,v,bStrict,nil)
            end
        end 
    end
    for k,v in pairs(LegendsOfDotaPlugin.npc_abilities_custom) do
        if v ~= nil and type(v) == 'table' then
            if LegendsOfDotaPlugin.npc_abilities[k] == nil then
                if v.CustomList ~= nil and LegendsOfDotaPlugin:CustomAbilityLists(v.CustomList) then
                    if v.AbilityType ~= nil then
                        if v.AbilityType == "DOTA_ABILITY_TYPE_ATTRIBUTES" then
                            LegendsOfDotaPlugin:AddTalent(k,v,false,v.CustomList)
                        elseif v.AbilityType == "DOTA_ABILITY_TYPE_ULTIMATE" then
                            LegendsOfDotaPlugin:AddUltimate(k,v,false,v.CustomList)
                        else
                            LegendsOfDotaPlugin:AddBasic(k,v,false,v.CustomList)
                        end
                    else
                        LegendsOfDotaPlugin:AddBasic(k,v,false,v.CustomList)
                    end
                end
            end
        end 
    end
    LegendsOfDotaPlugin:AllDonePreping()
end


function LegendsOfDotaPlugin:AddTalent(sAbility,data,bStrict,sOwner)
    if not LegendsOfDotaPlugin.settings.allow_talents then return end
    if LegendsOfDotaPlugin.ban_list[sAbility] == nil then
        if sOwner == nil then
            sOwner = LegendsOfDotaPlugin:FindHeroAbilityOwner(sAbility,bStrict)
        end
        if (sOwner == "disabled") then return end
        if LegendsOfDotaPlugin.ability_pools[sOwner] == nil then
            LegendsOfDotaPlugin.ability_pools[sOwner] = {}
        end
        while (#LegendsOfDotaPlugin.ability_pools[sOwner] > 30) do
            sOwner = sOwner .. "_e"
            if LegendsOfDotaPlugin.ability_pools[sOwner] == nil then
                LegendsOfDotaPlugin.ability_pools[sOwner] = {}
            end
        end
        local t = {
            name = sAbility,
            category = "talent",
            linked = LegendsOfDotaPlugin:FindLinkedAbilities(sAbility),
        }
        table.insert(LegendsOfDotaPlugin.ability_pools_sorted,{
            name = sAbility,
            category = "talent",
        })
        table.insert(LegendsOfDotaPlugin.ability_pools[sOwner],t)
    end
end

function LegendsOfDotaPlugin:AddBasic(sAbility,data,bStrict,sOwner)
    if LegendsOfDotaPlugin.ban_list[sAbility] == nil then
        if sOwner == nil then
            sOwner = LegendsOfDotaPlugin:FindHeroAbilityOwner(sAbility,bStrict)
        end
        if (sOwner == "disabled") then return end
        if LegendsOfDotaPlugin.ability_pools[sOwner] == nil then
            LegendsOfDotaPlugin.ability_pools[sOwner] = {}
        end
        local t = {
            name = sAbility,
            category = "basic",
            linked = LegendsOfDotaPlugin:FindLinkedAbilities(sAbility),
        }
        table.insert(LegendsOfDotaPlugin.ability_pools_sorted,{
            name = sAbility,
            category = "basic",
        })
        table.insert(LegendsOfDotaPlugin.ability_pools[sOwner],t)
    end
end

function LegendsOfDotaPlugin:AddUltimate(sAbility,data,bStrict,sOwner)
    if LegendsOfDotaPlugin.ban_list[sAbility] == nil then
        if sOwner == nil then
            sOwner = LegendsOfDotaPlugin:FindHeroAbilityOwner(sAbility,bStrict)
        end
        if (sOwner == "disabled") then return end
        if LegendsOfDotaPlugin.ability_pools[sOwner] == nil then
            LegendsOfDotaPlugin.ability_pools[sOwner] = {}
        end
        local t = {
            name = sAbility,
            category = "ultimate",
            linked = LegendsOfDotaPlugin:FindLinkedAbilities(sAbility),
        }
        table.insert(LegendsOfDotaPlugin.ability_pools_sorted,{
            name = sAbility,
            category = "ultimate",
        })
        table.insert(LegendsOfDotaPlugin.ability_pools[sOwner],t)
    end
end

function LegendsOfDotaPlugin:FindHeroAbilityOwner(sAbility,bStrict)
    for k,v in pairs(LegendsOfDotaPlugin.hero_definitions) do
        if type(v) == "table" then
            for i=1,DOTA_MAX_ABILITIES do
                if v["Ability" .. i] ~= nil and v["Ability" .. i] == sAbility then
                    if string.starts(k,"npc_dota_hero_") then
                        return "1_" .. string.sub(k,string.len("npc_dota_hero_")+1)
                    else
                        return k
                    end
                end
            end
        end
    end
    if (bStrict) then
        return "disabled"
    end
    return Toolbox:split(sAbility,"_")[1]
end

function LegendsOfDotaPlugin:FindHeroTalentOwner(sAbility)
    if string.starts(sAbility,"special_bonus_unique_") then
        return LegendsOfDotaPlugin:FindHeroAbilityOwner(sAbility)
    end
    return "zz_generic_talent"
end


function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end
 
function LegendsOfDotaPlugin:FindLinkedTalents(sAbility)
    local t = {}
    if LegendsOfDotaPlugin.npc_abilities[sAbility] == nil then
        return t
    end
    if LegendsOfDotaPlugin.npc_abilities[sAbility].AbilityValues ~= nil then
        t = LegendsOfDotaPlugin:SeekPrefixKeys(LegendsOfDotaPlugin.npc_abilities[sAbility].AbilityValues,"special_bonus_unique_")
        t = LegendsOfDotaPlugin:SeekPrefixValues(LegendsOfDotaPlugin.npc_abilities[sAbility].AbilityValues,"special_bonus_unique_",t)
    elseif LegendsOfDotaPlugin.npc_abilities[sAbility].AbilitySpecial ~= nil then
        t = LegendsOfDotaPlugin:SeekPrefixValues(LegendsOfDotaPlugin.npc_abilities[sAbility].AbilitySpecial,"special_bonus_unique_")
        t = LegendsOfDotaPlugin:SeekPrefixKeys(LegendsOfDotaPlugin.npc_abilities[sAbility].AbilitySpecial,"special_bonus_unique_",t)
    end
    return t
end
function LegendsOfDotaPlugin:FindLinkedAbilities(sAbility,sPrefix)
    local t = {}
    if LegendsOfDotaPlugin.npc_abilities[sAbility] == nil then return {} end
    if LegendsOfDotaPlugin.npc_abilities[sAbility].ad_linked_abilities ~= nil then
        table.insert(t,LegendsOfDotaPlugin.npc_abilities[sAbility].ad_linked_abilities)
    end
    if LegendsOfDotaPlugin.npc_abilities[sAbility].AbilitySpecial then
        local sValue = LegendsOfDotaPlugin:SeekKey(t,"ad_linked_abilities")
        if sValue ~= nil then
            if (sPrefix ~= nil and string.starts(sValue,sPrefix)) or sPrefix == nil then
                table.insert(t,sValue)
            end
        end
    end
    for k,v in pairs(LegendsOfDotaPlugin.npc_abilities) do
        if v ~= nil and type(v) == 'table' then
            if v.AbilityDraftUltScepterAbility and v.AbilityDraftUltScepterAbility == sAbility then
                if (sPrefix ~= nil and string.starts(k,sPrefix)) or sPrefix == nil then
                    table.insert(t,k)
                end
            end
            if v.AbilityDraftScepterAbility and v.AbilityDraftScepterAbility == sAbility then
                if (sPrefix ~= nil and string.starts(k,sPrefix)) or sPrefix == nil then
                    table.insert(t,k)
                end
            end
            if v.AbilityDraftUltShardAbility and v.AbilityDraftUltShardAbility == sAbility then
                if (sPrefix ~= nil and string.starts(k,sPrefix)) or sPrefix == nil then
                    table.insert(t,k)
                end
            end
            if v.AbilityDraftPreAbility and v.AbilityDraftPreAbility == sAbility then
                if (sPrefix ~= nil and string.starts(k,sPrefix)) or sPrefix == nil then
                    table.insert(t,k)
                end
            end
            if LegendsOfDotaPlugin:SeekKey(v.AbilityValues,sAbility) ~= nil then
                if (sPrefix ~= nil and string.starts(k,sPrefix)) or sPrefix == nil then
                    table.insert(t,k)
                end
            end
            if LegendsOfDotaPlugin:SeekValue(v.AbilitySpecial,sAbility) ~= nil then
                if (sPrefix ~= nil and string.starts(k,sPrefix)) or sPrefix == nil then
                    table.insert(t,k)
                end
            end
        end
    end
    return t
end

function LegendsOfDotaPlugin:SeekValue(t,str)
    if t == nil then return nil end
    for k,v in pairs(t) do
        if v ~= nil and type(v) == 'table' then
            local bFound = LegendsOfDotaPlugin:SeekValue(v,str)
            if bFound then return k end
        else
            if type(v) == 'string' then
                if str == v then
                    return k
                end
            end
        end
    end
    return nil
end
function LegendsOfDotaPlugin:SeekKey(t,str)
    if t == nil then return nil end
    for k,v in pairs(t) do
        if k == str then return v end
        if v ~= nil and type(v) == 'table' then
            local value = LegendsOfDotaPlugin:SeekKey(v,str)
            if value then return value end
        end
    end
    return nil
end

function LegendsOfDotaPlugin:SeekPrefixKeys(t,str,_t)
    if _t == nil then _t = {} end
    if t == nil then return _t end
    for k,v in pairs(t) do
        if string.starts(k,str) then
            table.insert(_t,k)
        elseif v ~= nil and type(v) == 'table' then
            _t = LegendsOfDotaPlugin:SeekPrefixKeys(v,str,_t)
        end
    end
    return _t
end

function LegendsOfDotaPlugin:SeekPrefixValues(t,str,_t)
    if _t == nil then _t = {} end
    if t == nil then return _t end
    for k,v in pairs(t) do
        if v ~= nil and type(v) == 'table' then
            _t = LegendsOfDotaPlugin:SeekPrefixValues(v,str,_t)
        else
            if type(v) == 'string' then
                if string.starts(v,str) then
                    table.insert(_t,v)
                end
            end
        end
    end
    return _t
end




--[[ "ability_pick"
{
    "name" "string"
    "category" "string"
    "slot" "short"
} ]]
function LegendsOfDotaPlugin:ability_pick(tEvent)
    local iPlayer = tEvent.PlayerID
    if LegendsOfDotaPlugin.player_data[iPlayer] == nil then
        LegendsOfDotaPlugin.player_data[iPlayer] = {}
    end
    if LegendsOfDotaPlugin.player_data[iPlayer].ready then return end
    if LegendsOfDotaPlugin.player_data[iPlayer].abilities == nil then
        LegendsOfDotaPlugin.player_data[iPlayer].abilities = {}
    end
    local tReturn = {
        name= tEvent.name,
        category= tEvent.category,
        slot= tEvent.slot
    }

    for k,v in pairs(LegendsOfDotaPlugin.player_data[iPlayer].abilities) do
        if v.name == tEvent.name then
            tReturn.name = "failure"
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer ~= nil then
                CustomGameEventManager:Send_ServerToPlayer(hPlayer,"ability_pick",tReturn)
            end
            return
        end
    end

    if not LegendsOfDotaPlugin:TestDummy(tEvent.name) then
        tReturn.name = "failure"
    else
        LegendsOfDotaPlugin.player_data[iPlayer].abilities["s"..tEvent.slot] = {
            category = tEvent.category,
            name = tEvent.name,
            slot = tEvent.slot
        }
        CustomNetTables:SetTableValue("heroselection_rework", "player_data", LegendsOfDotaPlugin.player_data)
    end

    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer ~= nil then
        CustomGameEventManager:Send_ServerToPlayer(hPlayer,"ability_pick",tReturn)
    end
end

--[[ "hero_pick"
{
    "hero" "short"
} ]]
function LegendsOfDotaPlugin:hero_pick(tEvent)
    local iPlayer = tEvent.PlayerID
    if LegendsOfDotaPlugin.player_data[iPlayer] == nil then
        LegendsOfDotaPlugin.player_data[iPlayer] = {}
    end
    if LegendsOfDotaPlugin.player_data[iPlayer].ready then return end
    LegendsOfDotaPlugin.player_data[iPlayer].hero = tEvent.hero

    if LegendsOfDotaPlugin.settings.pick_mode == "lod" then
        --do nothing
    elseif LegendsOfDotaPlugin.settings.pick_mode == "random" then
        LegendsOfDotaPlugin:RandomBuild(GetSystemTimeMS() .. iPlayer .. iPlayer,iPlayer)
    elseif LegendsOfDotaPlugin.settings.pick_mode == "steamid" then
        LegendsOfDotaPlugin:RandomBuild(Toolbox:GetSteamID(iPlayer) .. tEvent.hero,iPlayer)
    elseif LegendsOfDotaPlugin.settings.pick_mode == "steamid_daily" then
        LegendsOfDotaPlugin:RandomBuild(Toolbox:GetSteamID(iPlayer) .. GetSystemDate() .. tEvent.hero,iPlayer)
    elseif LegendsOfDotaPlugin.settings.pick_mode == "steamid_monthly" then
        local moth = string.gsub(GetSystemDate(), "/(.*)/", "XX")
        print(moth)
        LegendsOfDotaPlugin:RandomBuild(Toolbox:GetSteamID(iPlayer) .. moth .. tEvent.hero,iPlayer)
    end
    CustomNetTables:SetTableValue("heroselection_rework", "player_data", LegendsOfDotaPlugin.player_data)
end

--[[ "player_ready"
{
} ]]
function LegendsOfDotaPlugin:player_ready(tEvent)
    local iPlayer = tEvent.PlayerID
    if LegendsOfDotaPlugin.player_data[iPlayer] == nil then
        LegendsOfDotaPlugin.player_data[iPlayer] = {}
    end
    LegendsOfDotaPlugin.player_data[iPlayer].ready = true
    CustomNetTables:SetTableValue("heroselection_rework", "player_data", LegendsOfDotaPlugin.player_data)

    LegendsOfDotaPlugin:CheckAllReady()
end


function LegendsOfDotaPlugin:CheckAllReady()
    local c = 0
    local b = 0
	for iPlayer=0,DOTA_MAX_PLAYERS do
		if (PlayerResource:IsValidPlayer(iPlayer)) then
            if LegendsOfDotaPlugin.player_data[iPlayer] == nil then
                LegendsOfDotaPlugin.player_data[iPlayer] = {}
            end
            if LegendsOfDotaPlugin.player_data[iPlayer].ready == nil then
                LegendsOfDotaPlugin.player_data[iPlayer].ready = false
            end
            c = c + 1
            if LegendsOfDotaPlugin.player_data[iPlayer].ready then
                b = b +1
            end
		end
	end
    if c == b then
        LegendsOfDotaPlugin:FinalizeHeroes()
        local gm = GameRules:GetGameModeEntity()
        GameRules:SetHeroSelectionTime(0)
        GameRules:SetHeroSelectPenaltyTime(0)
        GameRules:SetStrategyTime(30)
        gm:SetDraftingBanningTimeOverride(0)
        gm:SetDraftingHeroPickSelectTimeOverride(0)
        LegendsOfDotaPlugin:DestroyTestDummy()
        return true
    else
        return false
    end
end


function LegendsOfDotaPlugin:FinalizeHeroes()
	for iPlayer=0,DOTA_MAX_PLAYERS do
		if (PlayerResource:IsValidPlayer(iPlayer)) then
            LegendsOfDotaPlugin:FinalizeHero(iPlayer)
		end
	end
end


function LegendsOfDotaPlugin:FinalizeHero(iPlayer)
    if LegendsOfDotaPlugin.player_data[iPlayer] == nil then
        return
    end
    if LegendsOfDotaPlugin.player_data[iPlayer].hero == nil then
        return
    end
    if type(LegendsOfDotaPlugin.player_data[iPlayer].hero) ~= 'number' then
        return
    end

    local sHero = DOTAGameManager:GetHeroNameByID(LegendsOfDotaPlugin.player_data[iPlayer].hero)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    hPlayer:SetSelectedHero(sHero)
end


function LegendsOfDotaPlugin:SpawnEvent(event)
    Timers:CreateTimer(0.01,function()
        local hUnit = EntIndexToHScript(event.entindex)
        if not hUnit:IsDOTANPC() then return end
        if not hUnit:IsHero() then return end
        if hUnit:IsRealHero() then
            if LegendsOfDotaPlugin.cache[event.entindex] ~= nil then return end
            LegendsOfDotaPlugin.cache[event.entindex] = 1
            local iPlayer = hUnit:GetPlayerID()
            if iPlayer < 0 then return end
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer == nil then return end
            local hMainHero = hPlayer:GetAssignedHero()
            if hMainHero == hUnit then
                LegendsOfDotaPlugin:ApplyHeroBuild(hUnit,iPlayer)
                return
            end
        end
        local hSource = hUnit:GetReplicatingOtherHero()
        if hSource ~= nil then
            local iPlayer = hSource:GetPlayerID()
            LegendsOfDotaPlugin:ApplyHeroBuild(hUnit,iPlayer)
        end
    end)
end

function LegendsOfDotaPlugin:ApplyHeroBuild(hUnit,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hMainHero = hPlayer:GetAssignedHero()
    if hMainHero == nil then return end

    if LegendsOfDotaPlugin.player_data[iPlayer] == nil then
        return
    end
    if LegendsOfDotaPlugin.player_data[iPlayer].abilities == nil then
        return
    end
    for k,v in pairs(LegendsOfDotaPlugin.player_data[iPlayer].abilities) do
        local sAbility = v.name
        local sCategory = v.category
        local iSlot = v.slot
        if LegendsOfDotaPlugin.no_duplication[sAbility] == nil or hMainHero == hUnit then
            if (sCategory == "talent") then
                LegendsOfDotaPlugin:ReplaceTalent(hUnit,sAbility,0,iSlot-1)
            else
                LegendsOfDotaPlugin:ReplaceAbility(hUnit,sAbility,0,iSlot-1,true)
            end
        end
    end

    if hUnit ~= hMainHero then
    local i = 0
    while (i < DOTA_MAX_ABILITIES) do
            local hOriginalAbility = hMainHero:GetAbilityByIndex(i)
            local hAbility = hUnit:GetAbilityByIndex(i)
            if hAbility and hOriginalAbility and hOriginalAbility:GetAbilityName() == hAbility:GetAbilityName() then
                if hOriginalAbility:GetLevel() > 0 then
                    hAbility:SetLevel(hOriginalAbility:GetLevel())
                end
            end
            i = i + 1
        end
    end
end

function LegendsOfDotaPlugin:ReplaceTalent(hUnit,sAbility,iLevel,iSlot)
    iSlot = iSlot - 6
    local i = 0
    local iTalentStart = 0
    while (iTalentStart == 0 and i < DOTA_MAX_ABILITIES) do
        local hAbility = hUnit:GetAbilityByIndex(i)
        local sOldAbility = hAbility:GetAbilityName()
        if Toolbox:string_starts(sOldAbility,"special_bonus_") then
            iTalentStart = i
        end
        i = i + 1
    end
    if iTalentStart == 0 then return true end
    iSlot = iTalentStart + iSlot
    print(iSlot,sAbility)
    local hOldAbility = hUnit:GetAbilityByIndex(iSlot)
    if hOldAbility then
        hUnit:RemoveAbilityByHandle(hOldAbility)
    end
    local hAbility = hUnit:AddAbility(sAbility)
    if hAbility ~= nil then
        local sMod = hAbility:GetIntrinsicModifierName()
        if sMod then
            local tMods = hUnit:FindAllModifiersByName(sMod)
            for i=1,#tMods do
                if tMods[i]:GetAbility() == hAbility then
                    tMods[i]:Destroy()
                end
            end
        end
    else
        return false
    end
    return true
end

function LegendsOfDotaPlugin:ReplaceAbility(hUnit,sAbility,iLevel,iSlot,bForce)
    local i = 0
    local iTalentStart = 0
    while (iTalentStart == 0 and i < DOTA_MAX_ABILITIES) do
        local hAbility = hUnit:GetAbilityByIndex(i)
        local sOldAbility = hAbility:GetAbilityName()
        if Toolbox:string_starts(sOldAbility,"special_bonus_") then
            iTalentStart = i
        end
        i = i + 1
    end
    if iSlot > iTalentStart-1 and iSlot < iTalentStart+9 then
        print("original slot",iSlot)
        iSlot = iSlot - (iTalentStart-(iTalentStart-9))
    end
    print(iSlot,sAbility)
    local hOldAbility = hUnit:GetAbilityByIndex(iSlot)
    local sOldAbility
    if hOldAbility ~= nil then 
        sOldAbility = hOldAbility:GetAbilityName()
        hUnit:RemoveAbilityByHandle(hOldAbility)
    end
    local hAbility = hUnit:AddAbility(sAbility)
    if hAbility ~= nil then
        if iLevel > 0 then
            hAbility:SetLevel(iLevel)
        else
            local sMod = hAbility:GetIntrinsicModifierName()
            if sMod then
                local tMods = hUnit:FindAllModifiersByName(sMod)
                for i=1,#tMods do
                    if tMods[i]:GetAbility() == hAbility then
                        tMods[i]:Destroy()
                    end
                end
            end
        end
        if bForce then
            hAbility:SetActivated(true)
            hAbility:SetHidden(false)
        end
        if hAbility:GetAutoCastState() then
            hAbility:ToggleAutoCast()
        end
    end
end


function LegendsOfDotaPlugin:SpawnTestDummy()
    LegendsOfDotaPlugin.test_dummy_attempts = 0
    CreateUnitByNameAsync( "npc_dota_hero_target_dummy", Vector(0,0,0), false, nil, nil, DOTA_TEAM_NEUTRALS,function(hDummy)
        LegendsOfDotaPlugin.test_dummy = hDummy
        print("dummy spawned!")
    end)
end
function LegendsOfDotaPlugin:DestroyTestDummy()
    if LegendsOfDotaPlugin.test_dummy == nil then return end
    LegendsOfDotaPlugin.test_dummy:Destroy()
end
function LegendsOfDotaPlugin:TestDummy(sAbility)
    print(sAbility)
    LegendsOfDotaPlugin.test_dummy_attempts = LegendsOfDotaPlugin.test_dummy_attempts + 1
    if LegendsOfDotaPlugin.test_dummy == nil then
        print("no test dummy found")
        return true
    end
    local hAbility = LegendsOfDotaPlugin.test_dummy:AddAbility(sAbility)
    print("adding ablity to " .. LegendsOfDotaPlugin.test_dummy:GetUnitName())
    if hAbility ~= nil then
        print("it was success!")
        LegendsOfDotaPlugin.test_dummy:RemoveAbilityByHandle(hAbility)
        print("removing...")
        if (LegendsOfDotaPlugin.test_dummy_attempts > 10) then
            LegendsOfDotaPlugin:DestroyTestDummy()
            LegendsOfDotaPlugin:SpawnTestDummy()
        end
        return true
    end
    print("it was failure!")
    return false
end

function LegendsOfDotaPlugin:ForceHeroes()
    if LegendsOfDotaPlugin:CheckAllReady() then return end
    LegendsOfDotaPlugin:FinalizeHeroes()
    local gm = GameRules:GetGameModeEntity()
    GameRules:SetHeroSelectionTime(0)
    GameRules:SetHeroSelectPenaltyTime(0)
    GameRules:SetStrategyTime(30)
    gm:SetDraftingBanningTimeOverride(0)
    gm:SetDraftingHeroPickSelectTimeOverride(0)
    LegendsOfDotaPlugin:DestroyTestDummy()
end


function LegendsOfDotaPlugin:ExportBanList(tArgs,bTeam,iPlayer)
    local str = "{\"ban_list\":{\n"
    for k,v in pairs(HeroBuilderPlugin.ban_list) do
        str = str .. "\t\"" .. k .. "\": 1\n"
    end
    str = str .. "}}"
    CustomGameEventManager:Send_ServerToAllClients("ban_list_export",{list = str})
    print(str)
end



function LegendsOfDotaPlugin:RandomBuild(sSeed,iPlayer)
    if LegendsOfDotaPlugin.player_data[iPlayer].abilities == nil then
        LegendsOfDotaPlugin.player_data[iPlayer].abilities = {}
    end
    local tMainBuild = {}
    local tTalentBuild = {}
    local bFound = false
    Timers:CreateTimer(0.1,function()
        for i=1,5 do
            bFound = false
            local tAbility
            while(not bFound) do
                tAbility = LegendsOfDotaPlugin:RandomAbility(sSeed,iPlayer,"basic")
                if not Toolbox:ContainsSubValue(tMainBuild,name,tAbility.name) then
                    if LegendsOfDotaPlugin:TestDummy(tAbility.name) then
                        bFound = true
                    end
                end
            end
            table.insert(tMainBuild,tAbility)
            LegendsOfDotaPlugin:BuildAddAbility(iPlayer,{
                category = "basic",
                name = tAbility.name,
                slot = (i)
            })
        end
    end)
    --add ult
    Timers:CreateTimer(0.2,function()
        bFound = false
        local tAbility
        while(not bFound) do
            tAbility = LegendsOfDotaPlugin:RandomAbility(sSeed,iPlayer,"ultimate")
            if not Toolbox:ContainsSubValue(tMainBuild,name,tAbility.name) then
                if LegendsOfDotaPlugin:TestDummy(tAbility.name) then
                    bFound = true
                end
            end
        end
        table.insert(tMainBuild,tAbility)
        LegendsOfDotaPlugin:BuildAddAbility(iPlayer,{
            category = "ultimate",
            name = tAbility.name,
            slot = (6)
        })
    end)
    
    --find all linked
    Timers:CreateTimer(0.3,function()
        local tLinked = {}
        for k,v in pairs(tMainBuild) do
            local sAbility = v.name
            local _t = LegendsOfDotaPlugin:FindLinkedTalents(sAbility)
            for _k,_v in pairs(_t) do
                table.insert(tLinked,_v)
            end
        end
        for i=1,8 do
            if #tLinked >= i then
                table.insert(tTalentBuild,tLinked[i])
                LegendsOfDotaPlugin:BuildAddAbility(iPlayer,{
                    category = "talent",
                    name = tLinked[i],
                    slot = (6+i)
                })
            else
                bFound = false
                while(not bFound) do
                    tAbility = LegendsOfDotaPlugin:RandomAbility(sSeed,iPlayer,"talent")
                    if (tAbility.name ~= nil and type(tAbility.name) == "string") then
                        if not Toolbox:ContainsValue(tTalentBuild,tAbility.name) then
                            if not string.starts(tAbility.name,"special_bonus_unique_") then
                                if string.starts(tAbility.name,"special_bonus_") then
                                    bFound = true
                                end
                            end
                        end
                    end
                end
                table.insert(tTalentBuild,tAbility.name)
                LegendsOfDotaPlugin:BuildAddAbility(iPlayer,{
                    category = "talent",
                    name = tAbility.name,
                    slot = (6+i)
                })
            end
        end
    end)
    
    Timers:CreateTimer(0.5,function()
    LegendsOfDotaPlugin:player_ready({PlayerID = iPlayer})
end)
end

function LegendsOfDotaPlugin:RandomAbility(sSeed,iPlayer,sCategory)
    local tAbility
    local iTries = 0
    while(tAbility == nil and iTries < 5000) do
        local keyAbility = Toolbox:GetSRandomKey(sSeed,LegendsOfDotaPlugin.ability_pools_sorted)
        if keyAbility ~= nil and LegendsOfDotaPlugin.ability_pools_sorted[keyAbility].category == sCategory then
            tAbility = LegendsOfDotaPlugin.ability_pools_sorted[keyAbility]
        end
        iTries = iTries + 1
    end
    return tAbility
end


function LegendsOfDotaPlugin:BuildAddAbility(iPlayer,tEvent)
    LegendsOfDotaPlugin.player_data[iPlayer].abilities["s"..tEvent.slot] = {
        category = tEvent.category,
        name = tEvent.name,
        slot = tEvent.slot
    }
end