tower_buffs_bonus_hp = tower_buffs_bonus_hp or class({})


function tower_buffs_bonus_hp:GetTexture() return "backdoor_protection" end

function tower_buffs_bonus_hp:IsPermanent() return true end
function tower_buffs_bonus_hp:RemoveOnDeath() return false end
function tower_buffs_bonus_hp:IsHidden() return true end
function tower_buffs_bonus_hp:IsDebuff() return false end
function tower_buffs_bonus_hp:IsPurgeException() return false end
function tower_buffs_bonus_hp:AllowIllusionDuplicate() return false end

function tower_buffs_bonus_hp:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function tower_buffs_bonus_hp:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS 
	}
	return funcs
end

function tower_buffs_bonus_hp:GetModifierExtraHealthBonus()
    return self:GetStackCount()
end
