XMax12Plugin = class({})
_G.XMax12Plugin = XMax12Plugin
XMax12Plugin.unit_cache = {}

function XMax12Plugin:Init()
    --print("[XMax12Plugin] found")
end

function XMax12Plugin:ApplySettings()
    XMax12Plugin.settings = PluginSystem:GetAllSetting("xmas12")
    --Towers give mana but you have 0 mana regen elsewhere.
    LinkLuaModifier( "day_1", "plugin_system/plugins/xmas12/modifiers/day_1", LUA_MODIFIER_MOTION_NONE )
    --You spend gold and eventually health for mana
    LinkLuaModifier( "day_2", "plugin_system/plugins/xmas12/modifiers/day_2", LUA_MODIFIER_MOTION_NONE )
    --Being alone makes you fear
    LinkLuaModifier( "day_5", "plugin_system/plugins/xmas12/modifiers/day_5", LUA_MODIFIER_MOTION_NONE )
    --Creates delayed explosions at player locations
    LinkLuaModifier( "day_6", "plugin_system/plugins/xmas12/modifiers/day_6", LUA_MODIFIER_MOTION_NONE )
    --Illusions haunt players
    LinkLuaModifier( "day_7", "plugin_system/plugins/xmas12/modifiers/day_7", LUA_MODIFIER_MOTION_NONE )
    --10% of health, mana and damage is given to nearest unit on death.
    LinkLuaModifier( "day_8", "plugin_system/plugins/xmas12/modifiers/day_8", LUA_MODIFIER_MOTION_NONE )
    --Given to couriers! gives random abilities on courier based on courier model.
    LinkLuaModifier( "day_9", "plugin_system/plugins/xmas12/modifiers/day_9", LUA_MODIFIER_MOTION_NONE )
    --Flashlights
    LinkLuaModifier( "day_12", "plugin_system/plugins/xmas12/modifiers/day_12", LUA_MODIFIER_MOTION_NONE )
    if XMax12Plugin.settings.day12 then
        local unit = Entities:Next(nil)
        while(unit) do
            if unit:IsDOTANPC() then
                local hModifier = unit:AddNewModifier(unit,nil,"day_12",{})
            end
            unit = Entities:Next(unit)
        end
    end

    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        XMax12Plugin:SpawnEvent(event)
    end,nil)

    ListenToGameEvent("entity_killed", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        XMax12Plugin:KilledEvent(event)
    end,nil)

    
    if XMax12Plugin.settings.day4 then
	    Timers:CreateTimer( XMax12Plugin.Day4Timer)
    end
end

function XMax12Plugin:Day4Timer()
    local x_ = -8585
    local y_ = -8585
    local y = 8585
    local x = 8585
    local vPos = Vector(Script_RandomFloat(x_,x),Script_RandomFloat(y_,y),0)

    
    CreateUnitByNameAsync("npc_barrel_of_fun",vPos, false, nil, nil, DOTA_TEAM_NEUTRALS,
    function (hUnit)
        hUnit:AddNewModifier(hUnit,nil,"modifier_kill",{duration = 100})
        FindClearSpaceForUnit(hUnit,vPos,true)
        local fIndex = ParticleManager:CreateParticle("particles/teleport.vpcf",PATTACH_WORLDORIGIN ,nil)
        ParticleManager:SetParticleControl(fIndex,0,hUnit:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(fIndex)
        EmitSoundOn("dstelept",hUnit)
    end)
    return 1
end

function XMax12Plugin:CacheUnit(entindex)
    if XMax12Plugin.unit_cache[entindex] ~= nil then return false end
    local hUnit = EntIndexToHScript(entindex)
    if hUnit:IsRealHero() then
        XMax12Plugin.unit_cache[entindex] = true
    end
end

function XMax12Plugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end
    --if not XMax12Plugin:CacheUnit(event.entindex) then return end

    if hUnit:IsRealHero() then
        if XMax12Plugin.settings.day1 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"day_1",{})
        end
        if XMax12Plugin.settings.day2 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"day_2",{})
        end
        if XMax12Plugin.settings.day5 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"day_5",{})
        end
        if XMax12Plugin.settings.day6 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"day_6",{})
        end
        if XMax12Plugin.settings.day7 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"day_7",{})
        end
    end
    if XMax12Plugin.settings.day8 then
        local hModifier = hUnit:AddNewModifier(hUnit,nil,"day_8",{})
    end
    if XMax12Plugin.settings.day9 then
        if hUnit:GetUnitName() == "npc_dota_courier" then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"day_9",{})
        end
    end
    if XMax12Plugin.settings.day12 then
        local hModifier = hUnit:AddNewModifier(hUnit,nil,"day_12",{})
    end
    
