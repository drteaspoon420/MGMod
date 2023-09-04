
BoostedPlugin = class({})
_G.BoostedPlugin = BoostedPlugin
BoostedPlugin.settings = {}
BoostedPlugin.unit_cache = {}
BoostedPlugin.lists = {}
BoostedPlugin.points = {}
BoostedPlugin.main_modifier_name = "modifier_boosted"
BoostedPlugin.official_url = "http://drteaspoon.fi:3000/list"
BoostedPlugin.kv_bans = {}

BoostedPlugin.player_boosters = {}

local JSON = require("utils/dkjson")
local only_slot_map = {
    any = -1,
    q = 0,
    w = 1,
    e = 2,
    d = 3,
    f = 4,
    r = 5
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

	local req_blocks = LoadKeyValues('scripts/vscripts/plugin_system/plugins/boosted/req_blocks.txt')
	if req_blocks == nil or not next(req_blocks) then
		print("empty req_blocks :/")
		return
	end
	BoostedPlugin.req_blocks = req_blocks
    --CustomGameEventManager:RegisterListener("boost_player",BoostedPlugin.boost_player)
    CustomGameEventManager:RegisterListener("upgrade_hero",BoostedPlugin.upgrade_hero)
    --CustomGameEventManager:RegisterListener("upgrade_report",Dynamic_Wrap(self,'upgrade_report'))
    --CustomGameEventManager:RegisterListener('ability_tooltip_extra_request', Dynamic_Wrap( self, 'ability_tooltip_extra_request'))

    PluginSystem:InternalEvent_Register("hero_build_change",function(event)
        BoostedPlugin:UpdatePlayer_NetTable(event.iPlayer,nil)
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

    --Currency thing
    local tOption = {
        plugin = BoostedPlugin,
        plugin_name = "boosted",
        cost = BoostedPlugin.settings.cost or 100,
        call_fn = "currencies_buy",
        option_name = "buy_upgrade",
    }
    CurrenciesPlugin:RegisterSpendOption(BoostedPlugin.settings.currency,tOption)
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
    if type(BoostedPlugin.kv_lists.blocklist) ~= "table" then 
        BoostedPlugin.kv_lists.blocklist = {
            all = {},
            wildcard = {}
        }
    end
    if type(BoostedPlugin.kv_lists.nerflist) ~= "table" then
        BoostedPlugin.kv_lists.nerflist = {
            all = {},
            wildcard = {}
        }
    end
    if type(BoostedPlugin.kv_lists.limitlist) ~= "table" then
        BoostedPlugin.kv_lists.limitlist = {
            all = {},
            wildcard = {}
        }
    end
    return true
end


function BoostedPlugin:UpdateEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        local iPlayer = hUnit:GetPlayerOwnerID()
        if iPlayer < 0 then return end
        BoostedPlugin:UpdatePlayer_NetTable(iPlayer,hUnit)
    end
end

function BoostedPlugin:GetAbilitiesOfUnit(hUnit)
    local c = hUnit:GetAbilityCount()
    local t = {}
    local only_slot = only_slot_map[BoostedPlugin.settings.only_slot]
    if only_slot == -1 then
        for i=1,c do
            local hAbility = hUnit:GetAbilityByIndex(i-1)
            if hAbility ~= nil then
                table.insert(t,hAbility)
            end
        end
        if hUnit:HasInventory() then
            for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_NEUTRAL_SLOT do
                local item = hUnit:GetItemInSlot(i);
                if item ~= nil then
                    table.insert(t,item)
                end
            end
        end
    else
        local i = only_slot
        local hAbility = hUnit:GetAbilityByIndex(i)
        if hAbility ~= nil then
            table.insert(t,hAbility)
        end
    end
    return t
end

function BoostedPlugin:UpdatePlayer_NetTable_Ability(iPlayer,hUnit,hAbility)
    if hAbility and hAbility.GetAbilityName == nil then return end
    local sAbility = hAbility:GetAbilityName()
    if BoostedPlugin:BlocksAbility(sAbility) then
        local vals = hAbility:GetAbilityKeyValues()
        if vals.AbilityType ~= "DOTA_ABILITY_TYPE_ATTRIBUTES" then
            if BoostedPlugin.lists[iPlayer][sAbility] == nil then
                BoostedPlugin.lists[iPlayer][sAbility] = {}
                if vals.AbilitySpecial ~= nil then
                    for k,v in pairs(vals.AbilitySpecial) do
                        for j,l in pairs(v) do
                            if BoostedPlugin:BlocksKV(sAbility,j) then
                                if j ~= "" then
                                    if BoostedPlugin.lists[iPlayer][sAbility] == nil then 
                                        BoostedPlugin.lists[iPlayer][sAbility] = {}
                                    end
                                    if BoostedPlugin.lists[iPlayer][sAbility][j] == nil then
                                        BoostedPlugin.lists[iPlayer][sAbility][j] = 1.0
                                    end
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
                                    if j == "value" or string.starts(j,"special_bonus_") then
                                        if BoostedPlugin.lists[iPlayer][sAbility] == nil then 
                                            BoostedPlugin.lists[iPlayer][sAbility] = {}
                                        end
                                        if BoostedPlugin.lists[iPlayer][sAbility][j] == nil then
                                            BoostedPlugin.lists[iPlayer][sAbility][k] = 1.0
                                        end
                                    end
                                end
                            else
                                if BoostedPlugin.lists[iPlayer][sAbility] == nil then 
                                    BoostedPlugin.lists[iPlayer][sAbility] = {}
                                end
                                if BoostedPlugin.lists[iPlayer][sAbility][j] == nil then
                                    BoostedPlugin.lists[iPlayer][sAbility][k] = 1.0
                                end
                            end
                        end
                    end
                end
                if vals.AbilityChannelTime ~= nil then
                    local t = Toolbox:split(vals.AbilityChannelTime," ")
                    if t[1] ~= "0" then
                        if BoostedPlugin.lists[iPlayer][sAbility] == nil then 
                            BoostedPlugin.lists[iPlayer][sAbility] = {}
                        end
                        if BoostedPlugin.lists[iPlayer][sAbility]["AbilityChannelTime"] == nil then
                            BoostedPlugin.lists[iPlayer][sAbility]["AbilityChannelTime"] = 1.0
                        end
                    end
                end
                if vals.AbilityDuration ~= nil then
                    local t = Toolbox:split(vals.AbilityDuration," ")
                    if t[1] ~= "0" then
                        if BoostedPlugin.lists[iPlayer][sAbility] == nil then 
                            BoostedPlugin.lists[iPlayer][sAbility] = {}
                        end
                        if BoostedPlugin.lists[iPlayer][sAbility]["AbilityDuration"] == nil then
                            BoostedPlugin.lists[iPlayer][sAbility]["AbilityDuration"] = 1.0
                        end
                    end
                end
                if vals.AbilityDamage ~= nil then
                    local t = Toolbox:split(vals.AbilityDamage," ")
                    if t[1] ~= "0" then
                        if BoostedPlugin.lists[iPlayer][sAbility] == nil then 
                            BoostedPlugin.lists[iPlayer][sAbility] = {}
                        end
                        if BoostedPlugin.lists[iPlayer][sAbility]["AbilityDamage"] == nil then
                            BoostedPlugin.lists[iPlayer][sAbility]["AbilityDamage"] = 1.0
                        end
                    end
                end
            end
        end
    end
end

function BoostedPlugin:UpdatePlayer_NetTable(iPlayer,hUnit)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    if hUnit == nil then
        hUnit = hPlayer:GetAssignedHero()
    end
    if hUnit == nil then return end
    if BoostedPlugin.lists[iPlayer] == nil then
        BoostedPlugin.lists[iPlayer] = {}
    end
    local tAbilityHandles = BoostedPlugin:GetAbilitiesOfUnit(hUnit)
    for i=1,#tAbilityHandles do
        local hAbility = tAbilityHandles[i]
        BoostedPlugin:UpdatePlayer_NetTable_Ability(iPlayer,hUnit,hAbility)
    end

    
    for k,v in pairs(BoostedPlugin.lists[iPlayer]) do
        CustomNetTables:SetTableValue("player_upgrades_" .. iPlayer,k,v)
    end
--[[     for k,v in pairs(deleted) do
        if v then
            CustomNetTables:SetTableValue("player_upgrades_" .. iPlayer,k,{})
        end
    end ]]
--[[     if BoostedPlugin.points[iPlayer] == nil then
        BoostedPlugin.points[iPlayer] = 0
        CustomNetTables:SetTableValue("player_upgrades_" .. iPlayer,"player_details",{points = BoostedPlugin.points[iPlayer]})
    end ]]
    --DeepPrintTable(BoostedPlugin.lists[iPlayer])
end

function BoostedPlugin:IsBlocked(k,v)
    return false
end
    
function BoostedPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    Timers:CreateTimer(0,function()
        if hUnit:IsRealHero() then
            --if BoostedPlugin.unit_cache[event.entindex] ~= nil then return end
            --BoostedPlugin.unit_cache[event.entindex] = true
            local iPlayer = hUnit:GetPlayerOwnerID()
            if iPlayer < 0 then return end
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer == nil then return end
--[[             local hHero = hPlayer:GetAssignedHero()
            if hHero == nil then
                print("hero was nill")
                return
            end
            if hHero ~= hUnit then 
                print("hero was not unit")
                return
            end ]]
            BoostedPlugin:UpdatePlayer_NetTable(iPlayer,hUnit)
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_boosted",{})
            print("all should be good")
        else
            if hUnit:IsCourier() then return end
            local iPlayer = hUnit:GetMainControllingPlayer()
            if iPlayer < 0 then
                iPlayer = hUnit:GetPlayerOwnerID()
            end
            if iPlayer < 0 then
                return
            end
            
            BoostedPlugin:UpdatePlayer_NetTable(iPlayer,hUnit)
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_boosted",{})
        end
    end)
end


function BoostedPlugin:boost_player(tEvent)
    local iPlayer = tEvent.PlayerID
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then
        print("not a real player",iPlayer)
        return
    end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then
        print("not a real hero",iPlayer)
        return
    end
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
    local fUp = BoostedPlugin.settings.UPGRADE_RATE * 0.01 * fMult
    local fDown = BoostedPlugin.settings.DOWNGRADE_RATE * 0.01 * fMult 
    if tEvent.rarity == 3 then
        fUp = fUp * BoostedPlugin.settings.ULTRA_MULTIPLIER * 0.01
        fDown = fDown * BoostedPlugin.settings.ULTRA_MULTIPLIER * 0.01
    elseif tEvent.rarity == 2 then
        fUp = fUp * BoostedPlugin.settings.RARE_MULTIPLIER * 0.01
        fDown = fDown * BoostedPlugin.settings.RARE_MULTIPLIER * 0.01
    end
    
    if fValue < 0 then
        if fOld > 1.0000001 then
            BoostedPlugin.lists[iPlayer][sAbility][sKey] = BoostedPlugin:ModifiedUpgrade(sAbility,sKey,1.0)
        else
            BoostedPlugin.lists[iPlayer][sAbility][sKey] = BoostedPlugin:ModifiedUpgrade(sAbility,sKey,fOld - fDown)
        end
    else
        if fOld < 0.9999999 then
            BoostedPlugin.lists[iPlayer][sAbility][sKey] = BoostedPlugin:ModifiedUpgrade(sAbility,sKey,1.0)
        else
            BoostedPlugin.lists[iPlayer][sAbility][sKey] = BoostedPlugin:ModifiedUpgrade(sAbility,sKey,fOld + fUp)
        end
    end

    CustomNetTables:SetTableValue("player_upgrades_" .. iPlayer,sAbility,BoostedPlugin.lists[iPlayer][sAbility])

    local hUnit = Entities:Next(nil)
    while hUnit do
        if hUnit:IsDOTANPC() then
            if hUnit.FindModifierByName ~= nil then
                local hMod = hUnit:FindModifierByName(BoostedPlugin.main_modifier_name)
                if hMod ~= nil then
                    if hUnit:GetMainControllingPlayer() == iPlayer then
                        hMod:UpdateValue(sAbility,sKey,BoostedPlugin.lists[iPlayer][sAbility][sKey])
                        if hUnit:HasInventory() then
                            BoostedPlugin:RefreshItems(sAbility,hUnit)
                        end
                    end
                end
            end
        end
        hUnit = Entities:Next(hUnit)
    end
    
end

function BoostedPlugin:RefreshItems(sAbility,hUnit)
    for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
        local item = hUnit:GetItemInSlot(i);
        if item ~= nil then
            if item:GetName() == sAbility then
                item:OnUnequip()
                Timers:CreateTimer( 0, function()
                    item:OnEquip()
                end)
            end
        end
    end
    local item = hUnit:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT);
    if item ~= nil then
        if item:GetName() == sAbility then
            item:OnUnequip()
            Timers:CreateTimer( 0, function()
                item:OnEquip()
            end)
        end
    end
end

function BoostedPlugin:BlocksAbility(sAbility) -- returns false if blocked
    if BoostedPlugin.req_blocks ~= nil then
        if BoostedPlugin.req_blocks.all ~= nil then
            if BoostedPlugin.req_blocks.all[sAbility] ~= nil then
                return false
            end
        end
    end
    if BoostedPlugin.req_blocks ~= nil then
        if BoostedPlugin.req_blocks.all ~= nil then
            if BoostedPlugin.req_blocks.all[sAbility] ~= nil then
                return false
            end
        end
    end
    if BoostedPlugin.kv_lists.blocklist == nil then return true end
    if BoostedPlugin.kv_lists.blocklist.all == nil then return true end
    if BoostedPlugin.kv_lists.blocklist.all[sAbility] == nil then return true end
    return false
end

function BoostedPlugin:BlocksKV(sAbility,sKey) -- returns false if blocked
    if BoostedPlugin.req_blocks ~= nil then
        if BoostedPlugin.req_blocks.all ~= nil then
            if BoostedPlugin.req_blocks.all[sAbility] ~= nil then
                return false
            end
            if BoostedPlugin.req_blocks.all[sKey] ~= nil then
                return false
            end
        end
    end
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
    if BoostedPlugin.settings.no_nerf_list then return 1.0 end
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
--[[ 
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
        value = 1.0,
        rarity = 2
    }
    for i=1,iCount do
        BoostedPlugin:boost_player(tEvent)
    end
end ]]


