HeroScreenReworkPlugin = class({})
_G.HeroScreenReworkPlugin = HeroScreenReworkPlugin
local JSON = require("utils/dkjson")
HeroScreenReworkPlugin.settings = {}

HeroScreenReworkPlugin.heroes = {}
HeroScreenReworkPlugin.npc_abilities = {}
HeroScreenReworkPlugin.npc_abilities_custom = {}
HeroScreenReworkPlugin.no_duplication = {}
HeroScreenReworkPlugin.ban_list = {}

HeroScreenReworkPlugin.player_build = {}

HeroScreenReworkPlugin.ability_pools = {}
HeroScreenReworkPlugin.hero_definitions = {}

HeroScreenReworkPlugin.player_data = {}

function HeroScreenReworkPlugin:Init()
    print("[HeroScreenReworkPlugin] found")
end

function HeroScreenReworkPlugin:ApplySettings()
    HeroScreenReworkPlugin.settings = PluginSystem:GetAllSetting("heroscreen_rework")
	local gm = GameRules:GetGameModeEntity()
    GameRules:SetHeroSelectionTime(10*60)
    GameRules:SetHeroSelectPenaltyTime(0)
    GameRules:SetStrategyTime(30)
	gm:SetDraftingBanningTimeOverride(0)
	gm:SetDraftingHeroPickSelectTimeOverride(10*60)
    HeroScreenReworkPlugin:LoadHeroes()
    HeroScreenReworkPlugin:LoadAbilities()
    CustomGameEventManager:RegisterListener("hero_pick",HeroScreenReworkPlugin.hero_pick)
    CustomGameEventManager:RegisterListener("ability_pick",HeroScreenReworkPlugin.ability_pick)
    CustomGameEventManager:RegisterListener("player_ready",HeroScreenReworkPlugin.player_ready)
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            HeroScreenReworkPlugin:SpawnEvent(event)
    end,nil)
    HeroScreenReworkPlugin:SpawnTestDummy()
end

function HeroScreenReworkPlugin:LoadHeroes()
    HeroScreenReworkPlugin.heroes = {
        {},		-- strength_heroes
        {},		-- agility_heroes
        {},		-- intelligence_heroes
        {}		-- universal
    }
    HeroScreenReworkPlugin.hero_definitions = LoadKeyValues('scripts/npc/npc_heroes.txt')
    local process_hero = function(hero_data,hero_name)
        if hero_data.Enabled ~= 1 then return end
        local hero_attribute = _G[hero_data.AttributePrimary]
        local attribute = hero_attribute + 1
        local tHero = {
            name = hero_name,
            banned = false,
            id = hero_data.HeroID,
        }
        table.insert(HeroScreenReworkPlugin.heroes[attribute], tHero)
    end
    for hero_name,_ in pairs(HeroScreenReworkPlugin.hero_definitions) do
        if (type(HeroScreenReworkPlugin.hero_definitions[hero_name]) == "table") then
            if HeroScreenReworkPlugin.hero_definitions[hero_name].HeroID ~= nil then
                process_hero(HeroScreenReworkPlugin.hero_definitions[hero_name],hero_name)
            end
        end
    end
    
    
    CustomNetTables:SetTableValue("heroselection_rework", "hero_pools", HeroScreenReworkPlugin.heroes)
end


