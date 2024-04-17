RoundsPlugin = class({})
_G.RoundsPlugin = RoundsPlugin
RoundsPlugin.heroes = {}
RoundsPlugin.hero_hashtable = {}
RoundsPlugin.pending_players = {}
RoundsPlugin.playing_teams = {}
RoundsPlugin.towers = {}
RoundsPlugin.defence_team = -1
RoundsPlugin.current_round = 0

ROUNDS_STATE_NOT_STARTED = 0
ROUNDS_STATE_PREPARATION = 1
ROUNDS_STATE_ROUND_ACTIVE = 2
ROUNDS_STATE_ROUND_END = 3
ROUNDS_STATE_MATCH_END = 4

RoundsPlugin.current_state = ROUNDS_STATE_NOT_STARTED
RoundsPlugin.round_end_time = -1

RoundsPlugin.round_data = {}

function RoundsPlugin:Init()
    print("[RoundsPlugin] found")
end

function RoundsPlugin:ApplySettings()
    RoundsPlugin.settings = PluginSystem:GetAllSetting("rounds")
    LinkLuaModifier( "modifier_rounds_core", "plugin_system/plugins/rounds/modifiers/modifier_rounds_core", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "modifier_rounds_wait", "plugin_system/plugins/rounds/modifiers/modifier_rounds_wait", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "modifier_rounds_tower_protect", "plugin_system/plugins/rounds/modifiers/modifier_rounds_tower_protect", LUA_MODIFIER_MOTION_NONE )
    

    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        RoundsPlugin:SpawnEvent(event)
    end,nil)
    
    ListenToGameEvent("entity_killed", function(event)
        RoundsPlugin:DeathEvent(event)
    end,nil)


    GameRules:SetHeroRespawnEnabled(false)
end

function RoundsPlugin:PreGame()
    RoundsPlugin.heroes = {}
    RoundsPlugin.hero_hashtable = {}
    RoundsPlugin.pending_players = {}
    RoundsPlugin.playing_teams = {}
    RoundsPlugin.towers = {}
    RoundsPlugin.defence_team = -1
    RoundsPlugin.current_round = 0
    RoundsPlugin.current_state = ROUNDS_STATE_NOT_STARTED
    RoundsPlugin.round_end_time = -1
    RoundsPlugin.score_radiant = 0
    RoundsPlugin.score_dire = 0
    RoundsPlugin:UpdateRoundData()

    local tTeams = {}
    for iPlayer = 0,DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(iPlayer) then
            RoundsPlugin.pending_players[iPlayer] = true
            RoundsPlugin:PrepHeroForPlayer(iPlayer,0)
        end
    end
end

function RoundsPlugin:PreGame_StageTwo()
    local tTeams = {}
    local ttTeams = {}
    for k,v in pairs(RoundsPlugin.heroes) do
        local hHero = v[2]
        if ttTeams[hHero:GetTeam()] == nil then
            ttTeams[hHero:GetTeam()] = true
            table.insert(tTeams,hHero:GetTeam())
        end
    end
    RoundsPlugin.playing_teams = tTeams
    local k = Toolbox:GetRandomKey(RoundsPlugin.playing_teams)
    RoundsPlugin.defence_team = DOTA_TEAM_BADGUYS -- RoundsPlugin.playing_teams[k]
    RoundsPlugin:PrepRoundStart()
end

function RoundsPlugin:PrepHeroForPlayer(iPlayer,iRetrys)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then
        RoundsPlugin:Retry(iPlayer,iRetrys or 0)
        return
    end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then
        RoundsPlugin:RetryPrepHeroForPlayer(iPlayer,iRetrys or 0)
        return
    end

    local hModifier = hHero:AddNewModifier(hHero,nil,"modifier_rounds_core",{})
    table.insert(RoundsPlugin.heroes,{
        iPlayer,hHero,hModifier
    })
    RoundsPlugin.hero_hashtable[hHero] = true
    RoundsPlugin:NotPending(iPlayer)
end

