SoulsPlugin = class({})
_G.SoulsPlugin = SoulsPlugin
SoulsPlugin.settings = {
}

SoulsPlugin.souls = {}
SoulsPlugin.earned = {}
SoulsPlugin.spent = {}

function SoulsPlugin:Init()
    print("[SoulsPlugin] found")
end

function SoulsPlugin:ApplySettings()
    SoulsPlugin.souls = {}
    SoulsPlugin.souls[DOTA_TEAM_GOODGUYS] = 0
    SoulsPlugin.souls[DOTA_TEAM_BADGUYS] = 0
    SoulsPlugin.earned = {}
    SoulsPlugin.earned[DOTA_TEAM_GOODGUYS] = 0
    SoulsPlugin.earned[DOTA_TEAM_BADGUYS] = 0
    SoulsPlugin.spent = {}
    SoulsPlugin.spent[DOTA_TEAM_GOODGUYS] = 0
    SoulsPlugin.spent[DOTA_TEAM_BADGUYS] = 0

    LinkLuaModifier( "modifier_soul_stack", "plugin_system/plugins/souls_plugin/modifier_soul_stack", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "modifier_soul_droplet", "plugin_system/plugins/souls_plugin/modifier_soul_droplet", LUA_MODIFIER_MOTION_NONE )
    ListenToGameEvent("entity_killed", function(event)
        SoulsPlugin:DeathEvent(event)
    end,nil)
end
    
function SoulsPlugin:EarnSouls(hHero,iCount)
    local iTeam = hHero:GetTeam()
    SoulsPlugin.souls[iTeam] = SoulsPlugin.souls[iTeam] + iCount
    SoulsPlugin.earned[iTeam] = SoulsPlugin.earned[iTeam] + iCount
    print("[SoulsPlugin] +",iCount,", Team:",iTeam,"has",SoulsPlugin.souls[iTeam])
    
    local sfx = "Loot_Drop_Stinger_Short"
    if iCount > 5000 then
        sfx = "Loot_Drop_Stinger_Arcana"
    elseif iCount > 2500 then
        sfx = "Loot_Drop_Stinger_Immortal"
    elseif iCount > 1000 then
        sfx = "Loot_Drop_Stinger_Ancient"
    elseif iCount > 665 then
        sfx = "Loot_Drop_Stinger_Legendary"
    elseif iCount > 250 then
        sfx = "Loot_Drop_Stinger_Mythical"
    elseif iCount > 100 then
        sfx = "Loot_Drop_Stinger_Rare"
    elseif iCount > 50 then
        sfx = "Loot_Drop_Stinger_Uncommon"
    end
    EmitSoundOnClient(sfx,hHero:GetPlayerOwner())
    CustomNetTables:SetTableValue("souls_collected","team_" .. iTeam,{souls = SoulsPlugin.souls[iTeam], earned = SoulsPlugin.earned[iTeam],spent = SoulsPlugin.spent[iTeam]})
    PluginSystem:InternalEvent_Call("souls_collected",{
		team = iTeam,
		increase = iCount,
		total = SoulsPlugin.souls[iTeam]
	})
end


function SoulsPlugin:SpendSoulsTeam(iTeam,iCount)
    if SoulsPlugin.souls[iTeam] < iCount then
        return false
    end
    SoulsPlugin.souls[iTeam] = SoulsPlugin.souls[iTeam] - iCount
    SoulsPlugin.spent[iTeam] = SoulsPlugin.spent[iTeam] + iCount
    CustomNetTables:SetTableValue("souls_collected","team_" .. iTeam,{souls = SoulsPlugin.souls[iTeam], earned = SoulsPlugin.earned[iTeam],spent = SoulsPlugin.spent[iTeam]})
    PluginSystem:InternalEvent_Call("souls_spent",{
		team = iTeam,
		increase = -iCount,
		total = SoulsPlugin.souls[iTeam]
	})
    return true
end

function SoulsPlugin:SpendSouls(hPlayer,iCount)
    local iTeam = hPlayer:GetTeam()
    return SoulsPlugin:SpendSoulsTeam(iTeam,iCount)
end

function SoulsPlugin:CheckSouls(hPlayer,iCount)
    local iTeam = hPlayer:GetTeam()
    if SoulsPlugin.souls[iTeam] < iCount then
        return false
    else
        return true
    end
end

function SoulsPlugin:GetSoulsTeam(iTeam)
    return SoulsPlugin.souls[iTeam] or 0
end

function SoulsPlugin:GetSouls(hPlayer)
    local iTeam = hPlayer:GetTeam()
    return SoulsPlugin.souls[iTeam] or 0
end

function SoulsPlugin:DeathEvent(event)
	local attackerUnit = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker)
	local killedUnit = event.entindex_killed and EntIndexToHScript(event.entindex_killed)
    if not killedUnit.GetLevel then return end
    if killedUnit == attackerUnit or attackerUnit == nil then
        return
    end
    local iStack = killedUnit:GetLevel()
    if iStack == 0 then iStack = 1 end
    if killedUnit:HasModifier("modifier_soul_stack") then
        local hMod = killedUnit:FindModifierByName("modifier_soul_stack")
        if hMod then
            iStack = iStack + hMod:GetStackCount()
            hMod:Destroy()
        end
    end
    CreateModifierThinker(
        killedUnit,
        nil,
        "modifier_soul_droplet",
        {stack = iStack},
        killedUnit:GetAbsOrigin(),
        DOTA_TEAM_NEUTRALS,
        false
    )
end
