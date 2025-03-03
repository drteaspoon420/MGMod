TwistedSpellsPlugin = class({})
_G.TwistedSpellsPlugin = TwistedSpellsPlugin
TwistedSpellsPlugin.settings = {}

function TwistedSpellsPlugin:Init()
    --print("[TwistedSpellsPlugin] found")
end

function TwistedSpellsPlugin:ApplySettings()
    TwistedSpellsPlugin.settings = PluginSystem:GetAllSetting("twisted_spells")

    ListenToGameEvent("npc_spawned", function(event)
        local hUnit = EntIndexToHScript(event.entindex)
        if not hUnit.IsRealHero then return end
        if hUnit:IsRealHero() then
            if AttacksCastSpellsPlugin.unit_cache[event.entindex] ~= nil then return end
            AttacksCastSpellsPlugin.unit_cache[event.entindex] = true
            --print("giving hero Chaos Cast")
            local ability = hUnit:AddAbility( "ability_chaos_cast" )
            ability:SetLevel(1)
        end
    end,nil)

end

function TwistedSpellsPlugin:DamageFilter(event)
    local attackerUnit = event.entindex_attacker_const and EntIndexToHScript(event.entindex_attacker_const)
    local victimUnit = event.entindex_victim_const and EntIndexToHScript(event.entindex_victim_const)
    local ability = event.entindex_inflictor_const and EntIndexToHScript(event.entindex_inflictor_const)

    if attackerUnit.hero_parent~=nil and attackerUnit.hero_parent:IsRealHero() then
        local damage_table = {
            victim = victimUnit,
            attacker = attackerUnit.hero_parent,
            damage = event.damage/100*TwistedSpellsPlugin.settings.damage_percent,
            damage_type = event.damagetype_const,
            ability = ability
        }
        ApplyDamage(damage_table)
        attackerUnit.hero_parent:IsRealHero()

        event.damage = 0
    end

    return {true,event}
end