tower_buffs_bonus_hp_regen = tower_buffs_bonus_hp_regen or class({})


function tower_buffs_bonus_hp_regen:GetTexture() return "backdoor_protection" end

function tower_buffs_bonus_hp_regen:IsPermanent() return true end
function tower_buffs_bonus_hp_regen:RemoveOnDeath() return false end
function tower_buffs_bonus_hp_regen:IsHidden() return true end
function tower_buffs_bonus_hp_regen:IsDebuff() return false end
function tower_buffs_bonus_hp_regen:IsPurgeException() return false end
function tower_buffs_bonus_hp_regen:AllowIllusionDuplicate() return false end

function tower_buffs_bonus_hp_regen:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function tower_buffs_bonus_hp_regen:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
	}
	return funcs
end

function tower_buffs_bonus_hp_regen:GetModifierConstantHealthRegen()
    return self:GetStackCount()
end