--[[
    Offer stuff
]]--
BoostedPlugin.player_offers = {}
BoostedPlugin.player_boosters = {}
function BoostedPlugin:GenerateOffer(iPlayer)
    if BoostedPlugin.player_offers[iPlayer] ~= nil and BoostedPlugin.player_offers[iPlayer] ~= {} then
        CustomNetTables:SetTableValue("player_booster", iPlayer .. "d", BoostedPlugin.player_offers[iPlayer])
        return
    end
    BoostedPlugin.player_boosters[iPlayer] = BoostedPlugin.player_boosters[iPlayer] - 1
    BoostedPlugin.player_offers[iPlayer]  = {}

    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then return end

    local c = BoostedPlugin.settings.upgrade_count
    local kvcount = BoostedPlugin:GetKvCount(hHero,iPlayer)
    if BoostedPlugin.settings.kv_count_bonus > 0 then
        local player_bonus = math.floor(kvcount / BoostedPlugin.settings.kv_count_bonus)
        c = c + player_bonus
    end
    local rare = 0
    local ultra = 0
    local normal = c
    for i=1,c do
        local r = RandomInt(0,100)
        if r < BoostedPlugin.settings.ultra_chance then
            ultra = ultra + 1
            normal = normal - 1
        elseif r < BoostedPlugin.settings.ultra_chance + BoostedPlugin.settings.rare_chance then
            rare = rare + 1
            normal = normal - 1
        end
    end

    local tAvailable = BoostedPlugin:ProcessOffer(iPlayer,normal,rare,ultra)
    BoostedPlugin.player_offers[iPlayer] = tAvailable
    CustomNetTables:SetTableValue("player_booster", iPlayer .. "d", BoostedPlugin.player_offers[iPlayer])
