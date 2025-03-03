SoulsPlugin = class({})
_G.SoulsPlugin = SoulsPlugin
SoulsPlugin.settings = {
}


function SoulsPlugin:Init()
    --print("[SoulsPlugin] found")
end

function SoulsPlugin:ApplySettings()
    
    SoulsPlugin.settings = PluginSystem:GetAllSetting("souls_plugin")
    LinkLuaModifier( "modifier_soul_stack", "plugin_system/plugins/souls_plugin/modifier_soul_stack", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "modifier_soul_droplet", "plugin_system/plugins/souls_plugin/modifier_soul_droplet", LUA_MODIFIER_MOTION_NONE )
    ListenToGameEvent("entity_killed", function(event)
        SoulsPlugin:DeathEvent(event)
    end,nil)
end
    
function SoulsPlugin:EarnSouls(hHero,iCount)
    local iPlayer = hHero:GetPlayerOwnerID()
    
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
    CurrenciesPlugin:AlterCurrency(SoulsPlugin.settings.currency,iPlayer,iCount)
end

function SoulsPlugin:DeathEvent(event)
	local attackerUnit = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker)
	local killedUnit = event.entindex_killed and EntIndexToHScript(event.entindex_killed)
    if not killedUnit.GetLevel then return end
    local iStack = 0
    if killedUnit:HasModifier("modifier_soul_stack") then
        local hMod = killedUnit:FindModifierByName("modifier_soul_stack")
        if hMod then
            iStack = iStack + hMod:GetStackCount()
            hMod:Destroy()
        end
    end
    if killedUnit == attackerUnit or attackerUnit == nil then
        goto continue_1
    end
    if killedUnit:IsIllusion() then
        goto continue_1
    end
    iStack = iStack + 1
    if killedUnit:IsNeutralUnitType() then
        iStack = iStack + 2
        goto continue_1
    end
    if killedUnit:IsRealHero() then
        iStack = iStack + killedUnit:GetLevel()
        goto continue_1
    end

    ::continue_1::
    if iStack > 0 then
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
end
