TremulousPlugin = class({})
_G.TremulousPlugin = TremulousPlugin
TremulousPlugin.death_times = {}
TremulousPlugin.unit_cache = {}

function TremulousPlugin:Init()
    print("[TremulousPlugin] found")
end

function TremulousPlugin:ApplySettings()
    TremulousPlugin.settings = PluginSystem:GetAllSetting("tremulous")
    GameRules:SetHeroRespawnEnabled(false)
    GameRules:GetGameModeEntity():SetBuybackEnabled(false)
    ListenToGameEvent("entity_killed", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        TremulousPlugin:KilledEvent(event)
    end,nil)
    ListenToGameEvent("npc_spawned", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            TremulousPlugin:SpawnEvent(event)
    end,nil)
    CustomGameEventManager:RegisterListener("building_pick",TremulousPlugin.building_pick)
    GameRules:SetUseUniversalShopMode(true)
end

function TremulousPlugin:SpawnPointTryRespawn(hSpawn)
    local iTeam = hSpawn:GetTeam()
    local vPos = hSpawn:GetAbsOrigin()
    local fLowest = 999999999
    local iSpawnId = -1
    for iPlayer,fTime in pairs(TremulousPlugin.death_times) do
        if PlayerResource:GetTeam(iPlayer) == iTeam then
            if fTime < fLowest then
                iSpawnId = iPlayer
            end
        end
    end
    if iSpawnId > -1 then
        TremulousPlugin.death_times[iSpawnId] = nil
        local hPlayer = PlayerResource:GetPlayer(iSpawnId)
        local hHero = hPlayer:GetAssignedHero()
        hHero:SetRespawnPosition(vPos)
        hHero:RespawnHero(false,false)
        return true
    end
    return false
end

function TremulousPlugin:KilledEvent(event)
	local hUnit = event.entindex_killed and EntIndexToHScript(event.entindex_killed)
    if not hUnit:IsDOTANPC() then return end
    local iTeam = hUnit:GetTeam()
	if (hUnit and hUnit:IsRealHero() and not hUnit:IsReincarnating()) then --check if there is spawns, if yes, create death_time record
        local hPlayer = hUnit:GetPlayerOwner()
        if hPlayer ~= nil then
            local hMainHero = hPlayer:GetAssignedHero()
            if hUnit == hMainHero then
                local fTime = GameRules:GetGameTime()
                local iPlayer = hPlayer:GetPlayerID()
                TremulousPlugin.death_times[iPlayer] = fTime
                if not TremulousPlugin:HasSpawns(iTeam) then
                    GameRules:SetGameWinner(((iTeam+1)%2)+DOTA_TEAM_GOODGUYS)
                end
            end
        end
    elseif hUnit:HasAbility("tremulous_spawn") or hUnit:HasAbility("tremulous_power")  then --if the last spawn is killed (or power supply)
        Timers:CreateTimer(5,function()
            if TremulousPlugin:HasSpawns(iTeam) then
                return
            end
            local hSearchUnit = Entities:Next(nil)
            while hSearchUnit do
                if hSearchUnit:IsDOTANPC() and hSearchUnit:IsRealHero() and hSearchUnit:GetTeam() == iTeam and (hSearchUnit:IsAlive() or hSearchUnit:IsReincarnating()) then
                    local hPlayer = hSearchUnit:GetPlayerOwner()
                    if hPlayer ~= nil then
                        local hMainHero = hPlayer:GetAssignedHero()
                        if hSearchUnit == hMainHero then
                            return
                        end
                    end
                end
                hSearchUnit = Entities:Next(hSearchUnit)
            end
            GameRules:SetGameWinner(((iTeam+1)%2)+DOTA_TEAM_GOODGUYS)
        end)
    end
end

function TremulousPlugin:HasSpawns(iTeam)
    local hUnit = Entities:Next(nil)
    while hUnit do
        if hUnit:IsDOTANPC() and hUnit:IsAlive() and hUnit:GetTeam() == iTeam then
            if hUnit:HasAbility("tremulous_spawn") and hUnit:HasModifier("modifier_tremulous_power_aura") then
                return true
            end
        end
        hUnit = Entities:Next(hUnit)
    end
    return false
end

function TremulousPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() and not hUnit:IsClone() and hUnit:GetReplicatingOtherHero() == nil then
        if TremulousPlugin.unit_cache[event.entindex] ~= nil then return end
        TremulousPlugin.unit_cache[event.entindex] = true
        hUnit:AddItemByName("item_tremulous_builder")
        hUnit:SetGold(0,false)
        hUnit:SetGold(TremulousPlugin.settings.start_gold,true)
    end
end

TremulousPlugin.buildings = {
    
    tremulous_build_ancient = {
        iCost = 8000,
        sUnit = "npc_tremulous_ancient"
    },
    tremulous_build_spawn = {
        iCost = 4000,
        sUnit = "npc_tremulous_spawn"
    },
    tremulous_build_tower = {
        iCost = 3000,
        sUnit = "npc_tremulous_tower"
    },
    tremulous_build_shrine = {
        iCost = 3000,
        sUnit = "npc_tremulous_shrine"
    },
    tremulous_build_shop = {
        iCost = 4000,
        sUnit = "npc_tremulous_shop"
    },
    tremulous_build_barracks = {
        iCost = 5000,
        sUnit = "npc_tremulous_barracks"
    },
}

function TremulousPlugin:building_pick(tEvent)
    local iPlayer = tEvent.PlayerID
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return end
    local hMainHero = hPlayer:GetAssignedHero()
    if hMainHero == nil then return end
    
    local hItem = hMainHero:FindItemInInventory("item_tremulous_builder")
    if hItem ~= nil then
        if (TremulousPlugin.buildings[tEvent.name] ~= nil) then
            print("attempting to spawn",tEvent.name)
            hItem:TryBuild(TremulousPlugin.buildings[tEvent.name].sUnit,TremulousPlugin.buildings[tEvent.name].iCost)
        end
    end
end