symbiosis = symbiosis or class({})


function symbiosis:GetTexture() return "symbiosis" end

function symbiosis:IsPermanent() return true end
function symbiosis:RemoveOnDeath() return false end
function symbiosis:IsHidden() return true end
function symbiosis:IsDebuff() return false end

function symbiosis:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function symbiosis:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_EVENT_ON_SET_LOCATION,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
	}
	return funcs
end

function symbiosis:OnCreated(event)
	if IsServer() then
		if self:ApplyHorizontalMotionController() == false then
			--print('woops, something went wrong')
			self:Destroy()
			return
		end
		self:SetStackCount(event.teamindex)
		--self:GetParent():SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
		self:GetParent():SetModelScale(0.01)
		self:StartIntervalThink(1)
	end
end

function symbiosis:OnRefresh(event)
end


function symbiosis:AllowIllusionDuplicate()
	return false
end

function symbiosis:OnHorizontalMotionInterrupted()
	if IsServer() then
		if self:ApplyHorizontalMotionController() == false then
			--print('woops, something went wrong')
			self:Destroy()
			return
		end
	end
end

function symbiosis:CheckState()
	local state = {
	[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_UNSELECTABLE] = true,
	[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_FROZEN] = true,
	[MODIFIER_STATE_OUT_OF_GAME] = true,
	[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
	[MODIFIER_STATE_INVISIBLE] = true,
	}
	if (self:GetCaster() ~= nil) then
		if (self:GetCaster():IsAlive()) then
			state[MODIFIER_STATE_STUNNED] = self:GetCaster():IsStunned()
			state[MODIFIER_STATE_SILENCED] = self:GetCaster():IsSilenced()
			state[MODIFIER_STATE_MUTED] = self:GetCaster():IsMuted()
			state[MODIFIER_STATE_COMMAND_RESTRICTED] = self:GetCaster():IsCommandRestricted()
			state[MODIFIER_STATE_DISARMED] = self:GetCaster():IsDisarmed()
		else
			state[MODIFIER_STATE_STUNNED] = true
			state[MODIFIER_STATE_SILENCED] = true
			state[MODIFIER_STATE_MUTED] = true
			state[MODIFIER_STATE_COMMAND_RESTRICTED] = true
			state[MODIFIER_STATE_DISARMED] = true
		end
	end
	return state
end

function symbiosis:GetModifierInvisibilityLevel()
  return 1
end

function symbiosis:OnIntervalThink()
	if IsServer() then
		if self:GetCaster() == nil then return end
		self:GetParent():SetModelScale(0.01)
	end
end

function symbiosis:UpdateHorizontalMotion( me, dt )
	if IsServer() then
		if self:GetCaster() == nil then return end
		local hParent = self:GetParent()
		local pos = self:GetCaster():GetAbsOrigin()
		local r = math.rad(((self:GetStackCount()*90)+GameRules:GetGameTime()*25)%360)
		local front = Vector(math.sin(r)*200,math.cos(r)*200,100)
		self:GetParent():SetModelScale(0.01)
		hParent:SetAbsOrigin(pos+front)
	end
end

function symbiosis:OnSetLocation (kv)
	if IsServer() then
		if kv.unit ~= self:GetParent() then return end
		self:GetParent():RemoveHorizontalMotionController( self )
		if self:ApplyHorizontalMotionController() == false then
			--print('woops, something went wrong')
			self:Destroy()
			return
		end
	    if self:GetCaster() ~= nil and not self:GetCaster():HasModifier("modifier_life_stealer_infest") then
				ProjectileManager:ProjectileDodge(self:GetCaster())
	      FindClearSpaceForUnit(self:GetCaster(),self:GetParent():GetOrigin(),true)
	    end
  end
end

function symbiosis:GetModifierModelScale()
	return 0.05
end

function symbiosis:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveHorizontalMotionController( self )
		
		data = {}
		data.teamindex = self:GetStackCount()
		self:GetParent():AddNewModifier(self:GetCaster(), nil, self:GetName(), data)
	end
end