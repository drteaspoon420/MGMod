DeleteDotaPlugin = class({})
_G.DeleteDotaPlugin = DeleteDotaPlugin
DeleteDotaPlugin.settings = {}
DeleteDotaPlugin.storrage = {}

function DeleteDotaPlugin:Init()
    print("[DeleteDotaPlugin] found")
end

function DeleteDotaPlugin:ApplySettings()
    DeleteDotaPlugin.settings = PluginSystem:GetAllSetting("delete_dota")

    if DeleteDotaPlugin.settings.delete_creep_spawning then
        GameRules:SetCreepSpawningEnabled(false)
    end
    
    if DeleteDotaPlugin.settings.delete_tier_1 then DeleteDotaPlugin:DeleteTowers(1) end
    if DeleteDotaPlugin.settings.delete_tier_2 then DeleteDotaPlugin:DeleteTowers(2) end
    if DeleteDotaPlugin.settings.delete_tier_3 then DeleteDotaPlugin:DeleteTowers(3) end
    if DeleteDotaPlugin.settings.delete_tier_4 then DeleteDotaPlugin:DeleteTowers(4) end
    if DeleteDotaPlugin.settings.delete_barracks then DeleteDotaPlugin:DeleteRax() end

    if DeleteDotaPlugin.settings.delete_ancient then 
        if DeleteDotaPlugin.settings.delete_radiant then
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_fort")
        end
        if DeleteDotaPlugin.settings.delete_dire then
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_fort")
        end
    end

    if DeleteDotaPlugin.settings.delete_fillers then
        if DeleteDotaPlugin.settings.delete_radiant then
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_fillers")
        end
        if DeleteDotaPlugin.settings.delete_dire then
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_fillers")
        end
    end
    if DeleteDotaPlugin.settings.delete_outposts then --doesnt work?
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_watch_tower")
        DeleteDotaPlugin:FindAndDeleteClass("npc_dota_watch_tower")
    end
    if DeleteDotaPlugin.settings.delete_neutral_spawns then
        DeleteDotaPlugin:FindAndDeleteClass("npc_dota_neutral_spawner")
    end
    if DeleteDotaPlugin.settings.delete_rune_spawns then
        DeleteDotaPlugin:FindAndDeleteClass("dota_item_rune_spawner")
        DeleteDotaPlugin:FindAndDeleteClass("dota_item_rune_spawner_bounty")
        DeleteDotaPlugin:FindAndDeleteClass("dota_item_rune_spawner_powerup")
    end
    if DeleteDotaPlugin.settings.delete_roshan then
        DeleteDotaPlugin:FindAndDeleteClass("npc_dota_roshan_spawner")
    end
    if DeleteDotaPlugin.settings.delete_shops then
        DeleteDotaPlugin:FindAndDeleteClass("trigger_shop")
        DeleteDotaPlugin:FindAndDeleteClass("ent_dota_shop")
        GameRules:GetGameModeEntity():SetStashPurchasingDisabled(true)
    end
    if DeleteDotaPlugin.settings.delete_fountain then
        if DeleteDotaPlugin.settings.delete_radiant and not DeleteDotaPlugin.settings.delete_dire then
            DeleteDotaPlugin:FindAndRemoveUnit("dota_fountain",DOTA_TEAM_GOODGUYS)
        elseif not DeleteDotaPlugin.settings.delete_radiant and DeleteDotaPlugin.settings.delete_dire then
            DeleteDotaPlugin:FindAndRemoveUnit("dota_fountain",DOTA_TEAM_BADGUYS)
        else
            DeleteDotaPlugin:FindAndRemoveUnit("dota_fountain")
        end
    end
    if DeleteDotaPlugin.settings.delete_misc then
        DeleteDotaPlugin:FindAndDeleteClass("ent_dota_neutral_item_stash")
        DeleteDotaPlugin:FindAndDeleteClass("ent_dota_halloffame")
    end
end

function DeleteDotaPlugin:DeleteTowers(iTier)
    if DeleteDotaPlugin.settings.delete_radiant then
        if iTier < 4 then
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_tower".. iTier .."_top")
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_tower".. iTier .."_mid")
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_tower".. iTier .."_bot")
        else
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_tower".. iTier)
        end
    end
    if DeleteDotaPlugin.settings.delete_dire then
        if iTier < 4 then
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_tower".. iTier .."_top")
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_tower".. iTier .."_mid")
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_tower".. iTier .."_bot")
        else
            DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_tower".. iTier)
        end
    end
end
function DeleteDotaPlugin:DeleteRax()
    if DeleteDotaPlugin.settings.delete_radiant then
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_melee_rax_top")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_melee_rax_mid")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_melee_rax_bot")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_range_rax_top")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_range_rax_mid")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_goodguys_range_rax_bot")
    end
    if DeleteDotaPlugin.settings.delete_dire then
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_melee_rax_top")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_melee_rax_mid")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_melee_rax_bot")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_range_rax_top")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_range_rax_mid")
        DeleteDotaPlugin:FindAndRemoveUnit("npc_dota_badguys_range_rax_bot")
    end
end

function DeleteDotaPlugin:FindAndDeleteUnit(sName,iTeam)
    local iTeam = iTeam or -1
    local e = Entities:Next(nil)
    while e do
        if e.GetUnitName then
            local sUnitName = e:GetUnitName()
            if sUnitName == sName then
                if iTeam == -1 or (e.GetTeam and e:GetTeam() == iTeam) then
                    e:Destroy()
                end
            end
        end
        e = Entities:Next(e)
    end
end

function DeleteDotaPlugin:FindAndRemoveUnit(sName,iTeam)
    local iTeam = iTeam or -1
    local e = Entities:Next(nil)
    while e do
        if e.GetUnitName then
            local sUnitName = e:GetUnitName()
            if sUnitName == sName then
                if iTeam == -1 or (e.GetTeam and e:GetTeam() == iTeam) then
                    e:RemoveSelf()
                end
            end
        end
        e = Entities:Next(e)
    end
end

function DeleteDotaPlugin:FindAndKillUnit(sName,iTeam)
    local iTeam = iTeam or -1
    local e = Entities:Next(nil)
    while e do
        if e.GetUnitName then
            local sUnitName = e:GetUnitName()
            if sUnitName == sName then
                if iTeam == -1 or (e.GetTeam and e:GetTeam() == iTeam) then
                    if e.Kill then
                        e:ForceKill(false)
                    end
                end
            end
        end
        e = Entities:Next(e)
    end
end

function DeleteDotaPlugin:FindAndDeleteClass(sName)
    local e = Entities:Next(nil)
    while e do
        if e.GetClassname then
            local sUnitName = e:GetClassname()
            if sUnitName == sName then
                e:RemoveSelf()
            end
        end
        e = Entities:Next(e)
    end
end

function DeleteDotaPlugin:ThanosSnap(tArgs,bTeam,iPlayer)
    if DeleteDotaPlugin.settings.thanos_snap then 
        if #tArgs == 2 then
            local chance = tonumber(tArgs[2])
            if chance then
                local e = Entities:Next(nil)
                while e do
                    if e.IsBaseNPC and e:IsBaseNPC() and e.IsRealHero and not e:IsRealHero() then
                        local dice = Script_RandomFloat(0,100)
                        print(chance,"/",dice)
                        if chance > dice then
                            e:Destroy()
                        end
                    end
                    e = Entities:Next(e)
                end
            end
        end
    end
end

