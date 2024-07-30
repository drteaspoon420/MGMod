boost_scaling_bonus_hp = boost_scaling_bonus_hp or class({})


function boost_scaling_bonus_hp:GetTexture() return "backdoor_protection" end

function boost_scaling_bonus_hp:IsPermanent() return true end
function boost_scaling_bonus_hp:RemoveOnDeath() return false end
function boost_scaling_bonus_hp:IsHidden() return true end
function boost_scaling_bonus_hp:IsDebuff() return false end
function boost_scaling_bonus_hp:IsPurgeException() return false end
function boost_scaling_bonus_hp:AllowIllusionDuplicate() return false end

function boost_scaling_bonus_hp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function boost_scaling_bonus_hp:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS 
	}
	return funcs
end

function boost_scaling_bonus_hp:GetModifierExtraHealthBonus()
    return self:GetStackCount()
end
