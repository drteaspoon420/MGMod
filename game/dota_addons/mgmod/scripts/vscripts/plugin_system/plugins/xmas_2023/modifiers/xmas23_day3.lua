xmas23_day3 = class({})


--function xmas23_day3:GetTexture() return "kumamoto" end
function xmas23_day3:IsPermanent() return true end
function xmas23_day3:RemoveOnDeath() return false end
function xmas23_day3:IsHidden() return true end
function xmas23_day3:IsDebuff() return false end
function xmas23_day3:IsPurgable() return false end
function xmas23_day3:IsPurgeException() return false end
function xmas23_day3:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function xmas23_day3:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
	}
	return funcs
end

function xmas23_day3:OnCreated(kv)
    self.boost = {}
    if not IsServer() then return end
    self:StartIntervalThink(3.14159265359)
    self:SetHasCustomTransmitterData(true)
    self:SendBuffRefreshToClients()
end

function xmas23_day3:HandleCustomTransmitterData( data )
	self.boost = {}
    for k,v in pairs(data) do
		self.boost[k] = v
	end
end

function xmas23_day3:AddCustomTransmitterData()
    return self.boost
end

function xmas23_day3:UpdateValue(k,v)
	self.boost[k] = v
	self:SendBuffRefreshToClients()
end


function xmas23_day3:OnIntervalThink()
    if not IsServer() then return end
    local hUnit = self:GetParent()
    if hUnit ~= nil and hUnit:HasInventory() then
		local sItem = ""
		local iCount = 0
        for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
            local item = hUnit:GetItemInSlot(i)
            if item ~= nil then
				if sItem == item:GetAbilityName() then
					iCount = iCount + 1
				else
					sItem = item:GetAbilityName()
					iCount = 1
				end
            end
        end
		if iCount == 6 then
			for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_5 do
				local item = hUnit:GetItemInSlot(i)
				if item ~= nil then
					hUnit:RemoveItem(item)
				end
			end
			local hItem = hUnit:GetItemInSlot(DOTA_ITEM_SLOT_6)
			if self.boost[sItem] == nil then
				self:UpdateValue(sItem,3)
			else
				self:UpdateValue(sItem,self.boost[sItem]+3)
			end
			hItem:OnUnequip()
			Timers:CreateTimer( 0, function()
				hItem:OnEquip()
			end)
		end
    end
end

function xmas23_day3:GetModifierOverrideAbilitySpecial(kv)
	if self.boost == nil then return 0 end
	if self.boost[kv.ability:GetAbilityName()] == nil then
        return 0
    end
    return 1
end
function xmas23_day3:GetModifierOverrideAbilitySpecialValue( kv )
    local v = kv.ability:GetLevelSpecialValueNoOverride(kv.ability_special_value,kv.ability_special_level)
    return self.boost[kv.ability:GetAbilityName()] * v
end