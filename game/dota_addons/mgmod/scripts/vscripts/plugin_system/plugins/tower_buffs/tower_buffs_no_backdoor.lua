tower_buffs_no_backdoor = tower_buffs_no_backdoor or class({})


function tower_buffs_no_backdoor:GetTexture() return "alchemist_chemical_rage" end

function tower_buffs_no_backdoor:IsPermanent() return true end
function tower_buffs_no_backdoor:RemoveOnDeath() return false end
function tower_buffs_no_backdoor:IsHidden() return true end
function tower_buffs_no_backdoor:IsDebuff() return false end
function tower_buffs_no_backdoor:IsPurgeException() return false end
function tower_buffs_no_backdoor:AllowIllusionDuplicate() return false end

function tower_buffs_no_backdoor:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function tower_buffs_no_backdoor:CheckState()
    local active = self:GetParent():HasModifier("modifier_backdoor_protection_active")
	local funcs = {
        [MODIFIER_STATE_ATTACK_IMMUNE] = active,
        [MODIFIER_STATE_MAGIC_IMMUNE] = active
	}
	return funcs
end

function tower_buffs_no_backdoor:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
	return funcs
end

function tower_buffs_no_backdoor:GetModifierIncomingDamage_Percentage()
    if self:GetParent():HasModifier("modifier_backdoor_protection_active") then
        return -1000
    else
        return 0
    end
end
