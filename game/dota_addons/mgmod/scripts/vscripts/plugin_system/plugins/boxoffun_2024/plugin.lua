BoxOfFun23Plugin = class({})
_G.BoxOfFun23Plugin = BoxOfFun23Plugin

function BoxOfFun23Plugin:Init()
    print("[BoxOfFun23Plugin] found")
end

function BoxOfFun23Plugin:ApplySettings()
    BoxOfFun23Plugin.settings = PluginSystem:GetAllSetting("boxoffun_2024")

    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        BoxOfFun23Plugin:SpawnEvent(event)
    end,nil)

    ListenToGameEvent("dota_rune_activated_server", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        BoxOfFun23Plugin:RunePickupEvent(event)
    end,nil)

    
end

function BoxOfFun23Plugin:GameInProgressEvent()
end

function BoxOfFun23Plugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end
    if hUnit:IsRealHero() then
    end
end

function BoxOfFun23Plugin:AddNewModifierToTeam(iTeam,sMod,tData,bHeroes,hSkip)
    if sMod == "" then return end
    bHeroes = bHeroes or false
    local iTeam = iTeam or -1
    local e = Entities:Next(nil)
    while e do
        if e.IsBaseNPC and e:IsBaseNPC() then
            if bHeroes == e:IsRealHero() or not bHeroes then
                if hSkip ~= e then
                    if iTeam == -1 or (e.GetTeam and e:GetTeam() == iTeam) then
                        local hModifier = e:AddNewModifier(e,nil,sMod,tData)
                    end
                end
            end
        end
        e = Entities:Next(e)
    end
end