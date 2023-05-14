StonksPlugin = class({})
_G.StonksPlugin = StonksPlugin
StonksPlugin.settings = {}


STONKS_TABLE = {
	stonks_admg = {},
	stonks_agi = {},
	stonks_amp = {},
	stonks_atck = {},
	stonks_bad = {},
	stonks_evc = {},
	stonks_hp = {},
	stonks_hrc = {},
	stonks_hrp = {},
	stonks_int = {},
	stonks_mp = {},
	stonks_mr = {},
	stonks_mrc = {},
	stonks_mrp = {},
	stonks_msbc = {},
	stonks_msbp = {},
	stonks_pab = {},
	stonks_pbdm = {},
	stonks_pbdp = {},
	stonks_sr = {},
	stonks_str = {},
	stonks_tdop = {},
	stonks_crp = {},
	stonks_mcr = {},
	stonks_icdp = {},
	stonks_crb = {},
	stonks_arb = {},
    stonks_bnv = {},
    stonks_bdv = {},
	stonks_exp = {},
}

function StonksPlugin:Init()
    print("[StonksPlugin] found")
end

function StonksPlugin:ApplySettings()
    StonksPlugin.settings = PluginSystem:GetAllSetting("stonks")

    if StonksPlugin.settings.min_start_cost > StonksPlugin.settings.max_start_cost then
        local x = StonksPlugin.settings.min_start_cost
        StonksPlugin.settings.min_start_cost = StonksPlugin.settings.max_start_cost
        StonksPlugin.settings.max_start_cost = x
    end
    if StonksPlugin.settings.min_start_left > StonksPlugin.settings.max_start_left then
        local x = StonksPlugin.settings.min_start_left
        StonksPlugin.settings.min_start_left = StonksPlugin.settings.max_start_left
        StonksPlugin.settings.max_start_left = x
    end
    CustomGameEventManager:RegisterListener( "stonk_buy", function(eventSourceIndex,keys) StonksPlugin:Buy(keys.PlayerID,keys.stonk,keys.amount) end)
    CustomGameEventManager:RegisterListener( "stonk_sell", function(eventSourceIndex,keys) StonksPlugin:Sell(keys.PlayerID,keys.stonk,keys.amount) end)
    self:Hooks()
    for k,v in pairs(STONKS_TABLE) do
        v.price = RandomInt(StonksPlugin.settings.min_start_cost,StonksPlugin.settings.max_start_cost)
        v.total = RandomInt(StonksPlugin.settings.min_start_left,StonksPlugin.settings.max_start_left)
        v.available = v.total
        STONKS_TABLE[k] = v
        
        LinkLuaModifier(k, "plugin_system/plugins/stonks/modifiers/" .. k, LUA_MODIFIER_MOTION_NONE)
        CustomNetTables:SetTableValue("stonks",k,v)
    end
    
    
    Timers:CreateTimer( StonksPlugin.RandomTimer)
    print('stonks fully initiated')

end

function StonksPlugin:RandomTimer()
	StonksPlugin:RandomAll()
	return StonksPlugin.settings.timer
end

function StonksPlugin:Hooks()
    ListenToGameEvent("entity_killed", function(keys)
        local killedUnit = EntIndexToHScript(keys.entindex_killed)
        local attackerUnit = EntIndexToHScript(keys.entindex_attacker)
        if killedUnit:IsRealHero() and not killedUnit:IsTempestDouble() and not killedUnit:IsReincarnating() then
            StonksPlugin:HeroScore(killedUnit,-StonksPlugin.settings.hero_effect)
        end
        if attackerUnit:IsRealHero() and not attackerUnit:IsTempestDouble() then
            local severity = StonksPlugin.settings.unit_effect
            if killedUnit:IsRealHero() and not killedUnit:IsTempestDouble() and not killedUnit:IsReincarnating() then
                severity = StonksPlugin.settings.hero_effect
            end
            StonksPlugin:HeroScore(attackerUnit,severity)
        end
        
        if killedUnit:IsTower() then
            local iTeam = killedUnit:GetTeam()
            severity = StonksPlugin.settings.tower_effect
            for p=0,DOTA_MAX_PLAYERS do
                if (PlayerResource:IsValidTeamPlayer(p)) then
                    local player = PlayerResource:GetPlayer(p)
                    local hHero = player:GetAssignedHero()
                    if iTeam == hHero:GetTeam() then
                        StonksPlugin:HeroScore(hHero,severity*-1)
                    else
                        StonksPlugin:HeroScore(hHero,severity)
                    end
                end
            end
        end
    end, nil)
end

function StonksPlugin:SendStateAll()
    for k,v in pairs(STONKS_TABLE) do
        self:SendState(k)
    end
end

function StonksPlugin:SendState(stonk)
    CustomNetTables:SetTableValue("stonks",stonk,STONKS_TABLE[stonk])
    --CustomGameEventManager:Send_ServerToAllClients("stonk_status", {stonk = stonk, price = math.floor(STONKS_TABLE[stonk].price), available = STONKS_TABLE[stonk].available} )