end

function tlen(t)
    local c = 0
    if not next(t) then return 0 end
    for k,v in pairs(t) do
        c = c + 1
    end
    return c
end


function BoostedPlugin:GetKvCount(hHero,iPlayer)
    local t = BoostedPlugin:LimitViable(BoostedPlugin:GetCompleteAbilityList(hHero,iPlayer),iPlayer)
    local c = 0
    for k,v in pairs(t) do
        if BoostedPlugin.lists[iPlayer] ~= nil then
            if BoostedPlugin.lists[iPlayer][v] ~= nil then
                c = c + tlen(BoostedPlugin.lists[iPlayer][v])
            end
        end
    end
    return c
end

function BoostedPlugin:upgrade_hero(tEvent)
	BoostedPlugin:SelectOffer(tEvent)
end
function BoostedPlugin:SelectOffer(tEvent)
	local iPlayer = tEvent.PlayerID
    if BoostedPlugin.player_offers[iPlayer] == nil then
        print("offer is nill?")
        return
    end
    if BoostedPlugin.player_offers[iPlayer] == {} then
        print("offer is empty?")
        return
    end
    local id = tEvent.id
    local tSelect
    for k,v in pairs(BoostedPlugin.player_offers[iPlayer]) do
        if v.id == id then
            tSelect = v
        end
    end
    if tSelect == nil then
        return
    end
    BoostedPlugin.player_offers[iPlayer] = {}
    local tInternalEvent = {
        PlayerID = iPlayer,
        ability = tSelect.ability,
        key = tSelect.key,
        rarity = tSelect.rarity
    }
    if tEvent.plus == 0 then
        tInternalEvent.value = -1
        BoostedPlugin:boost_player(tInternalEvent)
    elseif tEvent.plus == 1 then
        tInternalEvent.value = 1
        BoostedPlugin:boost_player(tInternalEvent)
    elseif tEvent.plus == 2 then
        BoostedPlugin:BanPersonalKV(tSelect.ability,tSelect.key,iPlayer)
    end
    BoostedPlugin.player_offers[iPlayer] = nil
    if BoostedPlugin.player_boosters[iPlayer] > 0 then
        BoostedPlugin:GenerateOffer(iPlayer)
    end