function RoundsPlugin:NotPending(iiPlayer)
    RoundsPlugin.pending_players[iiPlayer] = false
    for iPlayer = 0,DOTA_MAX_PLAYERS do
        if RoundsPlugin.pending_players[iPlayer] then return end
    end
    RoundsPlugin:PreGame_StageTwo()
end

function RoundsPlugin:GetDataFromHero(hHero)
    for k,v in pairs(RoundsPlugin.heroes) do
        if v[2] == hHero then return v end
    end
    return nil
end

function RoundsPlugin:GetDataFromPlayerHandle(hPlayer)
    return RoundsPlugin:GetDataFromPlayerID(hPlayer:GetPlayerID())
end

function RoundsPlugin:GetDataFromPlayerID(iPlayer)
    for k,v in pairs(RoundsPlugin.heroes) do
        if v[1] == iPlayer then return v end
    end
    return nil
end

function RoundsPlugin:GetDataFromModifier(hModifier)
    for k,v in pairs(RoundsPlugin.heroes) do
        if v[3] == hModifier then return v end
    end
    return nil
end

function RoundsPlugin:RetryPrepHeroForPlayer(iPlayer,iRetrys)
    iRetrys = iRetrys + 1
    if iRetrys > 15 then
        print("[RoundsPlugin] player " .. iPlayer .. " could not be initialized [RetryPrepHeroForPlayer]")
        return
    end
    Timers:CreateTimer(1,function() RoundsPlugin:PrepHeroForPlayer(iPlayer,iRetrys) end)
end

function RoundsPlugin:PrepRoundStart()

    RoundsPlugin.current_state = ROUNDS_STATE_PREPARATION
    RoundsPlugin:UpdateRoundData()
    RoundsPlugin:CleanupHeroes()
    RoundsPlugin:CleanupTowers()
    RoundsPlugin:CleanupMap()
    RoundsPlugin:SpawnTowers()

    Timers:CreateTimer(RoundsPlugin.settings.pre_round_time,function() RoundsPlugin:StartRound() end)
end

function RoundsPlugin:CleanupTowers()
    if RoundsPlugin.towers[1] ~= nil and RoundsPlugin.towers[1].RemoveSelf ~= nil then
        UTIL_RemoveImmediate(RoundsPlugin.towers[1])
    end
    if RoundsPlugin.towers[2] ~= nil and RoundsPlugin.towers[2].RemoveSelf ~= nil then
        UTIL_RemoveImmediate(RoundsPlugin.towers[2])
    end
    RoundsPlugin.towers[1] = nil
    RoundsPlugin.towers[2] = nil
end

function RoundsPlugin:CleanupHeroes()
    local iTargetLevel = 2 + (RoundsPlugin.current_round*2)
    for k,v in pairs(RoundsPlugin.heroes) do
        local hHero = v[2]
        hHero:RespawnHero(false,false)
        for i = 0, hHero:GetAbilityCount()-1 do 
            local hAbility = hHero:GetAbilityByIndex(i)
            if hAbility ~= nil then
                hAbility:RefreshCharges()
                hAbility:RefreshIntrinsicModifier()
                hAbility:EndCooldown()
            end
        end
        
        for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_NEUTRAL_SLOT do
            local hItem = hHero:GetItemInSlot(i)
            if hItem ~= nil then
                hItem:RefreshCharges()
                hItem:RefreshIntrinsicModifier()
                hItem:EndCooldown()
            end
        end
        local hModifier = hHero:AddNewModifier(hHero,nil,"modifier_rounds_wait",{
            duration= RoundsPlugin.settings.pre_round_time
        })
        local iLevel = hHero:GetLevel()
        while iLevel < iTargetLevel do
            hHero:HeroLevelUp(false)
            iLevel = iLevel + 1
        end
        hHero:ModifyGold(RoundsPlugin.settings.gold_per_round,true,DOTA_ModifyGold_GameTick)
    end
end

