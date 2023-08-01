HeroBuilderPlugin = class({})
_G.HeroBuilderPlugin = HeroBuilderPlugin
local JSON = require("utils/dkjson")
HeroBuilderPlugin.npc_abilities = {}
HeroBuilderPlugin.npc_abilities_custom = {}
HeroBuilderPlugin.no_duplication = {}
HeroBuilderPlugin.ban_list = {}

HeroBuilderPlugin.player_build = {}
HeroBuilderPlugin.cache = {}
HeroBuilderPlugin.player_hero_cache = {}
HeroBuilderPlugin.unit_cache = {}


HeroBuilderPlugin.available_abilities = {
    talent = {},
    basic = {},
    ultimate = {}
}

HeroBuilderPlugin.available_abilities_pages = {
    talent = 1,
    basic = 1,
    ultimate = 1
}

HeroBuilderPlugin.settings = {
}

function HeroBuilderPlugin:Init()
    print("[HeroBuilderPlugin] found")
end

function HeroBuilderPlugin:PreGameStuff()
    HeroBuilderPlugin.settings = PluginSystem:GetAllSetting("hero_builder")
-- GameRules:SetGameTimeFrozen(true)
	local file = LoadKeyValues('scripts/npc/npc_abilities.txt')
    if not (file == nil or not next(file)) then
        HeroBuilderPlugin.npc_abilities = file
    end
	local file_custom = LoadKeyValues('scripts/npc/npc_abilities_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        HeroBuilderPlugin.npc_abilities_custom = file_custom
    end
	local no_duplication = LoadKeyValues('scripts/vscripts/plugin_system/plugins/hero_builder/no_duplication.txt')
    if not (no_duplication == nil or not next(no_duplication)) then
        HeroBuilderPlugin.no_duplication = no_duplication
    end
	local ban_list = LoadKeyValues('scripts/vscripts/plugin_system/plugins/hero_builder/ban_list.txt')
    if not (ban_list == nil or not next(ban_list)) then
        HeroBuilderPlugin.ban_list = ban_list
    end
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            HeroBuilderPlugin:SpawnEvent(event)
    end,nil)
    if string.len(HeroBuilderPlugin.settings.custom_bans) > 1 and string.len(HeroBuilderPlugin.settings.custom_bans) < 20 then
        HeroBuilderPlugin:LoadBanList(HeroBuilderPlugin.settings.custom_bans)
    else
        HeroBuilderPlugin:PrepStageTwo()
    end
end

function HeroBuilderPlugin:PrepStageTwo()
    if HeroBuilderPlugin.settings.dota_abilities then
        for k,v in pairs(HeroBuilderPlugin.npc_abilities) do
            if v ~= nil and type(v) == 'table' then
                if v.AbilityType ~= nil then
                    if v.AbilityType == "DOTA_ABILITY_TYPE_ATTRIBUTES" then
                        HeroBuilderPlugin:AddTalent(k,v)
                    elseif v.AbilityType == "DOTA_ABILITY_TYPE_ULTIMATE" then
                        HeroBuilderPlugin:AddUltimate(k,v)
                    else
                        HeroBuilderPlugin:AddBasic(k,v)
                    end
                else
                    HeroBuilderPlugin:AddBasic(k,v)
                end
            end 
        end
    end
    if HeroBuilderPlugin.settings.custom_abilities then
        for k,v in pairs(HeroBuilderPlugin.npc_abilities_custom) do
            if v ~= nil and type(v) == 'table' then
                if HeroBuilderPlugin.npc_abilities[k] == nil then
                    if v.CustomEnabled ~= nil then
                        if v.AbilityType ~= nil then
                            if v.AbilityType == "DOTA_ABILITY_TYPE_ATTRIBUTES" then
                                HeroBuilderPlugin:AddTalent(k,v)
                            elseif v.AbilityType == "DOTA_ABILITY_TYPE_ULTIMATE" then
                                HeroBuilderPlugin:AddUltimate(k,v)
                            else
                                HeroBuilderPlugin:AddBasic(k,v)
                            end
                        else
                            HeroBuilderPlugin:AddBasic(k,v)
                        end
                    end
                end
            end 
        end
    end
    HeroBuilderPlugin:AllDonePreping()
end