function HeroScreenReworkPlugin:LoadAbilities()
	local file = LoadKeyValues('scripts/npc/npc_abilities.txt')
    if not (file == nil or not next(file)) then
        HeroScreenReworkPlugin.npc_abilities = file
    end
	local file_custom = LoadKeyValues('scripts/npc/npc_abilities_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        HeroScreenReworkPlugin.npc_abilities_custom = file_custom
    end
	local no_duplication = LoadKeyValues('scripts/vscripts/plugin_system/plugins/hero_builder/no_duplication.txt')
    if not (no_duplication == nil or not next(no_duplication)) then
        HeroScreenReworkPlugin.no_duplication = no_duplication
    end
	local ban_list = LoadKeyValues('scripts/vscripts/plugin_system/plugins/hero_builder/ban_list.txt')
    if not (ban_list == nil or not next(ban_list)) then
        HeroScreenReworkPlugin.ban_list = ban_list
    end
--[[     if string.len(HeroScreenReworkPlugin.settings.custom_bans) > 1 and string.len(HeroScreenReworkPlugin.settings.custom_bans) < 20 then
        HeroScreenReworkPlugin:LoadBanList(HeroScreenReworkPlugin.settings.custom_bans)
    else ]]
        HeroScreenReworkPlugin:PrepStageTwo()
--[[     end ]]
end

function HeroScreenReworkPlugin:AllDonePreping()
    for k,v in pairs(HeroScreenReworkPlugin.ability_pools) do
        CustomNetTables:SetTableValue("heroselection_rework_abilities", k, v)
    end
    DeepPrintTable(HeroScreenReworkPlugin.ability_pools)
end

function HeroScreenReworkPlugin:LoadBanList(pastebin)
    local url = "https://pastebin.com/raw/" .. pastebin
    local req = CreateHTTPRequestScriptVM("GET", url)
    req:Send(function(res)
        if res.StatusCode ~= 200 then
            print(res.Body)
            print("something went wrong")
        else
            print(res.Body)
			local data = JSON.decode(res.Body)
            HeroScreenReworkPlugin.ban_list = data.ban_list
        end
        HeroScreenReworkPlugin:PrepStageTwo()
    end)
end

function HeroScreenReworkPlugin:PrepStageTwo()
    --if HeroScreenReworkPlugin.settings.dota_abilities then
        for k,v in pairs(HeroScreenReworkPlugin.npc_abilities) do
            if v ~= nil and type(v) == 'table' then
                if v.AbilityType ~= nil then
                    if v.AbilityType == "DOTA_ABILITY_TYPE_ATTRIBUTES" then
                        HeroScreenReworkPlugin:AddTalent(k,v)
                    elseif v.AbilityType == "DOTA_ABILITY_TYPE_ULTIMATE" then
                        HeroScreenReworkPlugin:AddUltimate(k,v)
                    else
                        HeroScreenReworkPlugin:AddBasic(k,v)
                    end
                else
                    HeroScreenReworkPlugin:AddBasic(k,v)
                end
            end 
        end
    --end
    --if HeroScreenReworkPlugin.settings.custom_abilities then
        for k,v in pairs(HeroScreenReworkPlugin.npc_abilities_custom) do
            if v ~= nil and type(v) == 'table' then
                if HeroScreenReworkPlugin.npc_abilities[k] == nil then
                    if v.CustomEnabled ~= nil then
                        if v.AbilityType ~= nil then
                            if v.AbilityType == "DOTA_ABILITY_TYPE_ATTRIBUTES" then
                                HeroScreenReworkPlugin:AddTalent(k,v)
                            elseif v.AbilityType == "DOTA_ABILITY_TYPE_ULTIMATE" then
                                HeroScreenReworkPlugin:AddUltimate(k,v)
                            else
                                HeroScreenReworkPlugin:AddBasic(k,v)
                            end
                        else
                            HeroScreenReworkPlugin:AddBasic(k,v)
                        end
                    end
                end
            end 
        end
    --end
    HeroScreenReworkPlugin:AllDonePreping()
end


function HeroScreenReworkPlugin:AddTalent(sAbility,data)
    if HeroScreenReworkPlugin.ban_list[sAbility] == nil then
        local sOwner = HeroScreenReworkPlugin:FindHeroTalentOwner(sAbility)
        if HeroScreenReworkPlugin.ability_pools[sOwner] == nil then
            HeroScreenReworkPlugin.ability_pools[sOwner] = {}
        end
        while (#HeroScreenReworkPlugin.ability_pools[sOwner] > 30) do
            sOwner = sOwner .. "_e"
            if HeroScreenReworkPlugin.ability_pools[sOwner] == nil then
                HeroScreenReworkPlugin.ability_pools[sOwner] = {}
            end
        end
        local t = {
            name = sAbility,
            category = "talent",
            linked = HeroScreenReworkPlugin:FindLinkedAbilities(sAbility),
        }
        table.insert(HeroScreenReworkPlugin.ability_pools[sOwner],t)
    end
end

function HeroScreenReworkPlugin:AddBasic(sAbility,data)
    if HeroScreenReworkPlugin.ban_list[sAbility] == nil then
        local sOwner = HeroScreenReworkPlugin:FindHeroAbilityOwner(sAbility)
        if HeroScreenReworkPlugin.ability_pools[sOwner] == nil then
            HeroScreenReworkPlugin.ability_pools[sOwner] = {}
        end
        local t = {
            name = sAbility,
            category = "basic",
            linked = HeroScreenReworkPlugin:FindLinkedAbilities(sAbility),
        }
        table.insert(HeroScreenReworkPlugin.ability_pools[sOwner],t)
    end
end

function HeroScreenReworkPlugin:AddUltimate(sAbility,data)
    if HeroScreenReworkPlugin.ban_list[sAbility] == nil then
        local sOwner = HeroScreenReworkPlugin:FindHeroAbilityOwner(sAbility)
        if HeroScreenReworkPlugin.ability_pools[sOwner] == nil then
            HeroScreenReworkPlugin.ability_pools[sOwner] = {}
        end
        local t = {
            name = sAbility,
            category = "ultimate",
            linked = HeroScreenReworkPlugin:FindLinkedAbilities(sAbility),
        }
        table.insert(HeroScreenReworkPlugin.ability_pools[sOwner],t)
    end
end

function HeroScreenReworkPlugin:FindHeroAbilityOwner(sAbility)
    for k,v in pairs(HeroScreenReworkPlugin.hero_definitions) do
        if type(v) == "table" then
            for i=1,25 do
                if v["Ability" .. i] ~= nil and v["Ability" .. i] == sAbility then
                    if string.starts(k,"npc_dota_hero_") then
                        return "1_" .. string.sub(k,string.len("npc_dota_hero_")+1)
                    else
                        return k
                    end
                end
            end
            if string.find(sAbility,k) then
                return k
            end
        end
    end
    return Toolbox:split(sAbility,"_")[1]
end

function HeroScreenReworkPlugin:FindHeroTalentOwner(sAbility)
    if string.starts(sAbility,"special_bonus_unique_") then
        return HeroScreenReworkPlugin:FindHeroAbilityOwner(sAbility)
    end
    return "zz_generic_talent"
end


function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end
 
function HeroScreenReworkPlugin:FindLinkedAbilities(sAbility)
    local t = {}
    if HeroScreenReworkPlugin.npc_abilities[sAbility] == nil then return "none" end
    if HeroScreenReworkPlugin.npc_abilities[sAbility].ad_linked_abilities ~= nil then
        table.insert(t,HeroScreenReworkPlugin.npc_abilities[sAbility].ad_linked_abilities)
    end
    if HeroScreenReworkPlugin.npc_abilities[sAbility].AbilitySpecial then
        local sValue = HeroScreenReworkPlugin:SeekKey(t,"ad_linked_abilities")
        if sValue ~= nil then
            table.insert(t,sValue)
        end
    end
    for k,v in pairs(HeroScreenReworkPlugin.npc_abilities) do
        if v ~= nil and type(v) == 'table' then
            if v.AbilityDraftUltScepterAbility and v.AbilityDraftUltScepterAbility == sAbility then
                table.insert(t,k)
            end
            if v.AbilityDraftScepterAbility and v.AbilityDraftScepterAbility == sAbility then
                table.insert(t,k)
            end
            if v.AbilityDraftUltShardAbility and v.AbilityDraftUltShardAbility == sAbility then
                table.insert(t,k)
            end
            if v.AbilityDraftPreAbility and v.AbilityDraftPreAbility == sAbility then
                table.insert(t,k)
            end
            if HeroScreenReworkPlugin:SeekKey(v.AbilityValues,sAbility) ~= nil then
                table.insert(t,k)
            end
            if HeroScreenReworkPlugin:SeekValue(v.AbilitySpecial,sAbility) ~= nil then
                table.insert(t,k)
            end
        end
    end
    return t
end

function HeroScreenReworkPlugin:SeekValue(t,str)
    if t == nil then return nil end
    for k,v in pairs(t) do
        if v ~= nil and type(v) == 'table' then
            local bFound = HeroScreenReworkPlugin:SeekValue(v,str)
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
function HeroScreenReworkPlugin:SeekKey(t,str)
    if t == nil then return nil end
    for k,v in pairs(t) do
        if k == str then return v end
        if v ~= nil and type(v) == 'table' then
            local value = HeroScreenReworkPlugin:SeekKey(v,str)
            if value then return value end
        end
    end
    return nil
end




--[[ "ability_pick"
{
    "name" "string"
    "category" "string"
    "slot" "short"
} ]]
function HeroScreenReworkPlugin:ability_pick(tEvent)
    local iPlayer = tEvent.PlayerID
    if HeroScreenReworkPlugin.player_data[iPlayer] == nil then
        HeroScreenReworkPlugin.player_data[iPlayer] = {}
    end
    if HeroScreenReworkPlugin.player_data[iPlayer].abilities == nil then
        HeroScreenReworkPlugin.player_data[iPlayer].abilities = {}
    end
    local tReturn = {
        name= tEvent.name,
        category= tEvent.category,
        slot= tEvent.slot
    }

    for k,v in pairs(HeroScreenReworkPlugin.player_data[iPlayer].abilities) do
        if v.name == tEvent.name then
            tReturn.name = "failure"
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer ~= nil then
                CustomGameEventManager:Send_ServerToPlayer(hPlayer,"ability_pick",tReturn)
            end
            return
        end
    end

    if not HeroScreenReworkPlugin:TestDummy(tEvent.name) then
        tReturn.name = "failure"
    else
        HeroScreenReworkPlugin.player_data[iPlayer].abilities["s"..tEvent.slot] = {
            category = tEvent.category,
            name = tEvent.name,
            slot = tEvent.slot
        }
        CustomNetTables:SetTableValue("heroselection_rework", "player_data", HeroScreenReworkPlugin.player_data)
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
function HeroScreenReworkPlugin:hero_pick(tEvent)
    local iPlayer = tEvent.PlayerID
    if HeroScreenReworkPlugin.player_data[iPlayer] == nil then
        HeroScreenReworkPlugin.player_data[iPlayer] = {}
    end
    HeroScreenReworkPlugin.player_data[iPlayer].hero = tEvent.hero



    CustomNetTables:SetTableValue("heroselection_rework", "player_data", HeroScreenReworkPlugin.player_data)
end

--[[ "player_ready"
{
} ]]
function HeroScreenReworkPlugin:player_ready(tEvent)
    local iPlayer = tEvent.PlayerID
    if HeroScreenReworkPlugin.player_data[iPlayer] == nil then
        HeroScreenReworkPlugin.player_data[iPlayer] = {}
    end
    HeroScreenReworkPlugin.player_data[iPlayer].ready = true
    CustomNetTables:SetTableValue("heroselection_rework", "player_data", HeroScreenReworkPlugin.player_data)

    HeroScreenReworkPlugin:CheckAllReady()
end


function HeroScreenReworkPlugin:CheckAllReady()
    local c = 0
    local b = 0
	for iPlayer=0,DOTA_MAX_PLAYERS do
		if (PlayerResource:IsValidPlayer(iPlayer)) then
            if HeroScreenReworkPlugin.player_data[iPlayer] == nil then
                HeroScreenReworkPlugin.player_data[iPlayer] = {}
            end
            if HeroScreenReworkPlugin.player_data[iPlayer].ready == nil then
                HeroScreenReworkPlugin.player_data[iPlayer].ready = false
            end
            c = c + 1
            if HeroScreenReworkPlugin.player_data[iPlayer].ready then
                b = b +1
            end
		end
	end
    if c == b then
        HeroScreenReworkPlugin:FinalizeHeroes()
    end
	local gm = GameRules:GetGameModeEntity()
    GameRules:SetHeroSelectionTime(0)
    GameRules:SetHeroSelectPenaltyTime(0)
    GameRules:SetStrategyTime(30)
	gm:SetDraftingBanningTimeOverride(0)
	gm:SetDraftingHeroPickSelectTimeOverride(0)
    HeroScreenReworkPlugin:DestroyTestDummy()
end


function HeroScreenReworkPlugin:FinalizeHeroes()
	for iPlayer=0,DOTA_MAX_PLAYERS do
		if (PlayerResource:IsValidPlayer(iPlayer)) then
            HeroScreenReworkPlugin:FinalizeHero(iPlayer)
		end
	end
end


function HeroScreenReworkPlugin:FinalizeHero(iPlayer)
    local sHero = DOTAGameManager:GetHeroNameByID(HeroScreenReworkPlugin.player_data[iPlayer].hero)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    hPlayer:SetSelectedHero(sHero)
end


function HeroScreenReworkPlugin:SpawnEvent(event)
    Timers:CreateTimer(0.01,function()
        local hUnit = EntIndexToHScript(event.entindex)
        if not hUnit:IsDOTANPC() then return end
        if not hUnit:IsHero() then return end
        local hSource = hUnit:GetReplicatingOtherHero()
        if hSource ~= nil then
            local iPlayer = hSource:GetPlayerID()
            HeroScreenReworkPlugin:ApplyHeroBuild(hUnit,iPlayer)
        else
            if not hUnit:IsRealHero() then return end
            if hUnit == nil then return end
            if not hUnit.GetPlayerID then return end
            local iPlayer = hUnit:GetPlayerID()
            if not hUnit:IsHero() then return end
            if iPlayer < 0 then return end
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer == nil then return end
            local hMainHero = hPlayer:GetAssignedHero()
            if hMainHero == hUnit then
                HeroScreenReworkPlugin:ApplyHeroBuild(hUnit,iPlayer)
            end
        end
    end)
end

function HeroScreenReworkPlugin:ApplyHeroBuild(hUnit,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hMainHero = hPlayer:GetAssignedHero()
    if hMainHero == nil then return end

    if HeroScreenReworkPlugin.player_data[iPlayer] == nil then
        return
    end
    if HeroScreenReworkPlugin.player_data[iPlayer].abilities == nil then
        return
    end
    for k,v in pairs(HeroScreenReworkPlugin.player_data[iPlayer].abilities) do
        local sAbility = v.name
        local sCategory = v.category
        local iSlot = v.slot
        if HeroScreenReworkPlugin.no_duplication[sAbility] == nil or hMainHero == hUnit then
            if (sCategory == "talent") then
                HeroScreenReworkPlugin:ReplaceTalent(hUnit,sAbility,0,iSlot-1)
            else
                HeroScreenReworkPlugin:ReplaceAbility(hUnit,sAbility,0,iSlot-1,true)
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

function HeroScreenReworkPlugin:ReplaceTalent(hUnit,sAbility,iLevel,iSlot)
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
    if iSlot < iTalentStart then iSlot = iTalentStart end
    if iSlot > iTalentStart+7 then iSlot = iTalentStart+7 end
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

function HeroScreenReworkPlugin:ReplaceAbility(hUnit,sAbility,iLevel,iSlot,bForce)
    local i = 0
    local iSkip = -1
    while (iSkip == -1 and i < DOTA_MAX_ABILITIES) do
        local hAbility = hUnit:GetAbilityByIndex(i)
        local sOldAbility = hAbility:GetAbilityName()
        if not Toolbox:string_starts(sOldAbility,"special_bonus_") then
            iSkip = i
        end
        i = i + 1
    end
    local hOldAbility = hUnit:GetAbilityByIndex(iSkip+iSlot)
    local sOldAbility
    if hOldAbility ~= nil then 
        sOldAbility = hOldAbility:GetAbilityName()
        if Toolbox:string_starts(sOldAbility,"special_bonus_") then
            return true
        end

        if hOldAbility then
            hUnit:RemoveAbilityByHandle(hOldAbility)
        end
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


function HeroScreenReworkPlugin:SpawnTestDummy()
    CreateUnitByNameAsync( "npc_dota_hero_target_dummy", Vector(0,0,0), false, nil, nil, DOTA_TEAM_NEUTRALS,function(hDummy)
        HeroScreenReworkPlugin.test_dummy = hDummy
        print("dummy spawned!")
    end)
end
function HeroScreenReworkPlugin:DestroyTestDummy()
    if HeroScreenReworkPlugin.test_dummy == nil then return end
    HeroScreenReworkPlugin.test_dummy:Destroy()
end
function HeroScreenReworkPlugin:TestDummy(sAbility)
    if HeroScreenReworkPlugin.test_dummy == nil then
        print("no test dummy found")
        return true
    end
    local hAbility = HeroScreenReworkPlugin.test_dummy:AddAbility(sAbility)
    print("adding ablity to " .. HeroScreenReworkPlugin.test_dummy:GetUnitName())
    if hAbility ~= nil then
        print("it was success!")
        HeroScreenReworkPlugin.test_dummy:RemoveAbilityByHandle(hAbility)
        print("removing...")
        return true
    end
    print("it was failure!")
    return false
end