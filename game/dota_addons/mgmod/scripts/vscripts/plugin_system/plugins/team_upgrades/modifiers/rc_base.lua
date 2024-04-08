rc_base = rc_base or class({})

function rc_base:IsPermanent() return true end
function rc_base:RemoveOnDeath() return false end
function rc_base:IsHidden() return  true end
function rc_base:IsDebuff() return false end
function rc_base:AllowIllusionDuplicate() return true end

function rc_base:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function rc_base:DeclareFunctions()
	local funcs = {
		$1,
	}
	return funcs
end

function rc_base:AddCustomTransmitterData()
    return self.data
end

function rc_base:OnCreated(event)
	if not IsServer() then return end
    if self.data == nil then
        self.data = {}
    end
    self.data.bonus = event.bonus or 0
    self:SetHasCustomTransmitterData(true)
    self:SendBuffRefreshToClients()
end

function rc_base:OnRefresh(event)
	if not IsServer() then return end
    if self.data == nil then
        self.data = {}
    end
    self.data.bonus = event.bonus or 0
    self:SendBuffRefreshToClients()
end

function rc_base:HandleCustomTransmitterData( data )
	self.data = {}
    for k,v in pairs(data) do
		self.data[k] = v
	end
end

function rc_base:UpdateValue(k,v)
	self.data[k] = v
	self:SendBuffRefreshToClients()
end

function rc_base:$2()
    return self.data.bonus
end
