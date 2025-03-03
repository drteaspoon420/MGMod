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

FreeForAllPlugin.teams_debug_colors = {
    Vector(0,255,0), --"#00ff00;";
    Vector(255,0,0), --"#ff0000;";
    Vector(243,201, 9), --"#f3c909;";
    Vector(255,108,0), --"#FF6C00;";
    Vector(52,85,255), --"#3455FF;";
    Vector(101,212,19), --"#65d413;";
    Vector(129,83,54), --"#815336;";
    Vector(27,192,216), --"#1bc0d8;";
    Vector(199,228,13), --"#c7e40d;";
    Vector(140,42,244), --"#8c2af4;";
}

FreeForAllPlugin.spawns = {}

function FreeForAllPlugin:Init()
    --print("[FreeForAllPlugin] found")
end

function FreeForAllPlugin:ApplySettings()
    FreeForAllPlugin.settings = PluginSystem:GetAllSetting("freeforall")
    FreeForAllPlugin.dummyunit = CreateUnitByName( "npc_dota_creep_badguys_ranged", Vector(0,0,0), false, nil, nil, DOTA_TEAM_NEUTRALS)
    if FreeForAllPlugin.dummyunit == nil then
        --print("[FreeForAllPlugin] roshan required")
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
    for k = 1,#FreeForAllPlugin.teams do
        FreeForAllPlugin:CreateSpawns(FreeForAllPlugin.teams[k],k)
    end
    FreeForAllPlugin.dummyunit:ForceKill(false)
    FreeForAllPlugin.dummyunit = nil
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

function FreeForAllPlugin:CreateSpawns(iTeam,kTeam)
    if FreeForAllPlugin.settings.placement == "ordered_ring" then
        local fRad = FreeForAllPlugin.settings.distance
        local fStep = (math.pi*2)/100
        
        for i = 1,10 do
            local p = fStep*(i+kTeam*10)
            local x = math.sin(p) * fRad
            local y = math.cos(p) * fRad
            FindClearSpaceForUnit(FreeForAllPlugin.dummyunit,Vector(x,y,0),false)
            local vPos = FreeForAllPlugin.dummyunit:GetAbsOrigin()
            FreeForAllPlugin:CreateSpawn(iTeam,vPos,true,kTeam)
        end
    elseif FreeForAllPlugin.settings.placement == "offset_ring" then
        local fRad = FreeForAllPlugin.settings.distance
        local fStepSub = (math.pi*2)/100
        local fStep = (math.pi*2)/10
        local offset = fStep*2 + fStepSub*kTeam
        
        for i = 1,10 do
            local p = fStep*i+offset
            local x = math.sin(p) * fRad
            local y = math.cos(p) * fRad
            FindClearSpaceForUnit(FreeForAllPlugin.dummyunit,Vector(x,y,0),false)
            local vPos = FreeForAllPlugin.dummyunit:GetAbsOrigin()
            FreeForAllPlugin:CreateSpawn(iTeam,vPos,true,kTeam)
        end
    elseif FreeForAllPlugin.settings.placement == "within_circle" then
        local fRad = FreeForAllPlugin.settings.distance
        local fStep = math.pi*2
        
        for i = 1,10 do
            local p = fStep*Script_RandomFloat(0.0,1.0)
            local x = math.sin(p) * Script_RandomFloat(0.0,fRad)
            local y = math.cos(p) * Script_RandomFloat(0.0,fRad)
            FindClearSpaceForUnit(FreeForAllPlugin.dummyunit,Vector(x,y,0),false)
            local vPos = FreeForAllPlugin.dummyunit:GetAbsOrigin()
            FreeForAllPlugin:CreateSpawn(iTeam,vPos,true,kTeam)
        end
    elseif FreeForAllPlugin.settings.placement == "within_box" then
        local fRad = FreeForAllPlugin.settings.distance
        for i = 1,10 do
            local x = Script_RandomFloat(-fRad,fRad)
            local y = Script_RandomFloat(-fRad,fRad)
            FindClearSpaceForUnit(FreeForAllPlugin.dummyunit,Vector(x,y,0),false)
            local vPos = FreeForAllPlugin.dummyunit:GetAbsOrigin()
            FreeForAllPlugin:CreateSpawn(iTeam,vPos,true,kTeam)
        end
    end
end

function FreeForAllPlugin:CreateSpawn(iTeam,vPos,bCourier,kTeam)

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
    
    if FreeForAllPlugin.spawns[iTeam] == nil then
        FreeForAllPlugin.spawns[iTeam] = {}
    end
    if IsInToolsMode() then
        DebugDrawText(vPos,iTeam .. " spawn", false, 999.0)
    end
    table.insert(FreeForAllPlugin.spawns[iTeam],hStart)
end