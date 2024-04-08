DotaSettingsPlugin = class({})
_G.DotaSettingsPlugin = DotaSettingsPlugin
DotaSettingsPlugin.settings = {}

DotaSettingsPlugin.unit_cache = {}
function DotaSettingsPlugin:Init()
    print("[DotaSettingsPlugin] found")
end

function DotaSettingsPlugin:ApplySettings()
    local gm = GameRules:GetGameModeEntity()
    if gm == nil then
        print("[DotaSettingsPlugin] something went horribly wrong!")
        return
    end
	local contxt = {}

    DotaSettingsPlugin.settings = PluginSystem:GetAllSetting("dota_settings")
	gm:SetDraftingHeroPickSelectTimeOverride(DotaSettingsPlugin.settings.heropick_time)
    --GameRules:SetHeroSelectionTime(DotaSettingsPlugin.settings.heropick_time)
    GameRules:SetStrategyTime(DotaSettingsPlugin.settings.strategy_time)
    --GameRules:SetShowcaseTime(DotaSettingsPlugin.settings.showcase_time)
    GameRules:SetPreGameTime(DotaSettingsPlugin.settings.pregame_time)
    GameRules:SetPostGameTime(15)

--[[     if DotaSettingsPlugin.settings.global_shop then
        local global_shop = SpawnDOTAShopTriggerRadiusApproximate(Vector(0,0,0), 400)
        global_shop:SetShopType(DOTA_SHOP_HOME)
    end ]]
   -- if DotaSettingsPlugin.settings.global_shop then
   -- end

    GameRules:SetTreeRegrowTime(DotaSettingsPlugin.settings.tree_grow_time)
    
    --GameRules:SetUseCustomHeroXPValues(true)

    if DotaSettingsPlugin.settings.max_level ~= 30 then
		GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel( DotaSettingsPlugin.xp_table() )
		GameRules:GetGameModeEntity():SetUseCustomHeroLevels(true)
		GameRules:SetUseCustomHeroXPValues(true)
		GameRules:GetGameModeEntity():SetCustomHeroMaxLevel(DotaSettingsPlugin.settings.max_level)
    end

    
    GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(DotaSettingsPlugin.settings.courier_enabled)
    GameRules:GetGameModeEntity():SetUseTurboCouriers(DotaSettingsPlugin.settings.courier_turbo)
    GameRules:SetUseUniversalShopMode(DotaSettingsPlugin.settings.univeral_Shop)
    for iPlayer = 0,DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(iPlayer) then
            if DotaSettingsPlugin.settings.single_buyback then
                PlayerResource:SetBuybackCooldownTime(iPlayer,99999)
                PlayerResource:SetCustomBuybackCost(iPlayer,0)
            end
        end
    end

    if DotaSettingsPlugin.settings.courier_speed ~= 100 then
        LinkLuaModifier( "modifier_courier_speed", "plugin_system/plugins/dota_settings/modifier_courier_speed", LUA_MODIFIER_MOTION_NONE )
    end

    if DotaSettingsPlugin.settings.xp_gain_percent ~= 100 then
        DotaSettingsPlugin.settings.xp_gain_percent = DotaSettingsPlugin.settings.xp_gain_percent * 0.01
        GameRules:GetGameModeEntity():SetModifyExperienceFilter( DotaSettingsPlugin.ModifyExperienceFilter, contxt )
    end
    if DotaSettingsPlugin.settings.gold_gain_percent ~= 100 then
        DotaSettingsPlugin.settings.gold_gain_percent = DotaSettingsPlugin.settings.gold_gain_percent * 0.01
        GameRules:GetGameModeEntity():SetModifyGoldFilter( DotaSettingsPlugin.ModifyGoldFilter, contxt )
    end
    if DotaSettingsPlugin.settings.death_time_percent ~= 100 then
        --link modifier
        print("[DotaSettingsPlugin] death time is not default")
        --LinkLuaModifier( "modifier_death_percentage", "plugin_system/plugins/dota_settings/modifier_death_percentage", LUA_MODIFIER_MOTION_NONE )
        --register spawn listener to add modifier to heroes on first spawn
	    GameRules:GetGameModeEntity():SetRespawnTimeScale(DotaSettingsPlugin.settings.death_time_percent * 0.01)
    end

    
    if (DotaSettingsPlugin.settings.sell_anywhere == true) then
        GameRules:GetGameModeEntity():SetCanSellAnywhere(DotaSettingsPlugin.settings.sell_anywhere)
    end
    if (DotaSettingsPlugin.settings.allow_neutral_drops == false) then
        GameRules:GetGameModeEntity():SetAllowNeutralItemDrops(DotaSettingsPlugin.settings.allow_neutral_drops)
    end
	--GameRules:GetGameModeEntity():SetBountyRuneSpawnInterval(DotaSettingsPlugin.settings.bounty_rune_spawn_interval)
	--GameRules:GetGameModeEntity():SetPowerRuneSpawnInterval(DotaSettingsPlugin.settings.power_rune_spawn_interval)
	--GameRules:GetGameModeEntity():SetXPRuneSpawnInterval(DotaSettingsPlugin.settings.xp_rune_spawn_interval)
    
    local sBackDoorProtection = DotaSettingsPlugin.settings.backdoor_protection
    GameRules:GetGameModeEntity():SetTowerBackdoorProtectionEnabled(DotaSettingsPlugin.settings.backdoor_protection)

    
    if (DotaSettingsPlugin.settings.allow_buyback == false) then
        GameRules:GetGameModeEntity():SetBuybackEnabled(DotaSettingsPlugin.settings.allow_buyback)
    end
	--GameRules:GetGameModeEntity():SetCustomBackpackCooldownPercent(DotaSettingsPlugin.settings.backback_cooldown)
    --[[local heroId = DOTAGameManager:GetHeroIDByName(DotaSettingsPlugin.settings.force_hero)
     print(DotaSettingsPlugin.settings.force_hero,"is",heroId)
    if (DotaSettingsPlugin.settings.force_hero ~= "none") then
        if DOTAGameManager:GetHeroIDByName(DotaSettingsPlugin.settings.force_hero) ~= -1 then
            GameRules:GetGameModeEntity():SetCustomGameForceHero(DotaSettingsPlugin.settings.force_hero)
        end
    end ]]
	--GameRules:GetGameModeEntity():SetDaynightCycleAdvanceRate(DotaSettingsPlugin.settings.day_night_rate * 0.01)

	GameRules:SetGoldPerTick(DotaSettingsPlugin.settings.gold_per_tick)
	GameRules:SetGoldTickTime(DotaSettingsPlugin.settings.gold_tick)
    GameRules:SetStartingGold(DotaSettingsPlugin.settings.starting_gold)
    if (DotaSettingsPlugin.settings.allow_respawn == false) then
	    GameRules:SetHeroRespawnEnabled(DotaSettingsPlugin.settings.allow_respawn)
    end
    if (DotaSettingsPlugin.settings.allow_samehero == true) then
	    GameRules:SetSameHeroSelectionEnabled(DotaSettingsPlugin.settings.allow_samehero)
    end
    GameRules:SetTreeRegrowTime(DotaSettingsPlugin.settings.tree_grow_time)


    --game mode pick
    local time = 0
    if DotaSettingsPlugin.settings.hero_banning then
        GameRules:SetCustomGameBansPerTeam(5)
        time = 30
    end
    GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(time)
    if ("allrandom"==DotaSettingsPlugin.settings.pick_mode ) then
        GameRules:GetGameModeEntity():SetThink( function()
            for iPlayer = 0,DOTA_MAX_PLAYERS do
                if PlayerResource:IsValidPlayer(iPlayer) then
                    local hPlayer = PlayerResource:GetPlayer(iPlayer)
                    if hPlayer then
                        hPlayer:MakeRandomHeroSelection()
                    end
                end
            end
        end, time)
    elseif ("singledraft"==DotaSettingsPlugin.settings.pick_mode ) then
        GameRules:GetGameModeEntity():SetThink( function()
            local attribute_heroes = {
                {},		-- strength_heroes
                {},		-- agility_heroes
                {},		-- intelligence_heroes
                {}		-- universal
            }
            local hero_definitions = LoadKeyValues('scripts/npc/npc_heroes.txt')
            local file = {}
            local blist = LoadKeyValues('scripts/npc/blist.txt')
            local bmn = GameRules:GetBannedHeroes()
            for k,_ in pairs(hero_definitions) do
                if blist[k] == nil then
                    if not Toolbox:table_contains(bmn, k) then
                        file[k] = 1
                    end
                end
            end
            
            if file == nil or not next(file) then
                print("empty whitelist")
            else
                for hero_name, enabled in pairs(file) do
                    if enabled == 1 then
                        local hero_attribute = hero_definitions[hero_name]["AttributePrimary"]
                        if hero_attribute == "DOTA_ATTRIBUTE_STRENGTH" then
                            table.insert(attribute_heroes[1], hero_name)
                        elseif hero_attribute == "DOTA_ATTRIBUTE_AGILITY" then
                            table.insert(attribute_heroes[2], hero_name)
                        elseif hero_attribute == "DOTA_ATTRIBUTE_INTELLECT" then
                            table.insert(attribute_heroes[3], hero_name)
                        else
                            table.insert(attribute_heroes[4], hero_name)
                        end
                    end
                end

                GameRules:SetHideBlacklistedHeroes(true)
                GameRules:GetGameModeEntity():SetPlayerHeroAvailabilityFiltered( true )
                for p=0,DOTA_MAX_PLAYERS do
                    if PlayerResource:IsValidPlayer(p) then
                        for i=1,4 do
                            local hero_index = Toolbox:GetRandomKey(attribute_heroes[i])
                            local nHeroID = DOTAGameManager:GetHeroIDByName( attribute_heroes[i][hero_index] )
                            GameRules:AddHeroToPlayerAvailability( p, nHeroID )
                            attribute_heroes[i][hero_index] = nil
                        end
                    end
                end
            end
        end, time)
    end


    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        DotaSettingsPlugin:SpawnEvent(event)
