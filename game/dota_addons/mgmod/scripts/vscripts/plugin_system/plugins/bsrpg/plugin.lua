BsrpgPlugin = class({})
_G.BsrpgPlugin = BsrpgPlugin
BsrpgPlugin.settings = {}
BsrpgPlugin.unit_cache = {}
BsrpgPlugin.lists = {}
BsrpgPlugin.modifier_links = {}
BsrpgPlugin.points = {}


function BsrpgPlugin:Init()
    --print("[BsrpgPlugin] found")
end

function BsrpgPlugin:ApplySettings()
    BsrpgPlugin.settings = PluginSystem:GetAllSetting("bsrpg")
    local kv_lists = LoadKeyValues('scripts/vscripts/plugin_system/plugins/bsrpg/lists.txt')
    if not (kv_lists == nil or not next(kv_lists)) then
        BsrpgPlugin.kv_lists = kv_lists
    else
        BsrpgPlugin.kv_lists = {}
    end

    --print("[BsrpgPlugin] doing shit")
    if BsrpgPlugin.settings.bsrpg_mode == "points" or BsrpgPlugin.settings.bsrpg_mode == "free_form" then
        CustomGameEventManager:RegisterListener("boost_player",BsrpgPlugin.boost_player)
    end
    CustomGameEventManager:RegisterListener("boost_player_recheck",BsrpgPlugin.boost_player_recheck)

    if BsrpgPlugin.settings.bsrpg_mode == "attributes" then
        Timers:CreateTimer(1,function()
            BsrpgPlugin:periodic_check_all()
            return 5
        end)
    end
    
    PluginSystem:InternalEvent_Register("hero_build_change",function(event)
        BsrpgPlugin:UpdatePlayer_NetTable(event.iPlayer)
    end)
    ListenToGameEvent("dota_ability_changed", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        BsrpgPlugin:UpdateEvent(event)
    end,nil)
    LinkLuaModifier( "modifier_bsrpg", "plugin_system/plugins/bsrpg/modifier_bsrpg", LUA_MODIFIER_MOTION_NONE )
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            BsrpgPlugin:SpawnEvent(event)
    end,nil)
    
    --print("[BsrpgPlugin] doing shit")
end


function BsrpgPlugin:boost_player_recheck(event)
    local iPlayer = tEvent.PlayerID
    if iPlayer < 0 then return end
    BsrpgPlugin:UpdatePlayer_NetTable(iPlayer)
end

function BsrpgPlugin:UpdateEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    --print(event.entindex,"dota_ability_changed")
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        local iPlayer = hUnit:GetPlayerOwnerID()
        if iPlayer < 0 then return end
        BsrpgPlugin:UpdatePlayer_NetTable(iPlayer)
    end
end