end

function BoostedPlugin:BanPersonalKV(ability,key,player_id)
    if BoostedPlugin.kv_bans[player_id] == nil then
        BoostedPlugin.kv_bans[player_id] = {}
        BoostedPlugin.kv_bans[player_id].bans = 0
    end
    if BoostedPlugin.kv_bans[player_id].bans < BoostedPlugin.settings.kv_bans then
        BoostedPlugin.kv_bans[player_id][ability .. "&" .. key] = 1
        BoostedPlugin.kv_bans[player_id].bans = BoostedPlugin.kv_bans[player_id].bans + 1
    end
end

function BoostedPlugin:FindAbilityOrItem(unit,ability)
    if unit ~= nil then
        if string.find(ability,"item_") then
            return BoostedPlugin:FindItemByName(unit,ability)
        else
            return unit:FindAbilityByName(ability)
        end
    end
    return nil
end

function BoostedPlugin:FindOwned(hero,ability)
    local t = BoostedPlugin:GetControlledUnits(hero)
    for _,v in pairs(t) do
        local hAbility = BoostedPlugin:FindAbilityOrItem(v,ability)
        if hAbility ~= nil then return hAbility end
    end
    return nil
end

function BoostedPlugin:FindItemByName(unit, itemName)
    if unit ~= nil and unit:HasInventory() then
        for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
            local item = unit:GetItemInSlot(i);
            if item ~= nil then
                if item:GetName() == itemName then
                    return item
                end
            end
        end
        local item = unit:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT);
        if item ~= nil then
            if item:GetName() == itemName then
                return item
            end
        end
    end
    return nil
