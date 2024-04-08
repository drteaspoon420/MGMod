xmas23_day5 = class({})


function xmas23_day5:GetTexture() return "kumamoto" end
function xmas23_day5:IsPermanent() return true end
function xmas23_day5:RemoveOnDeath() return false end
function xmas23_day5:IsHidden() return false end
function xmas23_day5:IsDebuff() return false end
function xmas23_day5:IsPurgable() return false end
function xmas23_day5:IsPurgeException() return false end
function xmas23_day5:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function xmas23_day5:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
	return funcs
end

function xmas23_day5:OnCreated(kv)
    if not IsServer() then return end
end

function xmas23_day5:GetModifierTotalDamageOutgoing_Percentage()
    return 300
end
