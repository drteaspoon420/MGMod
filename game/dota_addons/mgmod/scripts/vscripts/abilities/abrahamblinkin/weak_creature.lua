LinkLuaModifier("modifier_weak_creature", "abilities/abrahamblinkin/weak_creature", LUA_MODIFIER_MOTION_NONE )

weak_creature = class ({})

function weak_creature:Spawn()
	self.damage = 1
	self.radius = 1
	self.heal = 1
	self.mana = 1
end

function weak_creature:GetIntrinsicModifierName()
  return "modifier_weak_creature"
end

modifier_weak_creature = modifier_weak_creature or class({})

function modifier_weak_creature:GetTexture() return "item_blades_of_attack" end

function modifier_weak_creature:IsPermanent() return true end
function modifier_weak_creature:RemoveOnDeath() return true end
function modifier_weak_creature:IsDebuff() return true end
function modifier_weak_creature:IsPurgable() return false end
function modifier_weak_creature:IsHidden() return true end

function modifier_weak_creature:CheckState()
	state = {
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		-- [MODIFIER_STATE_OUT_OF_GAME] = true, --breaks swashbuckle
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
		[MODIFIER_STATE_IGNORING_STOP_ORDERS] = true
	}
	return state
end

function modifier_weak_creature:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_MP_RESTORE_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE
	}
	return funcs
end

function modifier_weak_creature:OnCreated()
	self:StartIntervalThink(8)
	if not IsServer() then return end
	self.damage_percent = TwistedSpellsPlugin.settings.damage_percent
	self.heal_percent = TwistedSpellsPlugin.settings.heal_percent
	self.mana_percent = TwistedSpellsPlugin.settings.mana_percent
	self.radius_percent = TwistedSpellsPlugin.settings.radius_percent
    self:SetHasCustomTransmitterData(true)
	self:SendBuffRefreshToClients()
end

function modifier_weak_creature:AddCustomTransmitterData()
    return {
		damage_percent = self.damage_percent,
		heal_percent = self.heal_percent,
		mana_percent = self.mana_percent,
		radius_percent = self.radius_percent
	}
end

function modifier_weak_creature:HandleCustomTransmitterData( data )
	self.damage_percent = data.damage_percent
	self.heal_percent = data.heal_percent
	self.mana_percent = data.mana_percent
	self.radius_percent = data.radius_percent
end

function modifier_weak_creature:OnIntervalThink()
	-- UTIL_Remove(self:GetParent())
end

function modifier_weak_creature:GetModifierDamageOutgoing_Percentage()
	return -100 + self.damage_percent * self:GetAbility().damage
end

function modifier_weak_creature:GetModifierHealAmplify_PercentageSource()
	return -100 + self.heal_percent * self:GetAbility().heal
end

function modifier_weak_creature:GetModifierMPRestoreAmplify_Percentage()
	return -100 + self.mana_percent * self:GetAbility().mana
end

function modifier_weak_creature:GetModifierOverrideAbilitySpecial( params )
    local szSpecialValueName = params.ability_special_value
	if string.match(szSpecialValueName, "radius") then
		return 1
	end
	return 0
end

function modifier_weak_creature:GetModifierOverrideAbilitySpecialValue( params )

	if params.ability:IsItem() then return end

	local szAbilityName = params.ability:GetAbilityName()
	local szSpecialValueName = params.ability_special_value
	local nSpecialLevel = params.ability_special_level
	local base_value = params.ability:GetLevelSpecialValueNoOverride( szSpecialValueName, nSpecialLevel )
	local ability = self:GetAbility()
	local amped = base_value

	if string.match(szSpecialValueName, "radius") then
		base_value = base_value * (ability.radius) * ( self.radius_percent/100 )
	end

	return base_value
end

function modifier_weak_creature:GetModifierPercentageCooldown()
	return 100
end