end,nil)
end


function DotaSettingsPlugin:ApplySettingsStartGame()
    if DotaSettingsPlugin.settings.agh_shard_time == 15 then return end
    local deltime = GameRules:GetItemStockTime(DOTA_TEAM_GOODGUYS,"item_aghanims_shard",-1)
    if DotaSettingsPlugin.settings.agh_shard_time < deltime then
        Timers:CreateTimer(DotaSettingsPlugin.settings.agh_shard_time*60,function()
            GameRules:SetItemStockCount(5,DOTA_TEAM_GOODGUYS,"item_aghanims_shard",-1)
            GameRules:SetItemStockCount(5,DOTA_TEAM_BADGUYS,"item_aghanims_shard",-1)
        end)
    elseif DotaSettingsPlugin.settings.agh_shard_time > deltime then
        Timers:CreateTimer(deltime+0.01,function()
            GameRules:SetItemStockCount(0,DOTA_TEAM_GOODGUYS,"item_aghanims_shard",-1)
            GameRules:SetItemStockCount(0,DOTA_TEAM_BADGUYS,"item_aghanims_shard",-1)
        end)
        Timers:CreateTimer(DotaSettingsPlugin.settings.agh_shard_time*60,function()
            GameRules:SetItemStockCount(5,DOTA_TEAM_GOODGUYS,"item_aghanims_shard",-1)
            GameRules:SetItemStockCount(5,DOTA_TEAM_BADGUYS,"item_aghanims_shard",-1)
        end)
    end
