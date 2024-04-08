health_cap = health_cap or class({})



function health_cap:GetTexture() return end -- get the icon from a different ability

function health_cap:IsPermanent() return true end
function health_cap:RemoveOnDeath() return false end
function health_cap:IsHidden() return true end
function health_cap:IsDebuff() return false end

function health_cap:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function health_cap:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_FORCE_MAX_HEALTH,
	}
	return funcs
end

function health_cap:GetModifierForceMaxHealth()
	return 500
end

