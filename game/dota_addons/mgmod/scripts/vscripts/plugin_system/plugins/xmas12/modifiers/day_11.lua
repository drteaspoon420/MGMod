day_11 = class({})

--function day_11:GetTexture() return "kumamoto" end
function day_11:IsPermanent() return false end
function day_11:RemoveOnDeath() return true end
function day_11:IsHidden() return false end
function day_11:IsDebuff() return false end
function day_11:IsPurgable() return false end
function day_11:IsPurgeException() return false end
function day_11:GetAttributes()
	return  MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function day_11:DeclareFunctions()
	local funcs = {
       -- MODIFIER_PROPERTY_SUPER_ILLUSION_WITH_ULTIMATE,
        MODIFIER_PROPERTY_SUPER_ILLUSION,
	}
	return funcs
end

function day_11:GetModifierSuperIllusionWithUltimate()
    return true
end

function day_11:GetModifierSuperIllusion()
    return true
end
