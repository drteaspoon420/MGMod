AttacksCastSpellsPlugin = class({})
_G.AttacksCastSpellsPlugin = AttacksCastSpellsPlugin
AttacksCastSpellsPlugin.settings = {
}
AttacksCastSpellsPlugin.unit_cache = {}
AttacksCastSpellsPlugin.lists = {}

function AttacksCastSpellsPlugin:Init()
    --print("[AttacksCastSpellsPlugin] found")
end

function AttacksCastSpellsPlugin:ApplySettings()

    AttacksCastSpellsPlugin.settings = PluginSystem:GetAllSetting("attacks_cast_spells")
    local channelspecial = LoadKeyValues('scripts/vscripts/plugin_system/plugins/attacks_cast_spells/ability_limits/channelspecial.txt')
    if not (channelspecial == nil or not next(channelspecial)) then
        AttacksCastSpellsPlugin.lists.channelspecial = channelspecial
    else
        AttacksCastSpellsPlugin.lists.channelspecial = {}
    end

    local forced = LoadKeyValues('scripts/vscripts/plugin_system/plugins/attacks_cast_spells/ability_limits/forced.txt')
    if not (forced == nil or not next(forced)) then
        AttacksCastSpellsPlugin.lists.forced = forced
    else
        AttacksCastSpellsPlugin.lists.forced = {}
    end

    local illusion = LoadKeyValues('scripts/vscripts/plugin_system/plugins/attacks_cast_spells/ability_limits/illusion.txt')
    if not (illusion == nil or not next(illusion)) then
        AttacksCastSpellsPlugin.lists.illusion = illusion
    else
        AttacksCastSpellsPlugin.lists.illusion = {}
    end

    local normal = LoadKeyValues('scripts/vscripts/plugin_system/plugins/attacks_cast_spells/ability_limits/normal.txt')
    if not (normal == nil or not next(normal)) then
        AttacksCastSpellsPlugin.lists.normal = normal
    else
        AttacksCastSpellsPlugin.lists.normal = {}
    end

    local problematic = LoadKeyValues('scripts/vscripts/plugin_system/plugins/attacks_cast_spells/ability_limits/problematic.txt')
    if not (problematic == nil or not next(problematic)) then
        AttacksCastSpellsPlugin.lists.problematic = problematic
    else
        AttacksCastSpellsPlugin.lists.problematic = {}
    end

    local silence = LoadKeyValues('scripts/vscripts/plugin_system/plugins/attacks_cast_spells/ability_limits/silence.txt')
    if not (silence == nil or not next(silence)) then
        AttacksCastSpellsPlugin.lists.silence = silence
    else
        AttacksCastSpellsPlugin.lists.silence = {}
    end

    LinkLuaModifier( "modifier_attacks_cast_spells", "plugin_system/plugins/attacks_cast_spells/modifier_attacks_cast_spells", LUA_MODIFIER_MOTION_NONE )
    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        AttacksCastSpellsPlugin:SpawnEvent(event)
    end,nil)
    if AttacksCastSpellsPlugin.settings.forced_ability_leveling then
        ListenToGameEvent("dota_player_gained_level", function(event)
            if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
            AttacksCastSpellsPlugin:LevelUpEvent(event)
        end,nil)
    end

end

    
function AttacksCastSpellsPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        if AttacksCastSpellsPlugin.unit_cache[event.entindex] ~= nil then return end
        if not (AttacksCastSpellsPlugin.settings.core_apply_team == 0 or hUnit:GetTeam() == AttacksCastSpellsPlugin.settings.core_apply_team) then return end
        AttacksCastSpellsPlugin.unit_cache[event.entindex] = true
        local hModifier = hUnit:AddNewModifier(hUnit,nil,"modifier_attacks_cast_spells",{})
    end
end

function AttacksCastSpellsPlugin:LevelUpEvent(event)
    local hUnit = EntIndexToHScript(event.hero_entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        if not (AttacksCastSpellsPlugin.settings.core_apply_team == 0 or hUnit:GetTeam() == AttacksCastSpellsPlugin.settings.core_apply_team) then return end
        if hUnit:GetAbilityPoints() < 1 then
            return
        end
        for i=0,5 do
            local hAbility = hUnit:GetAbilityByIndex(i)
            if hAbility ~= nil and not hAbility:IsHidden() and hAbility:GetLevel() < 1 and hAbility:CanAbilityBeUpgraded() and hAbility:GetHeroLevelRequiredToUpgrade() <= hUnit:GetLevel() then
                hAbility:SetLevel(1)
                hUnit:SetAbilityPoints(hUnit:GetAbilityPoints()-1)
                return
            end
        end
    end
end
