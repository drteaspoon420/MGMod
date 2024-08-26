
function CurrenciesPlugin:RewardsInit()
    ListenToGameEvent("entity_killed", function(tEvent)
        CurrenciesPlugin:KillRewards(tEvent)
    end, nil)
    
    ListenToGameEvent("npc_spawned", function(tEvent)
        local hUnit = EntIndexToHScript(tEvent.entindex)
        if not hUnit:IsDOTANPC() then return end
        if CurrenciesPlugin.settings.observer_plant_reward_amount > 0 and hUnit.GetUnitName ~= nil and hUnit:GetUnitName() == "npc_dota_observer_wards" then
            Timers:CreateTimer( 0, function()
                local iPlayer = hUnit:GetMainControllingPlayer()
                if iPlayer == -1 then
                    iPlayer = hUnit:GetPlayerOwnerID()
                end
                if iPlayer == -1 then return end
                CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.observer_plant_reward_currency,iPlayer,CurrenciesPlugin.settings.observer_plant_reward_amount) 
                CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.observer_plant_reward_amount,hUnit,hUnit:GetTeam(),CurrenciesPlugin.settings.observer_plant_reward_currency)
            end)
        end
    end, nil)

    
    ListenToGameEvent("dota_ability_channel_finished", function(tEvent)
        CurrenciesPlugin:ChannelFinished(tEvent)
    end, nil)
    
    
    
end

function CurrenciesPlugin:StartRewards()
    if CurrenciesPlugin.settings.timed_reward_amount > 0 and CurrenciesPlugin.settings.timed_reward_rate > 0 then
        Timers:CreateTimer( CurrenciesPlugin.settings.timed_reward_rate, function()
            return CurrenciesPlugin:TimedReward()
        end)
    end
end

function CurrenciesPlugin:TimedReward()
    local sName = CurrenciesPlugin.settings.timed_reward_currency
    local t = CurrenciesPlugin.currency_data[sName]
    if t.share == 0 then
        for i=0, DOTA_MAX_TEAM_PLAYERS do
            if PlayerResource:IsValidPlayer(i) then
                local hPlayer = PlayerResource:GetPlayer(i)
                if hPlayer ~= nil then
                    CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.timed_reward_currency,i,CurrenciesPlugin.settings.timed_reward_amount) 
                end
            end
        end
    elseif t.share == 1 then
        for i=1,#CurrenciesPlugin.teams do
            local iTeam = CurrenciesPlugin.teams[i]
            CurrenciesPlugin:AlterCurrencyTeam(CurrenciesPlugin.settings.timed_reward_currency,iTeam,CurrenciesPlugin.settings.timed_reward_amount) 
        end
    elseif t.share == 2 then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.timed_reward_currency,0,CurrenciesPlugin.settings.timed_reward_amount) 
    end
    return CurrenciesPlugin.settings.timed_reward_rate
end