end


function BoostedPlugin:CreateOffer(hero,t)
    if not next(t) then return {{ability = "generic_hidden", key = "ERROR", current = 0},t} end
    local ability = Toolbox:GetRandomKey(t)
    local oo = BoostedPlugin:PickRng(t[ability])
    local key = oo[1]
    t[ability] = oo[2]
    if not next(t[ability]) then
        t[ability] = nil
    end
    local hAbility = BoostedPlugin:FindAbilityOrItem(hero,ability)
    if hAbility == nil then
        hAbility = BoostedPlugin:FindOwned(hero,ability)
        if hAbility == nil then
            return {{ability = "generic_hidden", key = "ERROR", current = 0},t}
        end
    end
    local nSpecialLevel = hAbility:GetLevel() - 1
    if nSpecialLevel == -1 then nSpecialLevel = 0 end
    local flBaseValue = hAbility:GetLevelSpecialValueNoOverride( key, nSpecialLevel )
    return {{ability = ability, key = key, current = flBaseValue},t}
end


function BoostedPlugin:ProcessOffer(iPlayer,normal,rare,ultra)
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
        if Toolbox:IsEmpty(tt) then break end
        local oo = BoostedPlugin:CreateOffer(hero,tt)
        local offer = oo[1]
        tt = oo[2]
        if offer.key == nil then
            print("something went wrong")
            attempts = attempts + 1
            if attempts > max_attempts then break end
        elseif used_key_pairs[offer.ability .. "_" .. offer.key] == nil and offer.ability ~= "generic_hidden" then
            local current = BoostedPlugin.lists[iPlayer][offer.ability][offer.key]
            local mult = BoostedPlugin:NerfsKV(offer.ability,offer.key)
            local upgrade = BoostedPlugin.settings.UPGRADE_RATE * 0.01 * BoostedPlugin.settings.ULTRA_MULTIPLIER * 0.01 * mult
            local downgrade = BoostedPlugin.settings.DOWNGRADE_RATE * 0.01 * BoostedPlugin.settings.ULTRA_MULTIPLIER * 0.01 * mult
            if (current < 0.9999999) then
                upgrade = 100
            else
                upgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,current + upgrade)*100
            end

            if (current > 1.0000001) then
                downgrade = 100
            else
                downgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,current - downgrade)*100
            end