end


function XMax12Plugin:KilledEvent(event)
	local attackerUnit = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker)
	local killedUnit = event.entindex_killed and EntIndexToHScript(event.entindex_killed)
	local damagebits = event.damagebits

	if (killedUnit and killedUnit:IsRealHero()) then
		if XMax12Plugin.settings.day11 then
			if (attackerUnit and attackerUnit:IsRealHero()) then
				local illusion_keys = {
					outgoing_damage =  1.0,
					incoming_damage =  1.0,
					bounty_base =  0.0,
					bounty_growth =  0.0,
					outgoing_damage_structure = 1.0,
					outgoing_damage_roshan = 1.0,
					duration = 60.0,
				}
				local tIllusion = CreateIllusions(attackerUnit, killedUnit, illusion_keys, 1, 0, false, true)
				for i=1,#tIllusion do
					tIllusion[i]:SetHealth(tIllusion[i]:GetMaxHealth())
					tIllusion[i]:SetMana(tIllusion[i]:GetMaxMana())
				end
			end
		end
	end
end


function XMax12Plugin:DamageFilter(event)
--[[ 	local attackerUnit = event.entindex_attacker_const and EntIndexToHScript(event.entindex_attacker_const)
	local damageType = event.damagetype_const
	local damage = event.damage
 ]]
	local victimUnit = event.entindex_victim_const and EntIndexToHScript(event.entindex_victim_const)
    if XMax12Plugin.settings ~= nil then
        if XMax12Plugin.settings.day3 then
            event.damage = victimUnit:GetMaxHealth() * 0.4
        end
    end
    return {true,event}
end

function XMax12Plugin:ExecuteOrderFilter(event)
	local ability = event.entindex_ability and EntIndexToHScript(event.entindex_ability)
	local targetUnit = event.entindex_target and EntIndexToHScript(event.entindex_target)
	local playerID = event.issuer_player_id_const
	local orderType = event.order_type
	local pos = Vector(event.position_x,event.position_y,event.position_z)
	local queue = event.queue
	local seqNum = event.sequence_number_const
	local units = event.units
	local unit = units and units["0"] and EntIndexToHScript(units["0"])

	if XMax12Plugin.settings.day10 then
		if orderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION then
			for k,nunit in pairs(units) do
				unit = EntIndexToHScript(nunit)
				if unit == nil then return end
				if not unit:IsAlive() then return {true,event} end
				if unit:IsFrozen() then return {true,event} end
				if unit:IsStunned() then return {true,event} end
				if unit:IsRooted() then return {true,event} end
				if unit:HasModifier("modifier_knockback") then return {true,event} end
				if (event.position_x == 0 and event.position_y == 0 and event.position_z == 0) then return {true,event} end
				local vPos = unit:GetAbsOrigin()
				vPos = vPos + (vPos - pos)
				local modifierKnockback =
				{
					center_x = vPos.x,
					center_y = vPos.y,
					center_z = vPos.z,
					duration = 0.5,
					knockback_duration = 0.5,
					knockback_distance = 600,
					knockback_height = 50,
				}
				unit:AddNewModifier( unit, nil, "modifier_knockback", modifierKnockback );
			end
			return {false,event}
		end
	end

	-- --  example
		-- if pos._len()<2000 then return false end

	return {true,event}
end