function CurrenciesPlugin:KillRewards(tEvent)
	local attackerUnit = tEvent.entindex_attacker and EntIndexToHScript(tEvent.entindex_attacker)
	local killedUnit = tEvent.entindex_killed and EntIndexToHScript(tEvent.entindex_killed)
    if not (killedUnit and attackerUnit) then return end
    if killedUnit:GetTeam() == attackerUnit:GetTeam() then return end
    if killedUnit.IsRealHero == nil then return end
    local iPlayer = attackerUnit:GetMainControllingPlayer()
    if CurrenciesPlugin.currency_data[CurrenciesPlugin.settings.tower_kill_reward_currency].share == 1 then
        if CurrenciesPlugin.settings.tower_kill_reward_amount > 0 and killedUnit:IsTower() then
            local iLeader = attackerUnit:GetTeam()
            CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.tower_kill_reward_currency,iLeader,CurrenciesPlugin.settings.tower_kill_reward_amount)
            CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.tower_kill_reward_amount,killedUnit,iLeader,CurrenciesPlugin.settings.tower_kill_reward_currency)
        end
    elseif (CurrenciesPlugin.currency_data[CurrenciesPlugin.settings.tower_kill_reward_currency].share == 2) then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.tower_kill_reward_currency,0,CurrenciesPlugin.settings.tower_kill_reward_amount)
        CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.tower_kill_reward_amount,killedUnit,0,CurrenciesPlugin.settings.tower_kill_reward_currency)
    end

    if iPlayer < 0 then return end

    if CurrenciesPlugin.currency_data[CurrenciesPlugin.settings.tower_kill_reward_currency].share == 0 then
        if CurrenciesPlugin.settings.tower_kill_reward_amount > 0 and killedUnit:IsTower() then
            CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.tower_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.tower_kill_reward_amount)
            CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.tower_kill_reward_amount,killedUnit,attackerUnit:GetTeam(),CurrenciesPlugin.settings.tower_kill_reward_currency)
        end
    end
    if CurrenciesPlugin.settings.unit_kill_reward_amount > 0 and not killedUnit:IsIllusion() and not killedUnit:IsReincarnating() then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.unit_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.unit_kill_reward_amount)
        CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.unit_kill_reward_amount,killedUnit,attackerUnit:GetTeam(),CurrenciesPlugin.settings.unit_kill_reward_currency)
    end
    if CurrenciesPlugin.settings.hero_kill_reward_amount > 0 and killedUnit:IsRealHero() and not killedUnit:IsReincarnating() then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.hero_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.hero_kill_reward_amount)
        CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.hero_kill_reward_amount,killedUnit,attackerUnit:GetTeam(),CurrenciesPlugin.settings.hero_kill_reward_currency)
    end
    if CurrenciesPlugin.settings.observer_kill_reward_amount > 0 and killedUnit:GetUnitName() == "npc_dota_observer_wards" then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.observer_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.observer_kill_reward_amount)
        CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.observer_kill_reward_amount,killedUnit,attackerUnit:GetTeam(),CurrenciesPlugin.settings.observer_kill_reward_currency)
    end
    if CurrenciesPlugin.settings.roshan_kill_reward_amount > 0 and killedUnit:GetUnitName() == "npc_dota_roshan" then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.roshan_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.roshan_kill_reward_amount)
        CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.roshan_kill_reward_amount,killedUnit,attackerUnit:GetTeam(),CurrenciesPlugin.settings.roshan_kill_reward_currency)
    end
    if CurrenciesPlugin.settings.tormentor_kill_reward_amount > 0 and killedUnit:GetUnitName() == "npc_dota_miniboss" then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.tormentor_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.tormentor_kill_reward_amount)
        CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.tormentor_kill_reward_amount,killedUnit,attackerUnit:GetTeam(),CurrenciesPlugin.settings.tormentor_kill_reward_currency)
    end

end

function CurrenciesPlugin:ChannelFinished(tEvent)
	local hCaster = tEvent.caster_entindex and EntIndexToHScript(tEvent.caster_entindex)
    if hCaster == nil then return end
    if tEvent.interrupted ~= 0 then return end
    local iPlayer = hCaster:GetMainControllingPlayer()
    if iPlayer > -1 then
        if tEvent.abilityname == "ability_lamp_use" then
            CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.lamp_capture_reward_currency,iPlayer,CurrenciesPlugin.settings.lamp_capture_reward_amount)
            CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.lamp_capture_reward_amount,hCaster,hCaster:GetTeam(),CurrenciesPlugin.settings.lamp_capture_reward_currency)
        end
        if tEvent.abilityname == "ability_capture" then
            CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.outpost_capture_reward_currency,iPlayer,CurrenciesPlugin.settings.outpost_capture_reward_amount)
            CurrenciesPlugin:ShowEarnParticle(CurrenciesPlugin.settings.outpost_capture_reward_amount,hCaster,hCaster:GetTeam(),CurrenciesPlugin.settings.outpost_capture_reward_currency)
        end
    end
end

function CurrenciesPlugin:ModifyGoldFilter(tEvent)
    if tEvent.gold == nil then
        print("[CurrenciesPlugin] modify gold event is fucking up again.")
    end
    
    if tEvent.reason_const == DOTA_ModifyGold_HeroKill and CurrenciesPlugin.settings.hero_kill_reward_bounty > 0 then
        local iReward = math.floor(tEvent.gold * CurrenciesPlugin.settings.hero_kill_reward_bounty / 100)
        if iReward > 0 then
            CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.hero_kill_reward_currency,tEvent.player_id_const,iReward)
            local iPlayer = PlayerResource:GetPlayer(tEvent.player_id_const)
            local hUnit = iPlayer and iPlayer:GetAssignedHero()
            if hUnit then
                CurrenciesPlugin:ShowEarnParticle(iReward,hUnit,hUnit:GetTeam(),CurrenciesPlugin.settings.hero_kill_reward_currency)
            end
        end
    end
    return {true, tEvent}
end