xmas23_day7 = class({})


--function xmas23_day7:GetTexture() return "kumamoto" end
function xmas23_day7:IsPermanent() return true end
function xmas23_day7:RemoveOnDeath() return false end
function xmas23_day7:IsHidden() return true end
function xmas23_day7:IsDebuff() return false end
function xmas23_day7:IsPurgable() return false end
function xmas23_day7:IsPurgeException() return false end
function xmas23_day7:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function xmas23_day7:DeclareFunctions()
	local funcs = {
        MODIFIER_EVENT_ON_DAMAGE_HPLOSS,
	}
	return funcs
end

function xmas23_day7:OnCreated(kv)
    if not IsServer() then return end
end


function xmas23_day7:OnDamageHPLoss( event )
    return 10
end