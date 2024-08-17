boost_scaling_bonus_damage = boost_scaling_bonus_damage or class({})


function boost_scaling_bonus_damage:GetTexture() return "backdoor_protection" end

function boost_scaling_bonus_damage:IsPermanent() return true end
function boost_scaling_bonus_damage:RemoveOnDeath() return false end
function boost_scaling_bonus_damage:IsHidden() return true end
function boost_scaling_bonus_damage:IsDebuff() return false end
function boost_scaling_bonus_damage:IsPurgeException() return false end
function boost_scaling_bonus_damage:AllowIllusionDuplicate() return false end

function boost_scaling_bonus_damage:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function boost_scaling_bonus_damage:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE
	}
	return funcs
end

function boost_scaling_bonus_damage:GetModifierBaseAttack_BonusDamage()
    return self:GetStackCount()
end
