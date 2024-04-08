modifier_items_x = modifier_items_x or class({})


function modifier_items_x:GetTexture() return "alchemist_chemical_rage" end

function modifier_items_x:IsPermanent() return true end
function modifier_items_x:RemoveOnDeath() return false end
function modifier_items_x:IsHidden() return true end 	-- we can hide the modifier
function modifier_items_x:IsDebuff() return false end 	-- make it red or green
function modifier_items_x:IsPurgeException() return false end
function modifier_items_x:AllowIllusionDuplicate() return true end

modifier_items_x.blocklist = {
    AbilityCastPoint = 1,
    AbilityCooldown = 1,
    AbilityManaCost = 1,
    AbilityCastRange = 1,
    AbilityOvershootCastRange = 1,
    AbilityChannelTime = 1,
    bonus_cooldown = 1,
}

function modifier_items_x:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_items_x:OnCreated(kv)
	self.data = {}
    self.data.nerfs = {}
	if not IsServer() then return end
    self.data.core_multiplier = kv.core_multiplier
    self.data.nerfs.duration = kv.mod_duration
    self.data.nerfs.chance = kv.mod_chance
    self.data.nerfs.radius = kv.mod_radius
    self:SetHasCustomTransmitterData(true)
	self:SendBuffRefreshToClients()
end

function modifier_items_x:OnRefresh(kv)
	if not IsServer() then return end
	self:SendBuffRefreshToClients()
end

function modifier_items_x:AddCustomTransmitterData()
    return self.data
end

function modifier_items_x:HandleCustomTransmitterData( data )
	self.data = {}
    for k,v in pairs(data) do
		self.data[k] = v
	end
end

function modifier_items_x:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
	return funcs
end


function modifier_items_x:GetModifierOverrideAbilitySpecial( params )
	if self:GetParent() == nil or params.ability == nil then
		return 0
	end
    if not params.ability:IsItem() then return 0 end
    if modifier_items_x.blocklist[params.ability_special_value] ~= nil then return 0 end
	return 1
end

function modifier_items_x:GetModifierOverrideAbilitySpecialValue( params )
    local mult = self.data.core_multiplier or 10
	local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( params.ability_special_value, params.ability_special_level )
    for k,v in pairs(self.data.nerfs) do
        if string.find(params.ability_special_value,k) ~= nil then
            return flBaseValue * mult * v
        end
    end
	return flBaseValue * mult
end