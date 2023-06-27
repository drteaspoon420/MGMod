ArchiveOnePlugin = class({})
_G.ArchiveOnePlugin = ArchiveOnePlugin
ArchiveOnePlugin.unit_cache = {}

function ArchiveOnePlugin:Init()
    print("[ArchiveOnePlugin] found")
end

function ArchiveOnePlugin:ApplySettings()
    ArchiveOnePlugin.settings = PluginSystem:GetAllSetting("archive_pack_one")

    LinkLuaModifier( "symbiosis", "plugin_system/plugins/archive_pack_one/modifiers/symbiosis", LUA_MODIFIER_MOTION_HORIZONTAL )
    LinkLuaModifier( "clicks_death", "plugin_system/plugins/archive_pack_one/modifiers/clicks_death", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "bloodbath", "plugin_system/plugins/archive_pack_one/modifiers/bloodbath", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "combo", "plugin_system/plugins/archive_pack_one/modifiers/combo", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "nurgle", "plugin_system/plugins/archive_pack_one/modifiers/nurgle", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "unseen_sanic", "plugin_system/plugins/archive_pack_one/modifiers/unseen_sanic", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "health_cap", "plugin_system/plugins/archive_pack_one/modifiers/health_cap", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "ally_death_fear", "plugin_system/plugins/archive_pack_one/modifiers/ally_death_fear", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "death_stats", "plugin_system/plugins/archive_pack_one/modifiers/death_stats", LUA_MODIFIER_MOTION_NONE )

    LinkLuaModifier( "mod_hp", "plugin_system/plugins/archive_pack_one/modifiers/mod_hp", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "mod_mp", "plugin_system/plugins/archive_pack_one/modifiers/mod_mp", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "mod_dmg", "plugin_system/plugins/archive_pack_one/modifiers/mod_dmg", LUA_MODIFIER_MOTION_NONE )

    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        ArchiveOnePlugin:SpawnEvent(event)
    end,nil)

    ListenToGameEvent("entity_killed", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        ArchiveOnePlugin:KilledEvent(event)
    end,nil)

    
end

function ArchiveOnePlugin:CacheUnit(entindex)
    if ArchiveOnePlugin.unit_cache[entindex] ~= nil then return false end
    local hUnit = EntIndexToHScript(event.entindex)
    if hUnit:IsRealHero() then
        ArchiveOnePlugin.unit_cache[entindex] = true
    end
    return true
end

function ArchiveOnePlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end
    if not ArchiveOnePlugin:CacheUnit(event.entindex) then return end

    if hUnit:IsRealHero() then
        if ArchiveOnePlugin.settings.clicks_death then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"clicks_death",{})
        end
        if ArchiveOnePlugin.settings.bloodbath then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"bloodbath",{})
        end
        if ArchiveOnePlugin.settings.combo then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"combo",{})
        end
        if ArchiveOnePlugin.settings.nurgle then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"nurgle",{})
        end
        if ArchiveOnePlugin.settings.unseen_sanic then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"unseen_sanic",{})
        end
        if ArchiveOnePlugin.settings.health_cap then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"health_cap",{})
        end
        if ArchiveOnePlugin.settings.ally_death_fear then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"ally_death_fear",{})
        end
        if ArchiveOnePlugin.settings.death_stats then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"death_stats",{})
        end
    end
    
end
local teams_id = {}
        
local findFirstHero = function(iTeam)
    for i=0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayer(i) then
            local player = PlayerResource:GetPlayer(i)
            local heroUnit = player:GetAssignedHero()
            if hHero == nil and heroUnit:GetTeam() == iTeam then
                return heroUnit
            end
        end
    end
end

function ArchiveOnePlugin:OnPreGameEnd()
    if ArchiveOnePlugin.settings.symbiosis then
        for i=0, DOTA_MAX_TEAM_PLAYERS do
            if PlayerResource:IsValidPlayer(i) then
                local player = PlayerResource:GetPlayer(i)
                local hero = player:GetAssignedHero()
                local iTeam = hero:GetTeam()
                local hFirst = findFirstHero(iTeam)
                if (hFirst ~= hero and hFirst ~= nil) then
                    if teams_id[iTeam] ~= nil then
                        teams_id[iTeam] = teams_id[iTeam] + 1
                    else
                        teams_id[iTeam] = 0
                    end
                    data = {}
                    data.teamindex = teams_id[iTeam]
                    hero:AddNewModifier(hFirst, nil, "symbiosis", data)
                end
            end
        end
    end
end


function ArchiveOnePlugin:KilledEvent(event)
	local attackerUnit = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker)
	local killedUnit = event.entindex_killed and EntIndexToHScript(event.entindex_killed)
	local damagebits = event.damagebits
    
    if ArchiveOnePlugin.settings.powercreep then
        if (attackerUnit and killedUnit and killedUnit.IsIllusion ~= nil and attackerUnit.IsIllusion ~= nil and not killedUnit:IsIllusion() and not attackerUnit:IsIllusion()) then
            attackerUnit:AddNewModifier(attackerUnit,nil,"mod_hp",{bonus = killedUnit:GetMaxHealth() * 0.1})
            attackerUnit:AddNewModifier(attackerUnit,nil,"mod_mp",{bonus = killedUnit:GetMaxMana() * 0.1})
            attackerUnit:AddNewModifier(attackerUnit,nil,"mod_dmg",{bonus = killedUnit:GetAverageTrueAttackDamage(nil) * 0.1})
        end
    end
	if (killedUnit and killedUnit:IsRealHero()) then
--[[ 		if ArchiveOnePlugin.settings.day11 then
		end ]]
	end
end