function HeroBuilderPlugin:AddTalent(sAbility,data)
    if HeroBuilderPlugin.ban_list[sAbility] == nil then
        table.insert(HeroBuilderPlugin.available_abilities.talent,sAbility)
    end
end

function HeroBuilderPlugin:AddBasic(sAbility,data)
    if HeroBuilderPlugin.ban_list[sAbility] == nil then
        table.insert(HeroBuilderPlugin.available_abilities.basic,sAbility)
    end
end

function HeroBuilderPlugin:AddUltimate(sAbility,data)
    if HeroBuilderPlugin.ban_list[sAbility] == nil then
        table.insert(HeroBuilderPlugin.available_abilities.basic,sAbility)
    end
end

function HeroBuilderPlugin:AllDonePreping()
    CustomGameEventManager:RegisterListener("add_basic_ability",HeroBuilderPlugin.GiveUnitAbility_listen)
    --CustomGameEventManager:RegisterListener("add_ultimate_ability",HeroBuilderPlugin.GiveUnitAbility)
    CustomGameEventManager:RegisterListener("add_talent_ability",HeroBuilderPlugin.GiveUnitTalent_listen)

    CustomGameEventManager:RegisterListener("ban_basic_ability",HeroBuilderPlugin.BanAbility)
    CustomGameEventManager:RegisterListener("ban_talent_ability",HeroBuilderPlugin.BanAbility)

    HeroBuilderPlugin:PaginateSend(HeroBuilderPlugin.available_abilities.basic,"add_basic_ability")
    --HeroBuilderPlugin:PaginateSend(HeroBuilderPlugin.available_abilities.ultimate,"add_ultimate_ability")
    HeroBuilderPlugin:PaginateSend(HeroBuilderPlugin.available_abilities.talent,"add_talent_ability")
end

function HeroBuilderPlugin:BanAbility(tEvent)
    local iPlayer = tEvent.PlayerID
    if not HeroBuilderPlugin.settings.host_bans then return end
    if Toolbox:IsHost(iPlayer) then
        local sAbility = tEvent.ability
        HeroBuilderPlugin.ban_list[sAbility] = true
        CustomGameEventManager:Send_ServerToAllClients("hero_builder_error",{ability = sAbility})
    end
end


function HeroBuilderPlugin:PaginateSend(t,event_name)
    table.sort(t)
    local page_size = 20
    local current_page = {}
    local current_page_index = 0;
    local current_size = 0
    for k,v in pairs(t) do
        table.insert(current_page,v)
        current_size = current_size + 1
        if current_size > page_size then
            current_page_index = current_page_index + 1
            current_size = 0
            local rt = {
                target = "entindex",
                level = "int",
                ability = current_page,
                event = event_name,
            }
            CustomNetTables:SetTableValue("ability_registery",event_name .. "_" .. current_page_index,rt)
            current_page = {}
        end
    end
    if #current_page > 0 then
        current_page_index = current_page_index + 1
        local rt = {
            target = "entindex",
            level = "int",
            ability = current_page,
            event = event_name,
        }
        CustomNetTables:SetTableValue("ability_registery",event_name .. "_" .. current_page_index,rt)
    end
end

function HeroBuilderPlugin:GiveUnitAbility_listen(tEvent)
    if HeroBuilderPlugin.settings.disable_after_prematch and GameRules:State_Get() > DOTA_GAMERULES_STATE_PRE_GAME then return end
    if tonumber(tEvent.slot) < 0 then tEvent.slot = "0" end
    if HeroBuilderPlugin.settings.slot_id_limit > -1 and tonumber(tEvent.slot) > HeroBuilderPlugin.settings.slot_id_limit then return end
    local bSuccess = HeroBuilderPlugin:GiveUnitAbility(tEvent)
    if bSuccess then
        local iPlayer = tEvent.PlayerID
        local hUnit = EntIndexToHScript(tEvent.target)
        if hUnit.IsRealHero ~= nil and hUnit:IsRealHero() then
            PluginSystem:InternalEvent_Call("hero_build_change",{
                iPlayer = iPlayer
            })
        end
    end
end
function HeroBuilderPlugin:GiveUnitTalent_listen(tEvent)
    if HeroBuilderPlugin.settings.disable_after_prematch and GameRules:State_Get() > DOTA_GAMERULES_STATE_PRE_GAME then return end

    HeroBuilderPlugin:GiveUnitTalent(tEvent)
end