--TODO:
--[[
    local fMult = BoostedPlugin:NerfsKV(sAbility,sKey)
local fUp = BoostedPlugin.settings.UPGRADE_RATE * 0.01 * fMult
local fDown = BoostedPlugin.settings.DOWNGRADE_RATE * 0.01 * fMult 
if tEvent.rarity == 3 then
    fUp = fUp * BoostedPlugin.settings.ULTRA_MULTIPLIER * 0.01
    fDown = fDown * BoostedPlugin.settings.ULTRA_MULTIPLIER * 0.01
elseif tEvent.rarity == 2 then
    fUp = fUp * BoostedPlugin.settings.RARE_MULTIPLIER * 0.01
    fDown = fDown * BoostedPlugin.settings.RARE_MULTIPLIER * 0.01
end


if fValue < 0 then
    BoostedPlugin.lists[iPlayer][sAbility][sKey] = BoostedPlugin:ModifiedUpgrade(sAbility,sKey,fOld - fDown)
else
    BoostedPlugin.lists[iPlayer][sAbility][sKey] = BoostedPlugin:ModifiedUpgrade(sAbility,sKey,fOld + fUp)
end
]]
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
            i = i + 1
            used_key_pairs[offer.ability .. "_" .. offer.key] = true
            attempts = 0
        else
            attempts = attempts + 1
            if attempts > max_attempts then break end
        end
    end
    while i < rare+ultra+1 do
        if Toolbox:IsEmpty(tt) then break end
        local oo = BoostedPlugin:CreateOffer(hero,tt)
        local offer = oo[1]
        tt = oo[2]
        if offer.key == nil then
            print("something went wrong")
            attempts = attempts + 1
            if attempts > max_attempts then break end
        elseif used_key_pairs[offer.ability .. "_" .. offer.key] == nil and offer.ability ~= "generic_hidden" then
            local current = BoostedPlugin.lists[iPlayer][offer.ability][offer.key]
            local mult = BoostedPlugin:NerfsKV(offer.ability,offer.key)
            local upgrade = BoostedPlugin.settings.UPGRADE_RATE *0.01* BoostedPlugin.settings.RARE_MULTIPLIER *0.01*mult
            local downgrade = BoostedPlugin.settings.DOWNGRADE_RATE *0.01* BoostedPlugin.settings.RARE_MULTIPLIER *0.01*mult

            if (current < 0.9999999) then
                upgrade = 100
            else
                upgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,current + upgrade)*100
            end

            if (current > 1.0000001) then
                downgrade = 100
            else
                downgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,current - downgrade)*100
            end


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
            i = i + 1
            used_key_pairs[offer.ability .. "_" .. offer.key] = true
            attempts = 0
        else
            attempts = attempts + 1
            if attempts > max_attempts then break end
        end
    end
    while i < ultra+rare+normal+1 do
        if Toolbox:IsEmpty(tt) then break end
        local oo = BoostedPlugin:CreateOffer(hero,tt)
        local offer = oo[1]
        tt = oo[2]
        if offer.key == nil then
            print("something went wrong")
            attempts = attempts + 1
            if attempts > max_attempts then break end
        elseif used_key_pairs[offer.ability .. "_" .. offer.key] == nil and offer.ability ~= "generic_hidden" then
            local current = BoostedPlugin.lists[iPlayer][offer.ability][offer.key]
            local mult = BoostedPlugin:NerfsKV(offer.ability,offer.key)
            local upgrade = BoostedPlugin.settings.UPGRADE_RATE *0.01*mult
            local downgrade = BoostedPlugin.settings.DOWNGRADE_RATE *0.01*mult

            if (current < 0.9999999) then
                upgrade = 100
            else
                upgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,current + upgrade)*100
            end

            if (current > 1.0000001) then
                downgrade = 100
            else
                downgrade = BoostedPlugin:ModifiedUpgrade(offer.ability,offer.key,current - downgrade)*100
            end
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
            i = i + 1
            used_key_pairs[offer.ability .. "_" .. offer.key] = true
            attempts = 0
        else
            attempts = attempts + 1
            if attempts > max_attempts then break end
        end
    end
    table.sort(
        offer_table,
        function(v1,v2)
            if v1.rarity ~= v2.rarity then return v1.rarity > v2.rarity end
            if string.starts(v1.ability,"item_") then
                if string.starts(v2.ability,"item_") then
                    if v1.ability ~= v2.ability then return v1.ability < v2.ability end
                else
                    return false
                end
            elseif string.starts(v2.ability,"item_") then
                return true
            end
            if v1.ability ~= v2.ability then return v1.ability < v2.ability end
            return v1.key < v2.key
        end
    )
    return offer_table
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end
 
