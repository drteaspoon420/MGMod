boost_scaling_bonus_armor = boost_scaling_bonus_armor or class({})


function boost_scaling_bonus_armor:GetTexture() return "backdoor_protection" end

function boost_scaling_bonus_armor:IsPermanent() return true end
function boost_scaling_bonus_armor:RemoveOnDeath() return false end
function boost_scaling_bonus_armor:IsHidden() return true end
function boost_scaling_bonus_armor:IsDebuff() return false end
function boost_scaling_bonus_armor:IsPurgeException() return false end
function boost_scaling_bonus_armor:AllowIllusionDuplicate() return false end

function boost_scaling_bonus_armor:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function boost_scaling_bonus_armor:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
	return funcs
end

function boost_scaling_bonus_armor:GetModifierPhysicalArmorBonus()
    return self:GetStackCount()
end
