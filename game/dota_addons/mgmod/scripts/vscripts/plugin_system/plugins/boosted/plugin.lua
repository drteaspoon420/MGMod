BoostedPlugin = class({})
_G.BoostedPlugin = BoostedPlugin
BoostedPlugin.settings = {}
BoostedPlugin.unit_cache = {}
BoostedPlugin.lists = {}
BoostedPlugin.points = {}
BoostedPlugin.main_modifier_name = "modifier_boosted"
BoostedPlugin.official_url = "http://drteaspoon.fi:3000/list"
BoostedPlugin.kv_bans = {}

local only_slot_map = {
    SLOT1 = 0,
    SLOT2 = 1,
    SLOT3 = 2,
    SLOT4 = 3,
    SLOT5 = 4,
    SLOT6 = 5
}


function BoostedPlugin:Init()
    print("[BoostedPlugin] found")
end

function BoostedPlugin:ApplySettings()
    BoostedPlugin.settings = PluginSystem:GetAllSetting("boosted")
    local kv_lists = LoadKeyValues('scripts/vscripts/plugin_system/plugins/boosted/lists.txt')
    if not (kv_lists == nil or not next(kv_lists)) then
        BoostedPlugin.kv_lists = kv_lists
    else
        BoostedPlugin.kv_lists = {}
    end

    local url = BoostedPlugin.settings.custom_list
    if url ~= "" then
        BoostedPlugin:GetOnlineList("https://pastebin.com/raw/" .. url)
    else
        BoostedPlugin:GetOnlineList(BoostedPlugin.official_url)
    end

    CustomGameEventManager:RegisterListener("boost_player",BoostedPlugin.boost_player)
    CustomGameEventManager:RegisterListener("boost_player_recheck",BoostedPlugin.boost_player_recheck)

    PluginSystem:InternalEvent_Register("hero_build_change",function(event)
        BoostedPlugin:UpdatePlayer_NetTable(event.iPlayer)
    end)
    ListenToGameEvent("dota_ability_changed", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        BoostedPlugin:UpdateEvent(event)
    end,nil)
    LinkLuaModifier( "modifier_boosted", "plugin_system/plugins/boosted/modifier_boosted", LUA_MODIFIER_MOTION_NONE )
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            BoostedPlugin:SpawnEvent(event)
    end,nil)
end

function BoostedPlugin:GetOnlineList(url)
    local req = CreateHTTPRequestScriptVM("GET", url)
    req:SetHTTPRequestHeaderValue("Dedicated-Server-Key", GetDedicatedServerKey("v1"))
    req:Send(function(res)
        if res.StatusCode ~= 200 then
            if url ~= BoostedPlugin.official_url then
                print("custom url was not valid")
                BoostedPlugin:GetOnlineList(BoostedPlugin.official_url)
            end
            return
        end
        if not BoostedPlugin:ApplyOnlineList(res.Body) then
            if url ~= BoostedPlugin.official_url then
                print("custom list was not valid")
                BoostedPlugin:GetOnlineList(BoostedPlugin.official_url)
            end
        else
            print("valid list at " .. url)
        end
    end)
end

function BoostedPlugin:ApplyOnlineList(json)
    local data = JSON.decode(json)
    if data == nil then return false end
    print(type(data.blocklist))
    if data.blocklist == nil or type(data.blocklist) ~= "table" or (next(data.blocklist) == nil) then
        print("block list empty")
    else
        BoostedPlugin.kv_lists.blocklist = data.blocklist
    end
    if data.nerflist == nil or type(data.nerflist) ~= "table" or (next(data.nerflist) == nil) then
        print("nerf list empty")
    else
        BoostedPlugin.kv_lists.nerflist = data.nerflist
    end
    if data.limitlist == nil or type(data.limitlist) ~= "table" or (next(data.limitlist) == nil) then
        print("limit list empty")
    else
        BoostedPlugin.kv_lists.limitlist = data.limitlist
    end
    if type(BoostedPlugin.blocklist) ~= "table" then 
        BoostedPlugin.kv_lists.blocklist = {
            all = {},
            wildcard = {}
        }
    end
    if type(BoostedPlugin.nerflist) ~= "table" then
        BoostedPlugin.kv_lists.nerflist = {
            all = {},
            wildcard = {}
        }
    end
    if type(BoostedPlugin.limitlist) ~= "table" then
        BoostedPlugin.kv_lists.limitlist = {
            all = {},
            wildcard = {}
        }
    end
    return true
