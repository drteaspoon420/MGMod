modifier_boosted = modifier_boosted or class({})


function modifier_boosted:GetTexture() return "alchemist_chemical_rage" end

function modifier_boosted:IsPermanent() return true end
function modifier_boosted:RemoveOnDeath() return false end
function modifier_boosted:IsHidden() return true end 	-- we can hide the modifier
function modifier_boosted:IsDebuff() return false end 	-- make it red or green
function modifier_boosted:IsPurgeException() return false end
function modifier_boosted:AllowIllusionDuplicate() return true end

function modifier_boosted:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_boosted:OnCreated(kv)
	self.boost = {}
	if not IsServer() then return end
    self:SetHasCustomTransmitterData(true)
end
function modifier_boosted:OnRefresh(kv)
	if not IsServer() then return end
end

function modifier_boosted:DeclareFunctions()
--[[ 	if not (self:GetParent():GetTeamNumber() == DOTA_TEAM_BADGUYS or self:GetParent():GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
		return {
			MODIFIER_EVENT_ON_DOMINATED,
		}
	end ]]
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
		MODIFIER_EVENT_ON_DOMINATED,
	}
	return funcs
end

function modifier_boosted:OnDominated(kv)
	if not IsServer() then return end
--[[ 	self:ForceRefresh() ]]
    local playerId = self:GetParent():GetPlayerID()
	if playerId == nil or playerId < 0 then return end
	if kv.unit:GetMainControllingPlayer() ~= nil and kv.unit:GetMainControllingPlayer() == playerId then
	    local hMod = kv.unit:AddNewModifier(kv.unit, nil, HeroUpgrades.main_modifier_name, {})
		
        Timers:CreateTimer( 1, function()
			if hMod.RequestFull ~= nil then
				hMod:RequestFull()
			end
		end)
	end
end
function modifier_boosted:UpdateValue(a,k,v)
	self.boost[a .. "|" .. k] = v
	self:SendBuffRefreshToClients()
end

function modifier_boosted:RequestFull()
	local hUnit = self:GetParent()
    local t = HeroUpgrades:GetAllAbilities(hUnit)
	self.boost = HeroUpgrades:RequestAllAbilityValues(t,hUnit:GetTeam())
	self:SendBuffRefreshToClients()
end

function modifier_boosted:AddCustomTransmitterData()
    return self.boost
end

function modifier_boosted:HandleCustomTransmitterData( data )
	self.boost = {}
    for k,v in pairs(data) do
		self.boost[k] = v
	end
end

function modifier_boosted:GetModifierOverrideAbilitySpecial( params )
	if self:GetParent() == nil or params.ability == nil then
		return 0
	end
	if (self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS) then
		return 0
	end
	if self.boost == nil then return 0 end
	local szAbilityName = params.ability:GetAbilityName()
	local szSpecialValueName = params.ability_special_value
	local k = szAbilityName .. "|" .. szSpecialValueName
--[[ 	if IsInToolsMode() then
		print(k)
	end ]]
	if self.boost[k] == nil then return 0 end
	if self.boost[k] == 1 then return 0 end
	return 1
end

function modifier_boosted:GetModifierOverrideAbilitySpecialValue( params )
	local szAbilityName = params.ability:GetAbilityName() 
	local szSpecialValueName = params.ability_special_value
	local k = szAbilityName .. "|" .. szSpecialValueName
	local nSpecialLevel = params.ability_special_level
	local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( szSpecialValueName, nSpecialLevel )
	local fBoost = self.boost[k]
	return flBaseValue * fBoost
end