function BoostedPlugin:PickRng(t)
    local p = RandomInt(1, #t)
    local r = t[p]
    table.remove(t,p)
    return {r,t}
end

function BoostedPlugin:GetCompleteOfferList(hero,iPlayer)
    local tAbilities = BoostedPlugin:LimitViable(BoostedPlugin:GetCompleteAbilityList(hero,iPlayer),iPlayer)
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

function BoostedPlugin:GetCompleteAbilityList(hHero,iPlayer)
    local controlled = BoostedPlugin:GetControlledUnits(hHero)
    table.insert(controlled,hHero)
    local all_abs = {}
    for _,v in pairs(controlled) do
        local u_abs = BoostedPlugin:GetAllAbilities(v,iPlayer)
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

function BoostedPlugin:GetAllAbilities(hUnit,iPlayer)
    local c = hUnit:GetAbilityCount()
    local t = {}
    local only_slot = only_slot_map[BoostedPlugin.settings.only_slot]
    if only_slot == -1 then
        for i=1,c do
            local hAbility = hUnit:GetAbilityByIndex(i-1)
            if hAbility ~= nil then
                --if not hAbility:IsStolen() then
                    --BoostedPlugin:UpdatePlayer_NetTable_Ability(iPlayer,hUnit,hAbility)
                    sAbility = hAbility:GetName()
                    table.insert(t,sAbility)
                --end
            end
        end
    else
        local i = only_slot
        local hAbility = hUnit:GetAbilityByIndex(i)
        if hAbility ~= nil then
            --if not hAbility:IsStolen() then
                --BoostedPlugin:UpdatePlayer_NetTable_Ability(iPlayer,hUnit,hAbility)
                sAbility = hAbility:GetName()
                table.insert(t,sAbility)
            --end
        end
    end
    if hUnit:HasInventory() then
        if BoostedPlugin.settings.upgrade_normal_items then
            for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
                local item = hUnit:GetItemInSlot(i);
                if item ~= nil then
                    sAbility = item:GetName()
                    table.insert(t,sAbility)
                end
            end
        end
        if BoostedPlugin.settings.upgrade_neutral_items then
            local item = hUnit:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT );
            if item ~= nil then
                sAbility = item:GetName()
                table.insert(t,sAbility)
            end
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
            if hUnit:GetMainControllingPlayer() == playerId or hUnit:GetPlayerOwnerID() == playerId then
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
    if BoostedPlugin.player_boosters[iPlayer] == nil then
        BoostedPlugin.player_boosters[iPlayer] = 1
    else
        BoostedPlugin.player_boosters[iPlayer] = BoostedPlugin.player_boosters[iPlayer] + 1
    end
    if PlayerResource:GetPlayer(iPlayer) == nil then return end
    if PlayerResource:GetPlayer(iPlayer):GetAssignedHero() == nil then return end
    BoostedPlugin:GenerateOffer(iPlayer)
end

function BoostedPlugin:currencies_buy(tEvent)
    if tEvent.iShare == 0 then
        BoostedPlugin:GrantPlayerUpgrade(tEvent.iPlayer)
    elseif tEvent.iShare == 1 then
        local iTeam = PlayerResource:GetTeam(tEvent.iPlayer)
        if (iTeam == DOTA_TEAM_BADGUYS) or (iTeam == DOTA_TEAM_GOODGUYS) then
            BoostedPlugin:GrantTeamUpgrade(iTeam)
        end
    elseif tEvent.iShare == 2 then
        BoostedPlugin:GrantAllUpgrade()
    end