function RoundsPlugin:SpawnTowers()
    local sUnit = "npc_dota_tower_rounds"
    local vPos1
    local vPos2
    if RoundsPlugin.defence_team == DOTA_TEAM_GOODGUYS then
        vPos1 = Vector(1130,-3706,264)
        vPos2 = Vector(-3810,-802,264)
    end
    if RoundsPlugin.defence_team == DOTA_TEAM_BADGUYS then
        vPos1 = Vector(2914,-195,264)
        vPos2 = Vector(-1661,2985,264)
    end
    print("tower spawning")
    hTower1 = CreateUnitByName(sUnit,vPos1,false,nil,nil,RoundsPlugin.defence_team)
    local hModifier = hTower1:AddNewModifier(hTower1,nil,"modifier_rounds_tower_protect",{health = 666})
    RoundsPlugin.towers[1] = hTower1

    
    hTower2 = CreateUnitByName(sUnit,vPos2,false,nil,nil,RoundsPlugin.defence_team)
    local hModifier = hTower2:AddNewModifier(hTower2,nil,"modifier_rounds_tower_protect",{health = 666})
    RoundsPlugin.towers[2] = hTower2
end

function RoundsPlugin:CleanupMap()
    local e = Entities:Next(nil)
    while e do
        if e.GetUnitName == nil then goto cleanupmap_skip end
        if not e:IsBaseNPC() then goto cleanupmap_skip end
        if RoundsPlugin.hero_hashtable[e] ~= nil then goto cleanupmap_skip end

        if e:IsSummoned() then
            e:Destroy()
            goto cleanupmap_skip
        end

        if e:IsIllusion() then
            e:Destroy()
            goto cleanupmap_skip
        end


        if e:IsWard() then
            e:Destroy()
            goto cleanupmap_skip
        end


        if e:IsHeroWard() then
            e:Destroy()
            goto cleanupmap_skip
        end


        if e:IsCreep() then
            e:Destroy()
            goto cleanupmap_skip
        end


        if e:IsCreature() then
            e:Destroy()
            goto cleanupmap_skip
        end
        
        if e:IsPhantom() then
            e:Destroy()
            goto cleanupmap_skip
        end
        
        
        ::cleanupmap_skip::
        e = Entities:Next(e)
    end
end

function RoundsPlugin:StartRound()
    RoundsPlugin.current_state = ROUNDS_STATE_ROUND_ACTIVE
    RoundsPlugin.round_end_time = GameRules:GetGameTime()+RoundsPlugin.settings.round_time
    RoundsPlugin:UpdateRoundData()
    Timers:CreateTimer(1,function() RoundsPlugin:RoundTick() end)
end

function RoundsPlugin:RoundTick()
    if RoundsPlugin.current_state ~= ROUNDS_STATE_ROUND_ACTIVE then return end
    if RoundsPlugin.round_end_time > GameRules:GetGameTime() then return 1 end
    RoundsPlugin:RoundEnd(RoundsPlugin.defence_team)
end

function RoundsPlugin:DeathEvent(tEvent)
	local attackerUnit = tEvent.entindex_attacker and EntIndexToHScript(tEvent.entindex_attacker)
	local killedUnit = tEvent.entindex_killed and EntIndexToHScript(tEvent.entindex_killed)
    if killedUnit.IsBaseNPC and killedUnit:IsBaseNPC() then
        if killedUnit:IsRealHero() then
            local tData = RoundsPlugin:GetDataFromHero(killedUnit)
            if tData == nil then
                print("no data for hero? was it a bear?")
                return
            end
            if killedUnit:IsReincarnating() then return end
            RoundsPlugin:CheckLastManStanding()
        end
        if killedUnit:IsTower() then
            if killedUnit:HasModifier("modifier_rounds_tower_protect") then
                RoundsPlugin:RoundEnd(attackerUnit:GetTeam())
            end
        end
    end
end

