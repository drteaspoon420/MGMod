tower_buffs_bonus_armor = tower_buffs_bonus_armor or class({})


function tower_buffs_bonus_armor:GetTexture() return "backdoor_protection" end

function tower_buffs_bonus_armor:IsPermanent() return true end
function tower_buffs_bonus_armor:RemoveOnDeath() return false end
function tower_buffs_bonus_armor:IsHidden() return true end
function tower_buffs_bonus_armor:IsDebuff() return false end
function tower_buffs_bonus_armor:IsPurgeException() return false end
function tower_buffs_bonus_armor:AllowIllusionDuplicate() return false end

function tower_buffs_bonus_armor:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function tower_buffs_bonus_armor:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
	return funcs
end

function tower_buffs_bonus_armor:GetModifierPhysicalArmorBonus()
    return self:GetStackCount()
end