function HeroBuilderPlugin:GiveUnitAbility(tEvent)
    local iPlayer = tEvent.PlayerID
--[[     if HeroBuilderPlugin.settings.host_only then
        if not Toolbox:IsHost(iPlayer) then return false end
    end ]]
    local hUnit = EntIndexToHScript(tEvent.target)
    local iLevel = tEvent.level
    local sAbility = tEvent.ability
    if HeroBuilderPlugin.ban_list[sAbility] ~= nil then
        HeroBuilderPlugin:SendMessage(iPlayer,"invalid ablity",sAbility)
        return false
    end
    local bForce = tEvent.force == 1
    local iSlot = tEvent.slot

    local bLimited = 1 --PluginSystem:GetSetting("hero_builder","limited_mode")
    if bLimited and bLimited == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        if hUnit:GetTeam() ~= iTeam then return false end
        local iController = hUnit:GetMainControllingPlayer()
        if not (iController == -1 or iController == iPlayer) then return false end
    end

    local iiSlot = tonumber(iSlot)
    local ok = HeroBuilderPlugin:ReplaceAbility(hUnit,sAbility,iLevel,iiSlot,bForce)
    if not ok then
        HeroBuilderPlugin:SendMessage(iPlayer,"invalid ablity",sAbility)
        return false
    end
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(iPlayer)
    if hPlayerHero ~= nil then
        if hUnit == hPlayerHero then
            if HeroBuilderPlugin.player_build[iPlayer] == nil then HeroBuilderPlugin.player_build[iPlayer] = {} end
            if HeroBuilderPlugin.player_build[iPlayer].abilities == nil then HeroBuilderPlugin.player_build[iPlayer].abilities = {} end
            if HeroBuilderPlugin.player_build[iPlayer].talents == nil then HeroBuilderPlugin.player_build[iPlayer].talents = {} end
            table.insert(HeroBuilderPlugin.player_build[iPlayer].abilities,tEvent)
        end
    end
    return true
end

function HeroBuilderPlugin:GiveUnitTalent(tEvent)
    local iPlayer = tEvent.PlayerID
--[[     if HeroBuilderPlugin.settings.host_only then
        if not Toolbox:IsHost(iPlayer) then return false end
    end ]]
    local hUnit = EntIndexToHScript(tEvent.target)
    if hUnit.IsRealHero == nil then return false end
    if not hUnit:IsRealHero() then return false end
    local iLevel = tEvent.level
    local sAbility = tEvent.ability
    if HeroBuilderPlugin.ban_list[sAbility] ~= nil then
        HeroBuilderPlugin:SendMessage(iPlayer,"invalid ablity",sAbility)
        return false
    end
    local iSlot = tEvent.slot

    local bLimited = 1 -- PluginSystem:GetSetting("hero_builder","limited_mode")
    if bLimited and bLimited == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        if hUnit:GetTeam() ~= iTeam then return false end
        local iController = hUnit:GetMainControllingPlayer()
        if not (iController == -1 or iController == iPlayer) then return false end
    end
    
    --local ok = HeroBuilderPlugin:ReplaceGeneric(hUnit,sAbility,iLevel,"special_bonus_generic_talent",false)
    local iiSlot = tonumber(iSlot)
    local ok = HeroBuilderPlugin:ReplaceTalent(hUnit,sAbility,iLevel,iiSlot)
    if not ok then
        HeroBuilderPlugin:SendMessage(iPlayer,"invalid talent",sAbility)
        return false
    end
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(iPlayer)
    if hPlayerHero ~= nil then
        if hUnit == hPlayerHero then
            if HeroBuilderPlugin.player_build[iPlayer] == nil then HeroBuilderPlugin.player_build[iPlayer] = {} end
            if HeroBuilderPlugin.player_build[iPlayer].abilities == nil then HeroBuilderPlugin.player_build[iPlayer].abilities = {} end
            if HeroBuilderPlugin.player_build[iPlayer].talents == nil then HeroBuilderPlugin.player_build[iPlayer].talents = {} end
            table.insert(HeroBuilderPlugin.player_build[iPlayer].talents,tEvent)
        end
    end
    return true
end