end

function StonksPlugin:Buy(playerID,stonk,ammount)
	local player = PlayerResource:GetPlayer(playerID)
	local gold = PlayerResource:GetGold(playerID)
	local hHero = player:GetAssignedHero()

    if not hHero:IsAlive() then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "show_center_message", { message = "Cannot buy while dead." })
        return
    end

    if not (not StonksPlugin.settings.fountain or hHero:HasModifier("modifier_fountain_aura_buff")) then
        return
    end
    
    local will_buy = math.floor(gold / math.floor(STONKS_TABLE[stonk].price))
    if (STONKS_TABLE[stonk].available < will_buy) then
        will_buy = STONKS_TABLE[stonk].available
    end
    if ammount < will_buy then
        will_buy = ammount
    end
    if will_buy == 0 then return end
    local gold_spent = will_buy * math.floor(STONKS_TABLE[stonk].price)
    STONKS_TABLE[stonk].available = STONKS_TABLE[stonk].available - will_buy
    hHero:SpendGold(gold_spent,DOTA_ModifyGold_PurchaseItem)
    hHero:AddNewModifier(hHero,nil,stonk,{stack = will_buy})
    self:SendState(stonk)
    local sName = PlayerResource:GetSelectedHeroName(playerID)
    print(PlayerResource:GetPlayerName(playerID),playerID)
    local iTeam = player:GetTeam()
    GameRules:SendCustomMessageToTeam("" .. sName .. " <font color='#33ff33'>bought</font> " .. will_buy .. " " .. string.upper(string.sub(stonk, 8)),iTeam,playerID,playerID)
end

function StonksPlugin:Sell(playerID,stonk,ammount)
	local player = PlayerResource:GetPlayer(playerID)
	local gold = PlayerResource:GetGold(playerID)
	local hHero = player:GetAssignedHero()
    

    if not hHero:IsAlive() then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "show_center_message", { message = "Cannot sell while dead." })
        return
    end

    if not (not StonksPlugin.settings.fountain or hHero:HasModifier("modifier_fountain_aura_buff")) then
        return
    end
    if not hHero:HasModifier(stonk) then return end
    hModifier = hHero:FindModifierByName(stonk)
    local stack = hModifier:GetStackCount()
    if stack < ammount then
        ammount = stack
    end
    if ammount == 0 then return end
    local gold_gained = ammount * math.floor(STONKS_TABLE[stonk].price)
    if (gold_gained + gold) > 99999 then
        local remaining = 99999 - gold
        ammount = math.floor(remaining / math.floor(STONKS_TABLE[stonk].price))
        if (ammount == 0) then
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "show_center_message", { message = "You have max money." })
            return
        end
        gold_gained = ammount * math.floor(STONKS_TABLE[stonk].price)
    end
    STONKS_TABLE[stonk].available = STONKS_TABLE[stonk].available + ammount
    hHero:ModifyGold(gold_gained,true,DOTA_ModifyGold_SellItem)
    hHero:AddNewModifier(hHero,nil,stonk,{stack = ammount * -1})
    self:SendState(stonk)
    local sName = PlayerResource:GetSelectedHeroName(playerID)
    local iTeam = player:GetTeam()
    GameRules:SendCustomMessageToTeam("" .. sName .. " <font color='#ff3333'>sold</font> " .. ammount .. " " .. string.upper(string.sub(stonk, 8)),iTeam,playerID,playerID)
end

function StonksPlugin:Score(stonk,ammount,severity)
    STONKS_TABLE[stonk].price = math.floor(STONKS_TABLE[stonk].price + (ammount/STONKS_TABLE[stonk].total)*severity)
    if STONKS_TABLE[stonk].price < StonksPlugin.settings.min_stonk_price then STONKS_TABLE[stonk].price = StonksPlugin.settings.min_stonk_price end
    self:SendState(stonk)
end

function StonksPlugin:HeroScore(hHero,severity)
    for k,v in pairs(STONKS_TABLE) do
        if hHero:HasModifier(k) then
            hModifier = hHero:FindModifierByName(k)
            local ammount = hModifier:GetStackCount()
            self:Score(k,ammount,severity)
        end
    end
end


function StonksPlugin:RandomAll()
    for k,v in pairs(STONKS_TABLE) do
        self:Random(k)
    end
end

function StonksPlugin:Random(stonk)
    STONKS_TABLE[stonk].price = math.floor(STONKS_TABLE[stonk].price + RandomFloat(-StonksPlugin.settings.stonks_random_effect,StonksPlugin.settings.stonks_random_effect))
    if STONKS_TABLE[stonk].price < StonksPlugin.settings.min_stonk_price then STONKS_TABLE[stonk].price = StonksPlugin.settings.min_stonk_price end
    self:SendState(stonk)
end