end

function BoostedPlugin:GetUpgrade(ability,key,iPlayer)
    if BoostedPlugin.lists[iPlayer] ~= nil and BoostedPlugin.lists[iPlayer][ability] ~= nil and BoostedPlugin.lists[iPlayer][ability][key] ~= nil then
        return BoostedPlugin.lists[iPlayer][ability][key]
    end
    return 1.0
end


function BoostedPlugin:ModifiedUpgrade(ability,key,value)
    local max = BoostedPlugin.settings.MAX_MULTIPLIER or 10000
    local min = BoostedPlugin.settings.MIN_MULTIPLIER or 4
    local limitlist = BoostedPlugin.kv_lists.limitlist
    if limitlist ~= nil then
        if limitlist[ability] ~= nil and limitlist[ability][key] ~= nil then
            if limitlist[ability][key].min ~= nil then
                min = limitlist[ability][key].min
            end
            if limitlist[ability][key].max ~= nil then
                max = limitlist[ability][key].max
            end
        else
            if limitlist.all ~= nil and limitlist.all[ability] ~= nil then
                if limitlist.all[ability].min ~= nil then
                    min = limitlist.all[ability].min
                end
                if limitlist.all[ability].max ~= nil then
                    max = limitlist.all[ability].max
                end
            elseif limitlist.all ~= nil and limitlist.all[key] ~= nil then
                if limitlist.all[key].min ~= nil then
                    min = limitlist.all[key].min
                end
                if limitlist.all[key].max ~= nil then
                    max = limitlist.all[key].max
                end
            elseif limitlist.wildcard ~= nil then
                for k,v in pairs(limitlist.wildcard) do
                    if string.find(key,k) ~= nil then
                        if limitlist.wildcard[k].min ~= nil then
                            min = limitlist.wildcard[k].min
                        end
                        if limitlist.wildcard[k].max ~= nil then
                            max = limitlist.wildcard[k].max
                        end
                        break
                    end
                end
            end
        end 
    end
    if value > max*0.01 then
        value = max*0.01
    end
    if value < min*0.01 then
        value = min*0.01
    end
    return value
end

function BoostedPlugin:GetNerf(ability,key)
    if BoostedPlugin.settings.no_nerf_list then return 1 end
    if BoostedPlugin.kv_lists.nerflist == nil then return 1 end
    if BoostedPlugin.kv_lists.nerflist.all ~= nil and BoostedPlugin.kv_lists.nerflist.all[key] ~= nil then return BoostedPlugin.kv_lists.nerflist.all[key] end
    if BoostedPlugin.kv_lists.nerflist.all ~= nil and BoostedPlugin.kv_lists.nerflist.all[ability] ~= nil then return BoostedPlugin.kv_lists.nerflist.all[ability] end
    if BoostedPlugin.kv_lists.nerflist[ability] ~= nil and BoostedPlugin.kv_lists.nerflist[ability][key] ~= nil then return BoostedPlugin.kv_lists.nerflist[ability][key] end
    if BoostedPlugin.kv_lists.nerflist.wildcard ~= nil then
        for k,v in pairs(BoostedPlugin.kv_lists.nerflist.wildcard) do
            if string.find(key,k) ~= nil then return v end
        end
    end
    return 1
end

function BoostedPlugin:ItemAddedToInventoryFilter(event)
	local inventory = event.inventory_parent_entindex_const and EntIndexToHScript(event.inventory_parent_entindex_const)
	local item = event.item_entindex_const and EntIndexToHScript(event.item_entindex_const)
	local itemParent = event.item_parent_entindex_const and EntIndexToHScript(event.item_parent_entindex_const)
	local sugg = event.suggested_slot

	if BoostedPlugin ~= nil then
        if itemParent ~= nil then
            if itemParent:IsDOTANPC() then
                if itemParent:IsRealHero() then
                    if itemParent:GetPlayerOwnerID() < 0 then return {true,event} end
                    Timers:CreateTimer(0,function()
                        BoostedPlugin:UpdatePlayer_NetTable(itemParent:GetPlayerOwnerID())
                    end)
                end
            end
        end
	end
	
	return {true,event}
end