function HeroBuilderPlugin:ReplaceGeneric(hUnit,sAbility,iLevel,iSlot,bForce)
	if hUnit then
		local bAdded = false
		local i = 0
        local hExistingAbility = hUnit:FindAbilityByName(sAbility)
        if hExistingAbility ~= nil then
            if iLevel == 0 then iLevel = 1 end
            if hExistingAbility:GetLevel() + iLevel > hExistingAbility:GetMaxLevel() then
                if hExistingAbility:GetLevel() ~= hExistingAbility:GetMaxLevel() then
                    hExistingAbility:SetLevel(hExistingAbility:GetMaxLevel())
                end
            else
                hExistingAbility:SetLevel(hExistingAbility:GetLevel()+iLevel)
            end
            if bForce then
                hExistingAbility:SetActivated(true)
                hExistingAbility:SetHidden(false)
            end
        else
            while (not bAdded and i < DOTA_MAX_ABILITIES) do
                local ability = hUnit:GetAbilityByIndex(i)
                if ability and ability:GetAbilityName() == sGeneric then
                    hUnit:RemoveAbilityByHandle(ability)
                    bAdded = true
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
                    else
                        return false
                    end
                elseif i > 18 then
                    bAdded = true
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
                    else
                        return false
                    end
                end
                i = i + 1
            end
        end
	end
    return true
end

function HeroBuilderPlugin:ReplaceTalent(hUnit,sAbility,iLevel,iSlot)
	if hUnit then
        local iLevel = tonumber(iLevel)
		local bAdded = false
		local i = 0
        local hExistingAbility = hUnit:FindAbilityByName(sAbility)
        if hExistingAbility ~= nil then return true end
        if hUnit.IsRealHero == nil then return true end
        if not hUnit:IsRealHero() then return true end
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
            if hOldAbility:GetLevel() > 0 then
                hUnit:SetAbilityPoints(hUnit:GetAbilityPoints()+hOldAbility:GetLevel())
            end
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

        else
            return false
        end
	end
    return true
end

function HeroBuilderPlugin:ReplaceAbility(hUnit,sAbility,iLevel,iSlot,bForce)
	if hUnit then
        local iLevel = tonumber(iLevel)
		local bAdded = false
		local i = 0
        local hExistingAbility = hUnit:FindAbilityByName(sAbility)
        if hExistingAbility ~= nil then
            if hUnit.GetAbilityPoints ~= nil then
                if hUnit:GetAbilityPoints() > 0 then
                    iLevel = 1
                    hUnit:SetAbilityPoints(hUnit:GetAbilityPoints()-1)
                end
            else
                if iLevel == 0
                    then iLevel = 1
                end
            end
            if iLevel > 0 then
                if hExistingAbility:GetLevel() + iLevel > hExistingAbility:GetMaxLevel() then
                    if hExistingAbility:GetLevel() ~= hExistingAbility:GetMaxLevel() then
                        hExistingAbility:SetLevel(hExistingAbility:GetMaxLevel())
                    end
                else
                    hExistingAbility:SetLevel(hExistingAbility:GetLevel()+iLevel)
                end
            end
            if bForce then
                hExistingAbility:SetActivated(true)
                hExistingAbility:SetHidden(false)
            end
            return true
        end
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
        local iOldAbility
        if hOldAbility ~= nil then 
            sOldAbility = hOldAbility:GetAbilityName()
            if Toolbox:string_starts(sOldAbility,"special_bonus_") then
                return true
            end
            iOldAbility = hOldAbility:GetLevel()

            if hOldAbility then
                if iOldAbility > 0 then
                    if hUnit:IsRealHero() then
                        hUnit:SetAbilityPoints(hUnit:GetAbilityPoints()+iOldAbility)
                    end
                end
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
        else
            --return old ability
            if sOldAbility ~= nil then
                hAbility = hUnit:AddAbility(sOldAbility)
                if hAbility ~= nil then
                    if iOldAbility > 0 then
                        hAbility:SetLevel(iOldAbility)
                    end
                    if iOldAbility == 0 then
                        if hAbility:GetAutoCastState() then
                            hAbility:ToggleAutoCast()
                        end
                    else
                        hUnit:SetAbilityPoints(hUnit:GetAbilityPoints()-iOldAbility)
                    end
                end
            end
            return false
        end
	end
    return true
end

