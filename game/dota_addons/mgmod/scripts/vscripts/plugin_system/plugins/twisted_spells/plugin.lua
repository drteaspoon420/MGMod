TwistedSpellsPlugin = class({})
_G.TwistedSpellsPlugin = TwistedSpellsPlugin
TwistedSpellsPlugin.settings = {}

function TwistedSpellsPlugin:Init()
    print("[TwistedSpellsPlugin] found")
end

function TwistedSpellsPlugin:ApplySettings()
    TwistedSpellsPlugin.settings = PluginSystem:GetAllSetting("twisted_spells")

    ListenToGameEvent("npc_spawned", function(event)
        local hUnit = EntIndexToHScript(event.entindex)
        if not hUnit.IsRealHero then return end
        if hUnit:IsRealHero() then
            if AttacksCastSpellsPlugin.unit_cache[event.entindex] ~= nil then return end
            AttacksCastSpellsPlugin.unit_cache[event.entindex] = true
            print("giving hero Chaos Cast")
            local ability = hUnit:AddAbility( "ability_chaos_cast" )
            ability:SetLevel(1)
        end
    end,nil)

end