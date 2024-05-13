MangoPartyPlugin = class({})
_G.MangoPartyPlugin = MangoPartyPlugin
MangoPartyPlugin.settings = {}

function MangoPartyPlugin:Init()
    print("[MangoPartyPlugin] found")
end

function MangoPartyPlugin:ApplySettings()
    MangoPartyPlugin.settings = PluginSystem:GetAllSetting("sb_mango_party")

    LinkLuaModifier( "modifier_mango_damage_stacks", "plugin_system/plugins/sb_mango_party/modifier_mango_damage_stacks", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "modifier_mango_check", "plugin_system/plugins/sb_mango_party/modifier_mango_check", LUA_MODIFIER_MOTION_NONE )

    ListenToGameEvent("game_rules_state_change", function()
        if (GameRules:State_Get()==DOTA_GAMERULES_STATE_PRE_GAME) then
            CreateModifierThinker(nil, nil, "modifier_mango_check", {}, Vector(0,0,0), DOTA_TEAM_NEUTRALS, false)
        end
    end, self)
    

end

function MangoPartyPlugin:DamageFilter(event)
	local attackerUnit = EntIndexToHScript(event.entindex_attacker_const)
	local victimUnit = EntIndexToHScript(event.entindex_victim_const)
	local abilityIndex = event.entindex_inflictor_const
	local ability = nil
	local damageType = event.damagetype_const
	local damage = event.damage

	if victimUnit then
		if abilityIndex then
			ability = EntIndexToHScript(abilityIndex)
			local name = ability:GetName()
			if name == "item_enchanted_mango" then
				return {true,event}
			end
			if name == "item_famango" then
				return {true,event}
			end
			if name == "item_great_famango" then
				return {true,event}
			end
			if name == "item_greater_famango" then
				return {true,event}
			end
		end
		if MangoPartyPlugin.settings.heroes_only and not victimUnit:IsHero() then return {true,event} end
		local modifier = victimUnit:FindModifierByName("modifier_mango_damage_stacks")
		if not modifier then 
			modifier = victimUnit:AddNewModifier(victimUnit, nil, "modifier_mango_damage_stacks", {})
		end
		modifier:SetStackCount(modifier:GetStackCount() + damage)
		return {false,event}
	end

	return {true,event}
end


function MangoPartyPlugin:ApplyMangoDamage(caster, ability)

	local casterParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(casterParticle, 1, caster:GetAbsOrigin())

	local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0,0,0), nil, 80000, DOTA_UNIT_TARGET_TEAM_FRIENDLY +
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)

	for k, unit in pairs(units) do
		if unit:HasModifier("modifier_mango_damage_stacks") then
			--Apply the damage
			local position = unit:GetAbsOrigin()
			local damageTable = {
				attacker = caster,
				victim = unit,
				ability = ability,
				damage = unit:FindModifierByName("modifier_mango_damage_stacks"):GetStackCount(),
				damage_type = DAMAGE_TYPE_PURE,
				damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
			}
			ApplyDamage(damageTable)
			unit:RemoveModifierByName("modifier_mango_damage_stacks")
			EmitSoundOnLocationWithCaster(position, "Hero_Zuus.LightningBolt", caster)

			local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_zuus/zuus_thundergods_wrath.vpcf", PATTACH_WORLDORIGIN, nil )
			ParticleManager:SetParticleControl( particle, 0, unit:GetAbsOrigin() + Vector(-200,-200,2000) )
			ParticleManager:SetParticleControl( particle, 1, unit:GetAbsOrigin() )

		end
	end
end