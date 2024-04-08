xmas23_day9 = class({})


--function xmas23_day9:GetTexture() return "kumamoto" end
function xmas23_day9:IsPermanent() return true end
function xmas23_day9:RemoveOnDeath() return false end
function xmas23_day9:IsHidden() return true end
function xmas23_day9:IsDebuff() return false end
function xmas23_day9:IsPurgable() return false end
function xmas23_day9:IsPurgeException() return false end
function xmas23_day9:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function xmas23_day9:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_FORCE_MAX_HEALTH,
	}
	return funcs
end

function xmas23_day9:OnCreated(kv)
    if not IsServer() then return end
    self:SetHasCustomTransmitterData(true)
    self:SendBuffRefreshToClients()
end

function xmas23_day9:OnRefresh(kv)
    if not IsServer() then return end
    self:SetHasCustomTransmitterData(true)
    self:SendBuffRefreshToClients()
end

function xmas23_day2:HandleCustomTransmitterData( data )
	self.sync = {}
    for k,v in pairs(data) do
		self.sync[k] = v
	end
end


function xmas23_day2:AddCustomTransmitterData()
    return self.sync
end


function xmas23_day9:GetModifierForceMaxHealth( event )
    return self.sync.value
end