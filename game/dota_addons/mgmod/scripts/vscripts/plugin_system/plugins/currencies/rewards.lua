
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
            end)
        end
    end, nil)

    
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
        local iRadiant = -1
        local iDire = -1
        for i=0, DOTA_MAX_TEAM_PLAYERS do
            if PlayerResource:IsValidPlayer(i) then
                local hPlayer = PlayerResource:GetPlayer(i)
                if hPlayer ~= nil then
                    local iTeam = PlayerResource:GetTeam(i)
                    if iTeam == DOTA_TEAM_BADGUYS and iDire == -1 then
                        iDire = i
                        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.timed_reward_currency,i,CurrenciesPlugin.settings.timed_reward_amount) 
                    elseif iTeam == DOTA_TEAM_GOODGUYS and iRadiant == -1  then
                        iRadiant = i
                        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.timed_reward_currency,i,CurrenciesPlugin.settings.timed_reward_amount) 
                    end
                end
            end
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
    local iPlayer = attackerUnit:GetMainControllingPlayer()
    if iPlayer < 0 then return end
    if killedUnit-IsRealHero == nil then return end

    if CurrenciesPlugin.settings.unit_kill_reward_amount > 0 and not killedUnit:IsIllusion() and not killedUnit:IsReincarnating() then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.unit_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.unit_kill_reward_amount) 
    end
    if CurrenciesPlugin.settings.hero_kill_reward_amount > 0 and killedUnit:IsRealHero() and not killedUnit:IsReincarnating() then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.hero_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.hero_kill_reward_amount) 
    end
    if CurrenciesPlugin.settings.observer_kill_reward_amount > 0 and killedUnit:GetUnitName() == "npc_dota_observer_wards" then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.observer_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.observer_kill_reward_amount) 
    end
    if CurrenciesPlugin.settings.tower_kill_reward_amount > 0 and killedUnit:IsTower() then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.tower_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.tower_kill_reward_amount) 
    end
    if CurrenciesPlugin.settings.roshan_kill_reward_amount > 0 and killedUnit:GetUnitName() == "npc_dota_roshan" then
        CurrenciesPlugin:AlterCurrency(CurrenciesPlugin.settings.roshan_kill_reward_currency,iPlayer,CurrenciesPlugin.settings.roshan_kill_reward_amount) 
    end
end