modifier_rounds_tower_protect = class({})

function modifier_rounds_tower_protect:GetTexture() return "kumamoto" end
function modifier_rounds_tower_protect:IsPermanent() return true end
function modifier_rounds_tower_protect:RemoveOnDeath() return false end
function modifier_rounds_tower_protect:IsHidden() return false end
function modifier_rounds_tower_protect:IsDebuff() return false end
function modifier_rounds_tower_protect:IsPurgable() return false end
function modifier_rounds_tower_protect:IsPurgeException() return false end
function modifier_rounds_tower_protect:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_rounds_tower_protect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		
	}
	return funcs
end



function modifier_rounds_tower_protect:CheckState()
	local state = {
		[MODIFIER_STATE_SPECIALLY_UNDENIABLE] = true,
	}

	return state
end

function modifier_rounds_tower_protect:OnCreated(kv)
    if not IsServer() then return end
    self.team = self:GetParent():GetTeam()
    self.health = kv.health
    self.damage = kv.damage
	self:SetStackCount(100)
	self:StartIntervalThink(0.25)
    self:SetHasCustomTransmitterData(true)
	self:SendBuffRefreshToClients()
	if self:GetParent():HasModifier("modifier_invulnerable") then
		local iCount = self:GetParent():GetModifierCount()
		for i=0,iCount do
			local sName = self:GetParent():GetModifierNameByIndex(i)
			--print(sName)
		end
		self:GetParent():FindModifierByName("modifier_invulnerable"):Destroy()
	end
end

function modifier_rounds_tower_protect:OnDestroy()
    if not IsServer() then return end
end

function modifier_rounds_tower_protect:AddCustomTransmitterData()
    return {
		health = self.health,
		damage = self.damage,
	}
end

function modifier_rounds_tower_protect:HandleCustomTransmitterData( data )
	self.health = data.health
	self.damage = data.damage
end

function modifier_rounds_tower_protect:GetModifierExtraHealthBonus()
	return self.health or 0
end

function modifier_rounds_tower_protect:GetModifierBaseAttack_BonusDamage()
	return self.damage or 0
end

function modifier_rounds_tower_protect:GetModifierProvidesFOWVision()
	return 1
end



function modifier_rounds_tower_protect:OnIntervalThink()
    if not IsServer() then return end
	if RoundsPlugin == nil then return end
	if RoundsPlugin.hero_hashtable == nil then return end
	if RoundsPlugin.current_state ~= 2 then return end
	local vPos = self:GetParent():GetAbsOrigin()
	local iStackChange = self:GetStackCount()-1
	for hHero,v in pairs(RoundsPlugin.hero_hashtable) do
		if hHero ~= nil then
			if hHero:GetTeam() == self.team then
				local fDist = (hHero:GetAbsOrigin()-vPos):Length2D()
				if fDist < 800 then
					iStackChange = iStackChange + 2
				end
			end
		end
	end
	if iStackChange > 100 then iStackChange = 100 end
	if iStackChange < 0 then iStackChange = 0 end
	if iStackChange == self:GetStackCount() then return end
	self:SetStackCount(iStackChange)
end

function modifier_rounds_tower_protect:GetModifierPhysicalArmorBonus()
	return self:GetStackCount() * 0.25
end

function modifier_rounds_tower_protect:GetModifierMagicalResistanceBonus()
	return self:GetStackCount()
end