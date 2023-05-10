FreeForAllPlugin = class({})
_G.FreeForAllPlugin = FreeForAllPlugin
FreeForAllPlugin.unit_cache = {}

FreeForAllPlugin.teams = {
    DOTA_TEAM_GOODGUYS,
    DOTA_TEAM_BADGUYS,
    DOTA_TEAM_CUSTOM_1,
    DOTA_TEAM_CUSTOM_2,
    DOTA_TEAM_CUSTOM_3,
    DOTA_TEAM_CUSTOM_4,
    DOTA_TEAM_CUSTOM_5,
    DOTA_TEAM_CUSTOM_6,
    DOTA_TEAM_CUSTOM_7,
    DOTA_TEAM_CUSTOM_8
}

function FreeForAllPlugin:Init()
    print("[FreeForAllPlugin] found")
end

function FreeForAllPlugin:ApplySettings()
    FreeForAllPlugin.dummyunit = Toolbox:FindUnit("npc_dota_roshan")
    if FreeForAllPlugin.dummyunit == nil then
        print("[FreeForAllPlugin] roshan required")
        return
    end
    FreeForAllPlugin.original_pos = FreeForAllPlugin.dummyunit:GetAbsOrigin()
    --
    --destroy default spawns
    FreeForAllPlugin:FindAndDeleteClass("info_courier_spawn")
    FreeForAllPlugin:FindAndDeleteClass("info_courier_spawn_dire")
    FreeForAllPlugin:FindAndDeleteClass("info_courier_spawn_radiant")
    FreeForAllPlugin:FindAndDeleteClass("info_player_start_dota")
    FreeForAllPlugin:FindAndDeleteClass("info_player_start_badguys")
    FreeForAllPlugin:FindAndDeleteClass("info_player_start_goodguys")
    --
    for iPlayer = 0,DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(iPlayer) then
            local hPlayer = PlayerResource:GetPlayer(iPlayer)
            if hPlayer ~= nil then
                if #FreeForAllPlugin.teams > iPlayer then
                    GameRules:SetCustomGameTeamMaxPlayers(FreeForAllPlugin.teams[iPlayer+1],1)
                    FreeForAllPlugin:CreateSpawns(FreeForAllPlugin.teams[iPlayer+1])
                end
            end
        end
    end
    Timers:CreateTimer(0,function()
        for iPlayer = 0,DOTA_MAX_PLAYERS do
            if PlayerResource:IsValidPlayer(iPlayer) then
                local hPlayer = PlayerResource:GetPlayer(iPlayer)
                if hPlayer ~= nil then
                    if #FreeForAllPlugin.teams > iPlayer then
                        PlayerResource:SetCustomTeamAssignment(iPlayer,FreeForAllPlugin.teams[iPlayer+1])
                    end
                end
            end
        end
        FindClearSpaceForUnit(FindClearSpaceForUnit.dummyunit,FreeForAllPlugin.original_pos,false)
    end)
end

function FreeForAllPlugin:FindAndDeleteClass(sName)
    local e = Entities:Next(nil)
    while e do
        if e.GetClassname then
            local sUnitName = e:GetClassname()
            if sUnitName == sName then
                e:Destroy()
            end
        end
        e = Entities:Next(e)
    end
end

function FreeForAllPlugin:CreateSpawns(iTeam)
    local fRad = 3000
    local fStep = (math.pi*2)/10
    
    for i = 1,10 do
        local x = math.sin(fStep*i+iTeam) * fRad
        local y = math.cos(fStep*i+iTeam) * fRad
        FindClearSpaceForUnit(FindClearSpaceForUnit.dummyunit,Vector(x,y,0),false)
        local vPos = FindClearSpaceForUnit.dummyunit:GetAbsOrigin()
        FreeForAllPlugin:CreateSpawn(iTeam,vPos,true)
    end
end

function FreeForAllPlugin:CreateSpawn(iTeam,vPos,bCourier)

    local hStart = SpawnEntityFromTableSynchronous("info_player_start_dota",{
		origin = vPos,
    })
    hStart:SetTeam(iTeam)
    if bCourier then
        local hCourier = SpawnEntityFromTableSynchronous("info_courier_spawn",{
            origin = vPos,
        })
        hCourier:SetTeam(iTeam)
    end
    print("[FreeForAllPlugin] created spawn at",vPos,"for team",iTeam)
end