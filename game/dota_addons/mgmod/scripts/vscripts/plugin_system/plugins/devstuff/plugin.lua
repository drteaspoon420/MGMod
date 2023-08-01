DevStuffPlugin = class({})
_G.DevStuffPlugin = DevStuffPlugin
DevStuffPlugin.settings = {}
DevStuffPlugin.unit_cache = {}

function DevStuffPlugin:Init()
    print("[DevStuffPlugin] found")
end

function DevStuffPlugin:ApplySettings()
    DevStuffPlugin.settings = PluginSystem:GetAllSetting("devstuff")
    GameRules:SetRiverPaint(2,999)
    
--[[     ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        DevStuffPlugin:SpawnEvent(event)
end,nil) ]]
end
    
function DevStuffPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        if DevStuffPlugin.unit_cache[event.entindex] ~= nil then return end
        DevStuffPlugin.unit_cache[event.entindex] = true
        DevStuffPlugin:DoHeroes(hUnit)
    end
end

function DevStuffPlugin:DoHeroes(hUnit)
    --local hAttachment = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/attach_patch.vmdl", targetname=DoUniqueString("prop_dynamic")})

    if true then
        hUnit:SetModel("models/attach_patch.vmdl")
        hUnit:SetMaterialGroup("material")
    else
        print("[DevStuffPlugin] attach thing")
        CreateUnitByNameAsync("npc_dota_thinker",Vector(0,0,0),false,nil,nil,0,
        function(hAttachment)
            print("Spawned npc_dota_thinker")
            if hAttachment ~= nil then
                hAttachment:SetModel("models/attach_patch.vmdl")
                hAttachment:FollowEntity(hUnit,true)
                hAttachment:FollowEntityMerge(hUnit,"attach_hitloc")
                hAttachment:SetParent(hUnit,"attach_hitloc")
                
            else
                print("failed to create info_attach_dev")
            end

            print("attach_hitloc",hUnit:ScriptLookupAttachment("attach_hitloc"))
            print("attach_orb1",hUnit:ScriptLookupAttachment("attach_orb1"))
            print("attach_orb2",hUnit:ScriptLookupAttachment("attach_orb2"))
            print("attach_orb3",hUnit:ScriptLookupAttachment("attach_orb3"))
            print("attach_weapon_core_fx",hUnit:ScriptLookupAttachment("attach_weapon_core_fx"))
            print("attach_orb1 on new",hAttachment:ScriptLookupAttachment("attach_orb1"))
            print("attach_orb2 on new",hAttachment:ScriptLookupAttachment("attach_orb2"))
            print("attach_orb3 on new",hAttachment:ScriptLookupAttachment("attach_orb3"))
            print("attach_weapon_core_fx on new",hAttachment:ScriptLookupAttachment("attach_weapon_core_fx"))

            Timers:CreateTimer(2,function()
                print("with delay")
                print("attach_hitloc",hUnit:ScriptLookupAttachment("attach_hitloc"))
                print("attach_orb1",hUnit:ScriptLookupAttachment("attach_orb1"))
                print("attach_orb2",hUnit:ScriptLookupAttachment("attach_orb2"))
                print("attach_orb3",hUnit:ScriptLookupAttachment("attach_orb3"))
                print("attach_weapon_core_fx",hUnit:ScriptLookupAttachment("attach_weapon_core_fx"))
                print("attach_orb1 on new",hAttachment:ScriptLookupAttachment("attach_orb1"))
                print("attach_orb2 on new",hAttachment:ScriptLookupAttachment("attach_orb2"))
                print("attach_orb3 on new",hAttachment:ScriptLookupAttachment("attach_orb3"))
                print("attach_weapon_core_fx on new",hAttachment:ScriptLookupAttachment("attach_weapon_core_fx"))
            end)
        end)
    end
end


function DevStuffPlugin:ShortCutMods(tArgs,bTeam,iPlayer)
	local hUnit = Entities:GetLocalPlayerController() and Entities:GetLocalPlayerController():GetQueryUnit()
    if (hUnit) then
        for m,mod in pairs(hUnit:FindAllModifiers()) do
            local hAbility = mod:GetAbility()
            if hAbility ~= nil then
                print("Modifier:",mod:GetName()," of ", hAbility:GetAbilityName())
            else
                print("Modifier:",mod:GetName()," without ability parent")
            end
        end
    end
end

function DevStuffPlugin:ShortCutResetDefeated(tArgs,bTeam,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if not GameRules:PlayerHasCustomGameHostPrivileges(hPlayer) then return end
    GameRules:ResetDefeated()
end
function DevStuffPlugin:ShortCutResetToCustomGameSetup(tArgs,bTeam,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if not GameRules:PlayerHasCustomGameHostPrivileges(hPlayer) then return end
    GameRules:ResetToCustomGameSetup()
end
function DevStuffPlugin:ShortCutResetToHeroSelection(tArgs,bTeam,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if not GameRules:PlayerHasCustomGameHostPrivileges(hPlayer) then return end
    GameRules:ResetToHeroSelection()
end