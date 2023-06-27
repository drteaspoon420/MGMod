BoostedPlugin = class({})
_G.BoostedPlugin = BoostedPlugin
BoostedPlugin.settings = {}
BoostedPlugin.unit_cache = {}
BoostedPlugin.lists = {}
BoostedPlugin.modifier_links = {}
BoostedPlugin.points = {}


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

    if BoostedPlugin.settings.boosted_mode == "points" or BoostedPlugin.settings.boosted_mode == "free_form" then
        CustomGameEventManager:RegisterListener("boost_player",BoostedPlugin.boost_player)
    end
    CustomGameEventManager:RegisterListener("boost_player_recheck",BoostedPlugin.boost_player_recheck)

    if BoostedPlugin.settings.boosted_mode == "attributes" then
        Timers:CreateTimer(1,function()
            BoostedPlugin:periodic_check_all()
            return 5
        end)
    end
    
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
    local tOldAbilities = BoostedPlugin.lists[iPlayer]
    local deleted = {}
    for k,v in pairs(tOldAbilities) do
        local bChanges = false
        for j,l in pairs(v) do
            if l > 1.0000 or l < 1.0000 then
                bChanges = true
                --print(k,j,"was changed, abort deleting")
            end
        end
        if not bChanges then
            --print(k,"deleting")
            tOldAbilities[k] = nil
            deleted[k] = true
        end
    end
    local tAbilities = {}
    for i=0,DOTA_MAX_ABILITIES-1 do
        local hAbility = hHero:GetAbilityByIndex(i)
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
                                            tAbilities[sAbility][j] = {
                                                value = 1.0,
                                                attribute = RandomInt(0,2)
                                            }
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
                                                tAbilities[sAbility][k] = {
                                                    value = 1.0,
                                                    attribute = RandomInt(0,2)
                                                }
                                            end
                                        end
                                    else
                                        if tAbilities[sAbility] == nil then 
                                            tAbilities[sAbility] = {}
                                        end
                                        tAbilities[sAbility][k] = {
                                            value = 1.0,
                                            attribute = RandomInt(0,2)
                                        }
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
                                tAbilities[sAbility]["AbilityChannelTime"] = {
                                    value = 1.0,
                                    attribute = RandomInt(0,2)
                                }
                            end
                        end
                        if vals.AbilityDuration ~= nil then
                            local t = Toolbox:split(vals.AbilityDuration," ")
                            if t[1] ~= "0" then
                                if tAbilities[sAbility] == nil then 
                                    tAbilities[sAbility] = {}
                                end
                                tAbilities[sAbility]["AbilityDuration"] = {
                                    value = 1.0,
                                    attribute = RandomInt(0,2)
                                }
                            end
                        end
                        if vals.AbilityDamage ~= nil then
                            local t = Toolbox:split(vals.AbilityDamage," ")
                            if t[1] ~= "0" then
                                if tAbilities[sAbility] == nil then 
                                    tAbilities[sAbility] = {}
                                end
                                tAbilities[sAbility]["AbilityDamage"] = {
                                    value = 1.0,
                                    attribute = RandomInt(0,2)
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    for k,v in pairs(tAbilities) do
        if tOldAbilities[k] == nil then
            if next(tAbilities[k]) then
                tOldAbilities[k] = v
                deleted[k] = false
            end
        end
    end
    

    BoostedPlugin.lists[iPlayer] = tOldAbilities
    for k,v in pairs(BoostedPlugin.lists[iPlayer]) do
        CustomNetTables:SetTableValue("boosted_upgrades_" .. iPlayer,k,v)
    end
--[[     for k,v in pairs(deleted) do
        if v then
            CustomNetTables:SetTableValue("boosted_upgrades_" .. iPlayer,k,{})
        end
    end ]]
    if BoostedPlugin.points[iPlayer] == nil then
        BoostedPlugin.points[iPlayer] = 0
        CustomNetTables:SetTableValue("boosted_upgrades_" .. iPlayer,"player_details",{points = BoostedPlugin.points[iPlayer]})
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
            if BoostedPlugin.unit_cache[event.entindex] ~= nil then return end
            BoostedPlugin.unit_cache[event.entindex] = true
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
            BoostedPlugin.modifier_links[iPlayer] = hModifier
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
    
    if BoostedPlugin.settings.points_mode then
        if BoostedPlugin.points[iPlayer] == nil then
            BoostedPlugin.points[iPlayer] = 0
        end
        local fOld = BoostedPlugin.lists[iPlayer][sAbility][sKey]
        local fMult = BoostedPlugin:NerfsKV(sAbility,sKey)
        local fUp = 0.2 * fMult
        local fDown = 0.05 * fMult


        if BoostedPlugin.settings.allow_reallocation then
            if fOld > 1.001 then
                if fValue > 0 then
                    if BoostedPlugin.points[iPlayer] == 0 then return end
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld + fUp
                    BoostedPlugin.points[iPlayer] = BoostedPlugin.points[iPlayer] - 1
                else
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld - fUp
                    BoostedPlugin.points[iPlayer] = BoostedPlugin.points[iPlayer] + 1
                end
            elseif fOld < 0.999 then
                if fValue > 0 then
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld + fDown
                    BoostedPlugin.points[iPlayer] = BoostedPlugin.points[iPlayer] + 1
                else
                    if BoostedPlugin.points[iPlayer] == 0 then return end
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld - fDown
                    BoostedPlugin.points[iPlayer] = BoostedPlugin.points[iPlayer] - 1
                end
            else
                if BoostedPlugin.points[iPlayer] == 0 then return end
                if fValue > 0 then
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld + fUp
                    BoostedPlugin.points[iPlayer] = BoostedPlugin.points[iPlayer] - 1
                else
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld - fDown
                    BoostedPlugin.points[iPlayer] = BoostedPlugin.points[iPlayer] - 1
                end
            end
        else
            if BoostedPlugin.points[iPlayer] == 0 then return end
            if fOld > 1.001 then
                if fValue > 0 then
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld + fUp
                else
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld - fUp
                end
            elseif fOld < 0.999 then
                if fValue > 0 then
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld + fDown
                else
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld - fDown
                end
            else
                if fValue > 0 then
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld + fUp
                else
                    BoostedPlugin.lists[iPlayer][sAbility][sKey] = fOld - fDown
                end
            end
            BoostedPlugin.points[iPlayer] = BoostedPlugin.points[iPlayer] - 1
        end
        CustomNetTables:SetTableValue("boosted_upgrades_" .. iPlayer,"player_details",{points = BoostedPlugin.points[iPlayer]})
    else
        BoostedPlugin.lists[iPlayer][sAbility][sKey] = fValue
    end
    CustomNetTables:SetTableValue("boosted_upgrades_" .. iPlayer,sAbility,BoostedPlugin.lists[iPlayer][sAbility])

    if BoostedPlugin.modifier_links[iPlayer] == nil then
        print(iPlayer,"modifier is nil")
        return
    end
    local hMod = BoostedPlugin.modifier_links[iPlayer]
    if hMod.UpdateValue ~= nil then
        hMod:UpdateValue(sAbility,sKey,BoostedPlugin.lists[iPlayer][sAbility][sKey])
    else
        print("could not update modifier")
    end
end
function BoostedPlugin:periodic_check_all()
    for i=0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayer(i) then
            local player = PlayerResource:GetPlayer(i)
            if player ~= nil then
                BoostedPlugin:periodic_check(i)
            end
        end
    end
end
function BoostedPlugin:periodic_check(iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then return end
    if BoostedPlugin.perdiodic_check_stats == nil then BoostedPlugin.perdiodic_check_stats = {} end
    local str = hHero:GetStrength()
    local int = hHero:GetIntellect()
    local agi = hHero:GetAgility()
    if BoostedPlugin.perdiodic_check_stats[iPlayer] == nil then
        BoostedPlugin.perdiodic_check_stats[iPlayer] = {
            str = str,
            int = int,
            agi = agi
        }
    else
        if  BoostedPlugin.perdiodic_check_stats[iPlayer].str == str and
            BoostedPlugin.perdiodic_check_stats[iPlayer].int == int and
            BoostedPlugin.perdiodic_check_stats[iPlayer].agi == agi 
        then
            return
        end
    end
    --DeepPrintTable(BoostedPlugin.perdiodic_check_stats[iPlayer])

    if BoostedPlugin.lists[iPlayer] == nil then
        print(iPlayer,"list nil")
        return
    end

    if BoostedPlugin.modifier_links[iPlayer] == nil then
        print(iPlayer,"modifier is nil")
        return
    end
    local hMod = BoostedPlugin.modifier_links[iPlayer]
    if hMod.UpdateValue == nil then
        print("could not update modifier")
        return
    end
    local fMultSetting = BoostedPlugin.settings.percent_per_attributes * 0.01
    for k,_ in pairs(BoostedPlugin.lists[iPlayer]) do
        for j,v in pairs(BoostedPlugin.lists[iPlayer][k]) do
            if BoostedPlugin.lists[iPlayer][k][j].attribute == DOTA_ATTRIBUTE_STRENGTH then
                BoostedPlugin.lists[iPlayer][k][j].value = BoostedPlugin:NerfsKV(k,j) * fMultSetting * str + 1.0
            elseif BoostedPlugin.lists[iPlayer][k][j].attribute == DOTA_ATTRIBUTE_AGILITY then
                BoostedPlugin.lists[iPlayer][k][j].value = BoostedPlugin:NerfsKV(k,j) * fMultSetting * agi + 1.0
            elseif BoostedPlugin.lists[iPlayer][k][j].attribute == DOTA_ATTRIBUTE_INTELLECT then
                BoostedPlugin.lists[iPlayer][k][j].value = BoostedPlugin:NerfsKV(k,j) * fMultSetting * int + 1.0
            end
            hMod:UpdateValue(k,j,BoostedPlugin.lists[iPlayer][k][j].value)
        end
        CustomNetTables:SetTableValue("boosted_upgrades_" .. iPlayer,k,BoostedPlugin.lists[iPlayer][k])
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