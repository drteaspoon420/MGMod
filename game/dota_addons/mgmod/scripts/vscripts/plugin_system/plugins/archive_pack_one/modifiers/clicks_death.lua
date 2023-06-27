clicks_death = clicks_death or class({})

function clicks_death:GetTexture() return "clicks_death" end

function clicks_death:IsPermanent() return true end
function clicks_death:RemoveOnDeath() return false end
function clicks_death:IsHidden() return true end
function clicks_death:IsDebuff() return false end

function clicks_death:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function clicks_death:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ORDER
	}
	return funcs
end
 
function clicks_death:OnOrder(event)
	if not IsServer() then return end
	if event.unit == self:GetParent() then self:Click() end
end


function clicks_death:OnCreated(event)
	if not IsServer() then return end
	self.active = false
end

function clicks_death:Click()
	if not IsServer() then return end
	if not self:GetParent():IsAlive() or self.active then return end
	self:SetStackCount(self:GetStackCount()+1)
	if self:GetStackCount() >= 100 and not self.active then
		self:ClickDeath()
	end
end


function clicks_death:ClickDeath()
	self.active = true
	if not self:GetParent():WillReincarnate() and not self:GetParent():IsReincarnating() then
		self:SetStackCount(0)
	end
	local vpos = self:GetParent():GetAbsOrigin()
	local fx = ParticleManager:CreateParticle( "particles/necro_ti7_immortal_scythe_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW , "attach_origin", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW , "attach_origin", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOn("click_death",self:GetParent())
	Timers:CreateTimer(1.4, function ()
		self.active = false
		self:GetParent():ForceKill(false)
	end)
end