end

function BoostedPlugin:boost_player_recheck(event)
    local iPlayer = tEvent.PlayerID
    if iPlayer < 0 then return end
    BoostedPlugin:UpdatePlayer_NetTable(iPlayer)
end

function BoostedPlugin:UpdateEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    print(event.entindex,"dota_ability_changed")
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        local iPlayer = hUnit:GetPlayerOwnerID()
        if iPlayer < 0 then return end
        BoostedPlugin:UpdatePlayer_NetTable(iPlayer)
    end
end

function BoostedPlugin:UpdatePlayer_NetTable(iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then return end
    if BoostedPlugin.lists[iPlayer] == nil then BoostedPlugin.lists[iPlayer] = {} end
    local tAbilities = {}
    local tAbilityHandles = BoostedPlugin:GetCompleteAbilityList(iPlayer)
    for i=1,#tAbilityHandles do
        local hAbility = tAbilityHandles[i]
        if hAbility then
            local sAbility = hAbility:GetAbilityName()
            if BoostedPlugin:BlocksAbility(sAbility) then
                local vals = hAbility:GetAbilityKeyValues()
                if vals.AbilityType ~= "DOTA_ABILITY_TYPE_ATTRIBUTES" then
                    if tAbilities[sAbility] == nil then
                        tAbilities[sAbility] = {}
                        if vals.AbilitySpecial ~= nil then
                            for k,v in pairs(vals.AbilitySpecial) do
                                for j,l in pairs(v) do
                                    if BoostedPlugin:BlocksKV(sAbility,j) then
                                        if j ~= "" then
                                            if tAbilities[sAbility] == nil then 
                                                tAbilities[sAbility] = {}
                                            end
                                            tAbilities[sAbility][j] = 1.0
                                        end
                                    end
                                end
                            end
                        end
                        if vals.AbilityValues ~= nil then
                            for k,v in pairs(vals.AbilityValues) do
                                if BoostedPlugin:BlocksKV(sAbility,k) then
                                    if type(v) == "table" then
                                        for j,l in pairs(v) do
                                            if j == "value" then
                                                if tAbilities[sAbility] == nil then 
                                                    tAbilities[sAbility] = {}
                                                end
                                                tAbilities[sAbility][k] = 1.0
                                            end
                                        end
                                    else
                                        if tAbilities[sAbility] == nil then 
                                            tAbilities[sAbility] = {}
                                        end
                                        tAbilities[sAbility][k] = 1.0
                                    end
                                end
                            end
                        end
                        if vals.AbilityChannelTime ~= nil then
                            local t = Toolbox:split(vals.AbilityChannelTime," ")
                            if t[1] ~= "0" then
                                if tAbilities[sAbility] == nil then 
                                    tAbilities[sAbility] = {}
                                end
                                tAbilities[sAbility]["AbilityChannelTime"] = 1.0
                            end
                        end
                        if vals.AbilityDuration ~= nil then
                            local t = Toolbox:split(vals.AbilityDuration," ")
                            if t[1] ~= "0" then
                                if tAbilities[sAbility] == nil then 
                                    tAbilities[sAbility] = {}
                                end
                                tAbilities[sAbility]["AbilityDuration"] = 1.0
                            end
                        end
                        if vals.AbilityDamage ~= nil then
                            local t = Toolbox:split(vals.AbilityDamage," ")
                            if t[1] ~= "0" then
                                if tAbilities[sAbility] == nil then 
                                    tAbilities[sAbility] = {}
                                end
                                tAbilities[sAbility]["AbilityDamage"] = 1.0
                            end
                        end
                    end
                end
            end
        end
    end


    BoostedPlugin.lists[iPlayer] = tAbilities
    for k,v in pairs(BoostedPlugin.lists[iPlayer]) do
        CustomNetTables:SetTableValue("player_upgrades_" .. iPlayer,k,v)
    end
--[[     for k,v in pairs(deleted) do
        if v then
            CustomNetTables:SetTableValue("player_upgrades_" .. iPlayer,k,{})
        end
    end ]]
    if BoostedPlugin.points[iPlayer] == nil then
        BoostedPlugin.points[iPlayer] = 0
        CustomNetTables:SetTableValue("player_upgrades_" .. iPlayer,"player_details",{points = BoostedPlugin.points[iPlayer]})
    end
    --DeepPrintTable(BoostedPlugin.lists[iPlayer])
end

function BoostedPlugin:IsBlocked(k,v)
    return false
end
    
function BoostedPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        Timers:CreateTimer(0,function()
            --if BoostedPlugin.unit_cache[event.entindex] ~= nil then return end
            --BoostedPlugin.unit_cache[event.entindex] = true
            local iPlayer = hUnit:GetPlayerOwnerID()
            if iPlayer < 0 then return end
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer == nil then return end
            local hHero = hPlayer:GetAssignedHero()
            print("adding ",event.entindex)
            if hHero == nil then
                print("hero was nill")
                return
            end
            if hHero ~= hUnit then 
                print("hero was not unit")
                return
            end
            BoostedPlugin:UpdatePlayer_NetTable(iPlayer)
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_boosted",{})
            print("all should be good")
        end)
    end
end


function BoostedPlugin:boost_player(tEvent)
    local iPlayer = tEvent.PlayerID
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then return end
    local sAbility = tEvent.ability
    local sKey = tEvent.key
    local fValue = tonumber(tEvent.value)
    if BoostedPlugin.lists[iPlayer] == nil then
        print(iPlayer,"list nil")
        return
    end
    if BoostedPlugin.lists[iPlayer][sAbility] == nil then
        print(iPlayer,"ability list nil")
        return
    end
    if BoostedPlugin.lists[iPlayer][sAbility][sKey] == nil then
        print(iPlayer,"key in ability list nil")
        return
    end
    
    local fOld = BoostedPlugin.lists[iPlayer][sAbility][sKey]
    local fMult = BoostedPlugin:NerfsKV(sAbility,sKey)
    local fUp = 0.2 * fMult
    local fDown = 0.05 * fMult

    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fValue
    CustomNetTables:SetTableValue("player_upgrades_" .. iPlayer,sAbility,BoostedPlugin.lists[iPlayer][sAbility])

    local hMod = Entities:Next(nil)
    while hMod do
        if hMod.IncrementStackCount then
            if hMod.UpdateValue ~= nil then
                if hMod:GetParent():GetMainControllingPlayer() == iPlayer then
                    print("updating for player " .. iPlayer)
                    hMod:UpdateValue(sAbility,sKey,BoostedPlugin.lists[iPlayer][sAbility][sKey])
                end
            end
        end
        hMod = Entities:Next(hMod)
    end
    
end

function BoostedPlugin:BlocksAbility(sAbility) -- returns false if blocked
    if BoostedPlugin.kv_lists.blocklist == nil then return true end
    if BoostedPlugin.kv_lists.blocklist.all == nil then return true end
    if BoostedPlugin.kv_lists.blocklist.all[sAbility] == nil then return true end
    return false
end

function BoostedPlugin:BlocksKV(sAbility,sKey) -- returns false if blocked
    --no block list
    if BoostedPlugin.kv_lists.blocklist == nil then return true end
    --check specific ability + kv
    if BoostedPlugin.kv_lists.blocklist[sAbility] ~= nil and BoostedPlugin.kv_lists.blocklist[sAbility][sKey] ~= nil then
        return false
    end
    --check specific all + kv
    if BoostedPlugin.kv_lists.blocklist.all ~= nil and BoostedPlugin.kv_lists.blocklist.all[sKey] ~= nil then return false end
    
    --check specific wildcard + kv
    for k,v in pairs(BoostedPlugin.kv_lists.blocklist.wildcard) do
        if string.find(sKey,k) ~= nil then
            return false
        end
    end
    return true
end

function BoostedPlugin:NerfsKV(sAbility,sKey) -- returns 1.0 if normal.
    --no block list
    if BoostedPlugin.kv_lists.nerflist == nil then return 1.0 end
    --check specific ability + kv
    if BoostedPlugin.kv_lists.nerflist[sAbility] ~= nil and BoostedPlugin.kv_lists.nerflist[sAbility][sKey] ~= nil then
        return BoostedPlugin.kv_lists.nerflist[sAbility][sKey]
    end
    --check specific all + kv
    if BoostedPlugin.kv_lists.nerflist.all ~= nil and BoostedPlugin.kv_lists.nerflist.all[sKey] ~= nil then return BoostedPlugin.kv_lists.nerflist.all[sKey] end
    
    --check specific wildcard + kv
    for k,v in pairs(BoostedPlugin.kv_lists.nerflist.wildcard) do
        if string.find(sKey,k) ~= nil then
            return v
        end
    end
    return 1.0
end

function BoostedPlugin:BotLevelup(iPlayer)
    local iCount = BoostedPlugin.points[iPlayer]
    local tAbilities = BoostedPlugin.lists[iPlayer]
    local sAbility
    local sKey
    local iFailCount = 0
    while(sAbility == nil and sKey == nil) or iFailCount > 25 do
        sAbility = Toolbox:GetRandomKey(tAbilities)
        if sAbility ~= nil then
            sKey = Toolbox:GetRandomKey(tAbilities[sAbility])
        end
        if sKey == nil then
            iFailCount = iFailCount + 1
        end
    end
    if sKey == nil then return end
    local tEvent = {
        PlayerID = iPlayer,
        ability = sAbility,
        key = sKey,
        value = 1.0
    }
    for i=1,iCount do
        BoostedPlugin:boost_player(tEvent)
    end
end


--[[
    Offer stuff
]]--
BoostedPlugin.player_offers = {}
function BoostedPlugin:GenerateOffer(iPlayer)
    if BoostedPlugin.player_offers[iPlayer] == nil then
        BoostedPlugin.player_offers[iPlayer] = {}
    end
    local tOffer = {}

    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then return end

    local tAvailable = BoostedPlugin:ProcessOffer(iPlayer,7,2,1)


    table.insert(BoostedPlugin.player_offers[iPlayer],tOffer)
end

function BoostedPlugin:ProcessOffer(iPlayer,normal,rare,ultra)
    BoostedPlugin.player_current_offers[iPlayer] = {}
	local player = PlayerResource:GetPlayer(iPlayer)
	local hero = player:GetAssignedHero()
    local hero_name = hero:GetUnitName()
    local team = hero:GetTeam()
    local used_key_pairs = {}
    local offer_table = {}
    local i = 1
    local attempts = 0
    local max_attempts = 100
    
    if BoostedPlugin.kv_bans[iPlayer] == nil then
        BoostedPlugin.kv_bans[iPlayer] = {}
        BoostedPlugin.kv_bans[iPlayer].bans = 0
    end
    local allow_ban = BoostedPlugin.kv_bans[iPlayer].bans < BoostedPlugin.settings.kv_bans
    local tt = BoostedPlugin:GetCompleteOfferList(hero,iPlayer)
    while i < ultra+1 do
        if BoostedPlugin:IsEmpty(tt) then break end
        local oo = self:CreateOffer2(hero,tt)
        local offer = oo[1]
        tt = oo[2]
        if offer.key == nil then
            print("something went wrong")
            attempts = attempts + 1
            if attempts > max_attempts then break end
        elseif used_key_pairs[offer.ability .. "_" .. offer.key] == nil and offer.ability ~= "generic_hidden" then
            local current = BoostedPlugin:GetUpgrade(offer.ability,offer.key,team)
            local mult = self:GetNerf(offer.ability,offer.key)
            mult = mult * BoostedPlugin:TeamImbalance(team)
            local upgrade = BoostedPlugin.settings.UPGRADE_RATE * 0.01 * BoostedPlugin.settings.ULTRA_MULTIPLIER * 0.01 * mult
            local downgrade = BoostedPlugin.settings.DOWNGRADE_RATE * 0.01 * BoostedPlugin.settings.ULTRA_MULTIPLIER * 0.01 * mult
            upgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,team,current + upgrade)*100
            downgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,team,current - downgrade)*100

            table.insert(offer_table,{
                id = i,
                ability = offer.ability,
                key = offer.key,
                current = offer.current,
                current_mult = current,
                upgrade = upgrade,
                downgrade = downgrade,
                rarity = 3,
                allow_ban = allow_ban,
            });
            BoostedPlugin.player_current_offers[iPlayer][offer.ability .. "&" .. offer.key .. "&" .. 3] = true;
            i = i + 1
            used_key_pairs[offer.ability .. "_" .. offer.key] = true
            attempts = 0
        else
            attempts = attempts + 1
            if attempts > max_attempts then break end
        end
    end
    while i < rare+ultra+1 do
        if BoostedPlugin:IsEmpty(tt) then break end
        local oo = self:CreateOffer2(hero,tt)
        local offer = oo[1]
        tt = oo[2]
        if offer.key == nil then
            print("something went wrong")
            attempts = attempts + 1
            if attempts > max_attempts then break end
        elseif used_key_pairs[offer.ability .. "_" .. offer.key] == nil and offer.ability ~= "generic_hidden" then
            local current = BoostedPlugin:GetUpgrade(offer.ability,offer.key,team)
            local mult = self:GetNerf(offer.ability,offer.key)
            mult = mult * BoostedPlugin:TeamImbalance(team)
            local upgrade = BoostedPlugin.settings.UPGRADE_RATE *0.01* BoostedPlugin.settings.RARE_MULTIPLIER *0.01*mult
            local downgrade = BoostedPlugin.settings.DOWNGRADE_RATE *0.01* BoostedPlugin.settings.RARE_MULTIPLIER *0.01*mult

            upgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,team,current + upgrade)*100
            downgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,team,current - downgrade)*100


            table.insert(offer_table,{
                id = i,
                ability = offer.ability,
                key = offer.key,
                current = offer.current,
                current_mult = current,
                upgrade = upgrade,
                downgrade = downgrade,
                rarity = 2,
                allow_ban = allow_ban,
            });
            BoostedPlugin.player_current_offers[iPlayer][offer.ability .. "&" .. offer.key .. "&" .. 2] = true;
            i = i + 1
            used_key_pairs[offer.ability .. "_" .. offer.key] = true
            attempts = 0
        else
            attempts = attempts + 1
            if attempts > max_attempts then break end
        end
    end
    while i < ultra+rare+normal+1 do
        if BoostedPlugin:IsEmpty(tt) then break end
        local oo = self:CreateOffer2(hero,tt)
        local offer = oo[1]
        tt = oo[2]
        if offer.key == nil then
            print("something went wrong")
            attempts = attempts + 1
            if attempts > max_attempts then break end
        elseif used_key_pairs[offer.ability .. "_" .. offer.key] == nil and offer.ability ~= "generic_hidden" then
            local current = BoostedPlugin:GetUpgrade(offer.ability,offer.key,team)
            local mult = self:GetNerf(offer.ability,offer.key)
            mult = mult * BoostedPlugin:TeamImbalance(team)
            local upgrade = BoostedPlugin.settings.UPGRADE_RATE *0.01*mult
            local downgrade = BoostedPlugin.settings.DOWNGRADE_RATE *0.01*mult

            upgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,team,current + upgrade)*100
            downgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,team,current - downgrade)*100
            table.insert(offer_table,{
                id = i,
                ability = offer.ability,    
                key = offer.key,
                current = offer.current,
                current_mult = current,
                upgrade = upgrade,
                downgrade = downgrade,
                rarity = 1,
                allow_ban = allow_ban,
            });
            BoostedPlugin.player_current_offers[iPlayer][offer.ability .. "&" .. offer.key .. "&" .. 1] = true;
            i = i + 1
            used_key_pairs[offer.ability .. "_" .. offer.key] = true
            attempts = 0
        else
            attempts = attempts + 1
            if attempts > max_attempts then break end
        end
    end
    return offer_table;