function HeroBuilderPlugin:SpawnEvent(event)
    if HeroBuilderPlugin.unit_cache[event.entindex] ~= nil then return end
    HeroBuilderPlugin.unit_cache[event.entindex] = true
    Timers:CreateTimer(0.01,function()
        local hUnit = EntIndexToHScript(event.entindex)
        if hUnit == nil then return end
        if not hUnit.GetPlayerID then return end
        local playerID = hUnit:GetPlayerID()
        if not hUnit.IsHero then return end
        if not hUnit:IsHero() then return end
        if playerID < 0 then return end
        local hPlayer = PlayerResource:GetPlayer(playerID)
        if hPlayer == nil then return end
        local mainHero = hPlayer:GetAssignedHero()
        if mainHero == nil then return end
        if hUnit == mainHero then return end

        if hUnit:GetUnitName() ~= mainHero:GetUnitName() then
            playerID = HeroBuilderPlugin:FindActualOriginalHero(hUnit)
        end
        if playerID < 0 then return end

        if HeroBuilderPlugin.player_build[playerID] == nil then return end
        if HeroBuilderPlugin.player_build[playerID].abilities == nil then return end
        if HeroBuilderPlugin.player_build[playerID].talents == nil then return end


        for k,v in pairs(HeroBuilderPlugin.player_build[playerID].abilities) do
            v.target = event.entindex
            if HeroBuilderPlugin.no_duplication[v.ability] == nil then
                HeroBuilderPlugin:GiveUnitAbility(v)
            end
        end
        for k,v in pairs(HeroBuilderPlugin.player_build[playerID].talents) do
            v.target = event.entindex
            HeroBuilderPlugin:GiveUnitTalent(v)
        end
        
        local i = 0
        while (i < DOTA_MAX_ABILITIES) do
            local hOriginalAbility = mainHero:GetAbilityByIndex(i)
            local hAbility = hUnit:GetAbilityByIndex(i)
            if hAbility and hOriginalAbility and hOriginalAbility:GetAbilityName() == hAbility:GetAbilityName() then
                if hOriginalAbility:GetLevel() > 0 then
                    hAbility:SetLevel(hOriginalAbility:GetLevel())
                end
            end
            i = i + 1
        end
    end)
end

function HeroBuilderPlugin:SendMessage(iPlayer,sMessage,sSubject)
    --ShowCustomHeaderMessage(sMessage .. " " .. sSubject,iPlayer,0,2.0)
    --DebugScreenTextPretty( 140, 640, 0,  sMessage .. " " .. sSubject, 255, 0, 0, 255, 5.0, "arial", 30, false )
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer ~= nil then
        CustomGameEventManager:Send_ServerToPlayer(hPlayer,"hero_builder_error",{ability = sSubject})
    end
end

function HeroBuilderPlugin:FindActualOriginalHero(hUnit)
    local sName = hUnit:GetUnitName()
    if HeroBuilderPlugin.player_hero_cache[sName] ~= nil then
        return HeroBuilderPlugin.player_hero_cache[sName]
    end
    for iPlayer = 0,DOTA_MAX_PLAYERS do
        local hPlayer = PlayerResource:GetPlayer(iPlayer)
        if hPlayer ~= nil then
            local hHero = hPlayer:GetAssignedHero()
            if hHero ~= nil then
                if sName == hHero:GetUnitName() then
                    HeroBuilderPlugin.player_hero_cache[sName] = iPlayer
                    return iPlayer
                end
            end
        end
    end
    return -1
end

function HeroBuilderPlugin:ExportBanList(tArgs,bTeam,iPlayer)
	local hPlayer = iPlayer and PlayerResource:GetPlayer(iPlayer)
    local str = "{\"ban_list\":{\n"
    for k,v in pairs(HeroBuilderPlugin.ban_list) do
        str = str .. "\t\"" .. k .. "\": 1\n"
    end
    str = str .. "}}"
    CustomGameEventManager:Send_ServerToPlayer(hPlayer,"ban_list_export",{list = str})
end

function HeroBuilderPlugin:LoadBanList(pastebin)
    local url = "https://pastebin.com/raw/" .. pastebin
    local req = CreateHTTPRequestScriptVM("GET", url)
    req:Send(function(res)
        if res.StatusCode ~= 200 then
            print(res.Body)
            print("something went wrong")
        else
            print(res.Body)
			local data = JSON.decode(res.Body)
            HeroBuilderPlugin.ban_list = data.ban_list
        end
        HeroBuilderPlugin:PrepStageTwo()
    end)
end