function RoundsPlugin:CheckLastManStanding()
    local iTeamVictor = -1
    print("checking last man standing")
    for k,v in pairs(RoundsPlugin.heroes) do
        local hHero = v[2]
        if hHero:IsAlive() or hHero:IsReincarnating() then
            print("we found live one on team ", hHero:GetTeam())
            if iTeamVictor == -1 or iTeamVictor == hHero:GetTeam() then
                iTeamVictor = hHero:GetTeam() --we have one surviving team at least
            else
                return --we have more than 1 surviving team, game should not be over
            end
        end
    end
    if iTeamVictor == -1 then --we have no surviving team ???
        print("draw?!")
        RoundsPlugin:EndRound(iTeamVictor)
        return
    end

    if RoundsPlugin.settings.extra_objective_towers and RoundsPlugin.settings.extra_objective_towers_require then
        --check for offending team in case they need to destroy tower.
        if iTeamVictor ~= RoundsPlugin.defence_team then
            print("offfence needs to kill the tower still ", iTeamVictor)
            return
        end
    end
    print("we found winning team ", iTeamVictor)
    RoundsPlugin:EndRound(iTeamVictor)
end

function RoundsPlugin:EndRound(iTeamVictor)
    if iTeamVictor == DOTA_TEAM_BADGUYS then
        RoundsPlugin.score_dire = RoundsPlugin.score_dire + 1
    elseif iTeamVictor == DOTA_TEAM_GOODGUYS then
        RoundsPlugin.score_radiant = RoundsPlugin.score_radiant + 1
    end
    RoundsPlugin.current_state = ROUNDS_STATE_ROUND_END
    RoundsPlugin:UpdateRoundData()
    Timers:CreateTimer(5,function() RoundsPlugin:EndRound_Stage2() end)
end

function RoundsPlugin:EndRound_Stage2()
    local midpoint = math.floor(RoundsPlugin.settings.max_rounds / 2)
    local remaining = RoundsPlugin.settings.max_rounds - RoundsPlugin.current_round
    local score_dif = math.abs(RoundsPlugin.score_dire-RoundsPlugin.score_radiant)
    if score_dif > remaining then
        if RoundsPlugin.score_dire > RoundsPlugin.score_radiant then
            RoundsPlugin:EndMatch(DOTA_TEAM_BADGUYS)
        elseif RoundsPlugin.score_dire > RoundsPlugin.score_radiant then
            RoundsPlugin:EndMatch(DOTA_TEAM_GOODGUYS)
        else
            RoundsPlugin.settings.max_rounds = RoundsPlugin.settings.max_rounds + 1
        end
    end

    RoundsPlugin.current_round = RoundsPlugin.current_round + 1
    if RoundsPlugin.settings.alternate_mode then
        if RoundsPlugin.defence_team == DOTA_TEAM_BADGUYS then
            RoundsPlugin.defence_team = DOTA_TEAM_GOODGUYS
        else
            RoundsPlugin.defence_team = DOTA_TEAM_BADGUYS
        end
    else
        if RoundsPlugin.current_round == midpoint then
            if RoundsPlugin.defence_team == DOTA_TEAM_BADGUYS then
                RoundsPlugin.defence_team = DOTA_TEAM_GOODGUYS
            else
                RoundsPlugin.defence_team = DOTA_TEAM_BADGUYS
            end
        end
    end


    Timers:CreateTimer(5,function() RoundsPlugin:PrepRoundStart() end)
end

function RoundsPlugin:EndMatch(iTeamVictor)
    GameRules:SetCustomGameEndDelay(30.0)
    GameRules:SetGameWinner(iTeamVictor)
end

function RoundsPlugin:RestartMatch()

end

function RoundsPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end

    if hUnit:IsRealHero() then

    end
end

function RoundsPlugin:UpdateRoundData()
    RoundsPlugin.round_data = {
        defence_team = RoundsPlugin.defence_team,
        current_round = RoundsPlugin.current_round,
        max_rounds = RoundsPlugin.settings.max_rounds,
        current_state = RoundsPlugin.current_state,
        round_end_time = RoundsPlugin.round_end_time,
        score_radiant = RoundsPlugin.score_radiant,
        score_dire = RoundsPlugin.score_dire,
    }

    CustomNetTables:SetTableValue("rounds","round_data",RoundsPlugin.round_data)
end