end
function BoostedPlugin:PickRng(t)
    local p = RandomInt(1, #t)
    local r = t[p]
    table.remove(t,p)
    return {r,t}
end

function BoostedPlugin:GetCompleteOfferList(hero,iPlayer)
    local tAbilities = BoostedPlugin:LimitViable(BoostedPlugin:GetCompleteAbilityList(hero),iPlayer)
    local tOffers = {}
    for i=1,#tAbilities do
        local ability = tAbilities[i]
        local tt = BoostedPlugin:IntoRng(ability,BoostedPlugin.lists[iPlayer][ability],iPlayer)
        if next(tt) ~= nil then
            tOffers[ability] = tt
        end
    end
    return tOffers
end

function BoostedPlugin:LimitViable(t,iPlayer)
    local ti = {}
    for k,v in pairs(t) do
        if BoostedPlugin.lists[iPlayer][v] ~= nil then
            table.insert(ti,v)
        end
    end
    return ti
end

function BoostedPlugin:GetCompleteAbilityList(hero)
    local controlled = BoostedPlugin:GetControlledUnits(hero)
    table.insert(controlled,hero)
    local all_abs = {}
    for _,v in pairs(controlled) do
        local u_abs = BoostedPlugin:GetAllAbilities(v)
        for _,j in pairs(u_abs) do
            table.insert(all_abs,j)
        end
    end
    return remove_duplicates(all_abs)
end

function remove_duplicates(t)
    local hash = {}
    local res = {}
    for _,v in ipairs(t) do
       if (not hash[v]) then
           res[#res+1] = v
           hash[v] = true
       end
    end
    return res
end

function BoostedPlugin:GetAllAbilities(unit)
    local c = unit:GetAbilityCount()
    local t = {}
    local only_slot = BoostedPlugin.settings.only_slot
    if only_slot == "DISABLED" then
        for i=1,c do
            local hAbility = unit:GetAbilityByIndex(i-1)
            if hAbility ~= nil then
                --if not hAbility:IsStolen() then
                    sAbility = hAbility:GetName()
                    table.insert(t,sAbility)
                --end
            end
        end
        if unit:HasInventory() then
            for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_NEUTRAL_SLOT do
                local item = unit:GetItemInSlot(i);
                if item ~= nil then
                    sAbility = item:GetName()
                    table.insert(t,sAbility)
                end
            end
        end
    else
        local i = only_slot_map[only_slot]
        local hAbility = unit:GetAbilityByIndex(i)
        if hAbility ~= nil then
            --if not hAbility:IsStolen() then
                sAbility = hAbility:GetName()
                table.insert(t,sAbility)
            --end
        end
    end
    return t
end

function BoostedPlugin:GetControlledUnits(unit)
    local playerId = unit:GetPlayerID()
    local units = {}
    local hUnit = Entities:First()
    while hUnit ~= nil do
        if hUnit.IsBaseNPC ~= nil and hUnit:IsBaseNPC() then
            if hUnit:GetMainControllingPlayer() == playerId then
                if hUnit:HasModifier(BoostedPlugin.main_modifier_name) then
                    if not hUnit:IsIllusion() then
                        table.insert(units,hUnit)
                    end
                end
            end
        end
        hUnit = Entities:Next(hUnit)
    end
    return units
end

function BoostedPlugin:IntoRng(ability,t,iPlayer)
    local ti = {}
    if BoostedPlugin.kv_bans[iPlayer] == nil then
        BoostedPlugin.kv_bans[iPlayer] = {}
    end
    for k,v in pairs(t) do
		if v ~= nil then
            if BoostedPlugin.kv_bans[iPlayer][ability .. "&" .. k] == nil then
                table.insert(ti,k)
            end
        end
    end
    return ti
end

function BoostedPlugin:GrantAllUpgrade()
    for i=0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayer(i) then
            local player = PlayerResource:GetPlayer(i)
            if player ~= nil then
                BoostedPlugin:GrantPlayerUpgrade(i)
            end
        end
    end
end

function BoostedPlugin:GrantTeamUpgrade(iTeam)
    for i=0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayer(i) then
            local player = PlayerResource:GetPlayer(i)
            if player ~= nil then
                if PlayerResource:GetTeam(i) == iTeam then
                    BoostedPlugin:GrantPlayerUpgrade(i)
                end
            end
        end
    end
end

function BoostedPlugin:GrantPlayerUpgrade(iPlayer)
    BoostedPlugin:GenerateOffer(iPlayer)
end