boost_scaling_bonus_magic_resistance = boost_scaling_bonus_magic_resistance or class({})


function boost_scaling_bonus_magic_resistance:GetTexture() return "backdoor_protection" end

function boost_scaling_bonus_magic_resistance:IsPermanent() return true end
function boost_scaling_bonus_magic_resistance:RemoveOnDeath() return false end
function boost_scaling_bonus_magic_resistance:IsHidden() return true end
function boost_scaling_bonus_magic_resistance:IsDebuff() return false end
function boost_scaling_bonus_magic_resistance:IsPurgeException() return false end
function boost_scaling_bonus_magic_resistance:AllowIllusionDuplicate() return false end

function boost_scaling_bonus_magic_resistance:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function boost_scaling_bonus_magic_resistance:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
	return funcs
end

function boost_scaling_bonus_magic_resistance:GetModifierMagicalResistanceBonus()
    return self:GetStackCount()
end
