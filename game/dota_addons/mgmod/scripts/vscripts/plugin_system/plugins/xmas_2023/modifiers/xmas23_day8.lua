
xmas23_day8 = class({})


--function xmas23_day8:GetTexture() return "kumamoto" end
function xmas23_day8:IsPermanent() return true end
function xmas23_day8:RemoveOnDeath() return false end
function xmas23_day8:IsHidden() return true end
function xmas23_day8:IsDebuff() return false end
function xmas23_day8:IsPurgable() return false end
function xmas23_day8:IsPurgeException() return false end
function xmas23_day8:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function xmas23_day8:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_AOE_BONUS_CONSTANT,
	}
	return funcs
end

function xmas23_day8:OnCreated(kv)
    if not IsServer() then return end
end


function xmas23_day8:GetModifierAoEBonusConstant( event )
    return 10
end