function BsrpgPlugin:UpdatePlayer_NetTable(iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then return end
    if BsrpgPlugin.lists[iPlayer] == nil then BsrpgPlugin.lists[iPlayer] = {} end
    local tOldAbilities = BsrpgPlugin.lists[iPlayer]
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
            if BsrpgPlugin:BlocksAbility(sAbility) then
                local vals = hAbility:GetAbilityKeyValues()
                if vals.AbilityType ~= "DOTA_ABILITY_TYPE_ATTRIBUTES" then
                    if tAbilities[sAbility] == nil then
                        tAbilities[sAbility] = {}
                        if vals.AbilitySpecial ~= nil then
                            for k,v in pairs(vals.AbilitySpecial) do
                                for j,l in pairs(v) do
                                    if BsrpgPlugin:BlocksKV(sAbility,j) then
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
                                if BsrpgPlugin:BlocksKV(sAbility,k) then
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
    

    BsrpgPlugin.lists[iPlayer] = tOldAbilities
    for k,v in pairs(BsrpgPlugin.lists[iPlayer]) do
        CustomNetTables:SetTableValue("bsrpg_upgrades_" .. iPlayer,k,v)
    end
--[[     for k,v in pairs(deleted) do
        if v then
            CustomNetTables:SetTableValue("bsrpg_upgrades_" .. iPlayer,k,{})
        end
    end ]]
    if BsrpgPlugin.points[iPlayer] == nil then
        BsrpgPlugin.points[iPlayer] = 0
        CustomNetTables:SetTableValue("bsrpg_upgrades_" .. iPlayer,"player_details",{points = BsrpgPlugin.points[iPlayer]})
    end
    --DeepPrintTable(BsrpgPlugin.lists[iPlayer])
end

function BsrpgPlugin:IsBlocked(k,v)
    return false
end
    
function BsrpgPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        Timers:CreateTimer(0,function()
            if BsrpgPlugin.unit_cache[event.entindex] ~= nil then return end
            BsrpgPlugin.unit_cache[event.entindex] = true
            local iPlayer = hUnit:GetPlayerOwnerID()
            if iPlayer < 0 then return end
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer == nil then return end
            local hHero = hPlayer:GetAssignedHero()
            --print("adding ",event.entindex)
            if hHero == nil then
                --print("hero was nill")
                return
            end
            if hHero ~= hUnit then 
                --print("hero was not unit")
                return
            end
            BsrpgPlugin:UpdatePlayer_NetTable(iPlayer)
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_bsrpg",{})
            --print("all should be good")
            BsrpgPlugin.modifier_links[iPlayer] = hModifier
        end)
    end
end


function BsrpgPlugin:boost_player(tEvent)
    local iPlayer = tEvent.PlayerID
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then return end
    local sAbility = tEvent.ability
    local sKey = tEvent.key
    local fValue = tonumber(tEvent.value)
    if BsrpgPlugin.lists[iPlayer] == nil then
        --print(iPlayer,"list nil")
        return
    end
    if BsrpgPlugin.lists[iPlayer][sAbility] == nil then
        --print(iPlayer,"ability list nil")
        return
    end
    if BsrpgPlugin.lists[iPlayer][sAbility][sKey] == nil then
        --print(iPlayer,"key in ability list nil")
        return
    end
    
    if BsrpgPlugin.settings.points_mode then
        if BsrpgPlugin.points[iPlayer] == nil then
            BsrpgPlugin.points[iPlayer] = 0
        end
        local fOld = BsrpgPlugin.lists[iPlayer][sAbility][sKey]
        local fMult = BsrpgPlugin:NerfsKV(sAbility,sKey)
        local fUp = 0.2 * fMult
        local fDown = 0.05 * fMult


        if BsrpgPlugin.settings.allow_reallocation then
            if fOld > 1.001 then
                if fValue > 0 then
                    if BsrpgPlugin.points[iPlayer] == 0 then return end
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld + fUp
                    BsrpgPlugin.points[iPlayer] = BsrpgPlugin.points[iPlayer] - 1
                else
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld - fUp
                    BsrpgPlugin.points[iPlayer] = BsrpgPlugin.points[iPlayer] + 1
                end
            elseif fOld < 0.999 then
                if fValue > 0 then
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld + fDown
                    BsrpgPlugin.points[iPlayer] = BsrpgPlugin.points[iPlayer] + 1
                else
                    if BsrpgPlugin.points[iPlayer] == 0 then return end
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld - fDown
                    BsrpgPlugin.points[iPlayer] = BsrpgPlugin.points[iPlayer] - 1
                end
            else
                if BsrpgPlugin.points[iPlayer] == 0 then return end
                if fValue > 0 then
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld + fUp
                    BsrpgPlugin.points[iPlayer] = BsrpgPlugin.points[iPlayer] - 1
                else
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld - fDown
                    BsrpgPlugin.points[iPlayer] = BsrpgPlugin.points[iPlayer] - 1
                end
            end
        else
            if BsrpgPlugin.points[iPlayer] == 0 then return end
            if fOld > 1.001 then
                if fValue > 0 then
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld + fUp
                else
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld - fUp
                end
            elseif fOld < 0.999 then
                if fValue > 0 then
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld + fDown
                else
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld - fDown
                end
            else
                if fValue > 0 then
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld + fUp
                else
                    BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fOld - fDown
                end
            end
            BsrpgPlugin.points[iPlayer] = BsrpgPlugin.points[iPlayer] - 1
        end
        CustomNetTables:SetTableValue("bsrpg_upgrades_" .. iPlayer,"player_details",{points = BsrpgPlugin.points[iPlayer]})
    else
        BsrpgPlugin.lists[iPlayer][sAbility][sKey] = fValue
    end
    CustomNetTables:SetTableValue("bsrpg_upgrades_" .. iPlayer,sAbility,BsrpgPlugin.lists[iPlayer][sAbility])

    if BsrpgPlugin.modifier_links[iPlayer] == nil then
        --print(iPlayer,"modifier is nil")
        return
    end
    local hMod = BsrpgPlugin.modifier_links[iPlayer]
    if hMod.UpdateValue ~= nil then
        hMod:UpdateValue(sAbility,sKey,BsrpgPlugin.lists[iPlayer][sAbility][sKey])
    else
        --print("could not update modifier")
    end
end
function BsrpgPlugin:periodic_check_all()
    for i=0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayer(i) then
            local player = PlayerResource:GetPlayer(i)
            if player ~= nil then
                BsrpgPlugin:periodic_check(i)
            end
        end
    end
end
function BsrpgPlugin:periodic_check(iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then return end
    if BsrpgPlugin.perdiodic_check_stats == nil then BsrpgPlugin.perdiodic_check_stats = {} end
    local str = hHero:GetStrength()
    local int = hHero:GetIntellect()
    local agi = hHero:GetAgility()
    if BsrpgPlugin.perdiodic_check_stats[iPlayer] == nil then
        BsrpgPlugin.perdiodic_check_stats[iPlayer] = {
            str = str,
            int = int,
            agi = agi
        }
    else
        if  BsrpgPlugin.perdiodic_check_stats[iPlayer].str == str and
            BsrpgPlugin.perdiodic_check_stats[iPlayer].int == int and
            BsrpgPlugin.perdiodic_check_stats[iPlayer].agi == agi 
        then
            return
        end
    end
    --DeepPrintTable(BsrpgPlugin.perdiodic_check_stats[iPlayer])

    if BsrpgPlugin.lists[iPlayer] == nil then
        --print(iPlayer,"list nil")
        return
    end

    if BsrpgPlugin.modifier_links[iPlayer] == nil then
        --print(iPlayer,"modifier is nil")
        return
    end
    local hMod = BsrpgPlugin.modifier_links[iPlayer]
    if hMod.UpdateValue == nil then
        --print("could not update modifier")
        return
    end
    local fMultSetting = BsrpgPlugin.settings.percent_per_attributes * 0.01
    for k,_ in pairs(BsrpgPlugin.lists[iPlayer]) do
        for j,v in pairs(BsrpgPlugin.lists[iPlayer][k]) do
            if BsrpgPlugin.lists[iPlayer][k][j].attribute == DOTA_ATTRIBUTE_STRENGTH then
                BsrpgPlugin.lists[iPlayer][k][j].value = BsrpgPlugin:NerfsKV(k,j) * fMultSetting * str + 1.0
            elseif BsrpgPlugin.lists[iPlayer][k][j].attribute == DOTA_ATTRIBUTE_AGILITY then
                BsrpgPlugin.lists[iPlayer][k][j].value = BsrpgPlugin:NerfsKV(k,j) * fMultSetting * agi + 1.0
            elseif BsrpgPlugin.lists[iPlayer][k][j].attribute == DOTA_ATTRIBUTE_INTELLECT then
                BsrpgPlugin.lists[iPlayer][k][j].value = BsrpgPlugin:NerfsKV(k,j) * fMultSetting * int + 1.0
            end
            hMod:UpdateValue(k,j,BsrpgPlugin.lists[iPlayer][k][j].value)
        end
        CustomNetTables:SetTableValue("bsrpg_upgrades_" .. iPlayer,k,BsrpgPlugin.lists[iPlayer][k])
    end
end

function BsrpgPlugin:BlocksAbility(sAbility) -- returns false if blocked
    if BsrpgPlugin.kv_lists.blocklist == nil then return true end
    if BsrpgPlugin.kv_lists.blocklist.all == nil then return true end
    if BsrpgPlugin.kv_lists.blocklist.all[sAbility] == nil then return true end
    return false
end
function BsrpgPlugin:BlocksKV(sAbility,sKey) -- returns false if blocked
    --no block list
    if BsrpgPlugin.kv_lists.blocklist == nil then return true end
    --check specific ability + kv
    if BsrpgPlugin.kv_lists.blocklist[sAbility] ~= nil and BsrpgPlugin.kv_lists.blocklist[sAbility][sKey] ~= nil then
        return false
    end
    --check specific all + kv
    if BsrpgPlugin.kv_lists.blocklist.all ~= nil and BsrpgPlugin.kv_lists.blocklist.all[sKey] ~= nil then return false end
    
    --check specific wildcard + kv
    for k,v in pairs(BsrpgPlugin.kv_lists.blocklist.wildcard) do
        if string.find(sKey,k) ~= nil then
            return false
        end
    end
    return true
end

function BsrpgPlugin:NerfsKV(sAbility,sKey) -- returns 1.0 if normal.
    --no block list
    if BsrpgPlugin.kv_lists.nerflist == nil then return 1.0 end
    --check specific ability + kv
    if BsrpgPlugin.kv_lists.nerflist[sAbility] ~= nil and BsrpgPlugin.kv_lists.nerflist[sAbility][sKey] ~= nil then
        return BsrpgPlugin.kv_lists.nerflist[sAbility][sKey]
    end
    --check specific all + kv
    if BsrpgPlugin.kv_lists.nerflist.all ~= nil and BsrpgPlugin.kv_lists.nerflist.all[sKey] ~= nil then return BsrpgPlugin.kv_lists.nerflist.all[sKey] end
    
    --check specific wildcard + kv
    for k,v in pairs(BsrpgPlugin.kv_lists.nerflist.wildcard) do
        if string.find(sKey,k) ~= nil then
            return v
        end
    end
    return 1.0
end

function BsrpgPlugin:BotLevelup(iPlayer)
    local iCount = BsrpgPlugin.points[iPlayer]
    local tAbilities = BsrpgPlugin.lists[iPlayer]
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
        BsrpgPlugin:boost_player(tEvent)
    end
end