end

function DotaSettingsPlugin.xp_table()
    local xp_table = {		
        0,
        240,
        640,
        1160,
        1760,
        2440,
        3200,
        4000,
        4900,
        5900,
        7000,
        8200,
        9500,
        10900,
        12400,
        14000,
        15700,
        17500,
        19400,
        21400,
        23600,
        26000,
        28600,
        31400,
        34400,
        38400,
        43400,
        49400,
        56400,
        63900
    }
    if DotaSettingsPlugin.settings.max_level > #xp_table then
        for i = #xp_table + 1, DotaSettingsPlugin.settings.max_level do
            xp_table[i] = xp_table[i - 1] + (300 * ( i - 15 ))
        end
    elseif DotaSettingsPlugin.settings.max_level < #xp_table then
        for i = DotaSettingsPlugin.settings.max_level+1, #xp_table do
            xp_table[i] = nil
        end
    end
    return xp_table
end


function DotaSettingsPlugin:ModifyGoldFilter(event)
    if event.gold == nil then
        print("[DotaSettingsPlugin] modify gold event is fucking up again.")
    end
	event.gold = event.gold * DotaSettingsPlugin.settings.gold_gain_percent
    return true
end

    
function DotaSettingsPlugin:ModifyExperienceFilter(event)
    if event.experience == nil then
        print("[DotaSettingsPlugin] modify experience event is fucking up again.")
    end
	event.experience = event.experience * DotaSettingsPlugin.settings.xp_gain_percent
    return true
end


    
function DotaSettingsPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if DotaSettingsPlugin.settings.death_time_percent ~= 100 then
        if hUnit:IsRealHero() then
            if DotaSettingsPlugin.unit_cache[event.entindex] ~= nil then return end
            DotaSettingsPlugin.unit_cache[event.entindex] = true
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_death_percentage",{stack = DotaSettingsPlugin.settings.death_time_percent})
        end
    end
    
    if DotaSettingsPlugin.settings.courier_speed ~= 100 then
        if hUnit:IsCourier() then
            if DotaSettingsPlugin.unit_cache[event.entindex] ~= nil then return end
            DotaSettingsPlugin.unit_cache[event.entindex] = true
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_courier_speed",{stack = DotaSettingsPlugin.settings.courier_speed})
        end
    end
end


