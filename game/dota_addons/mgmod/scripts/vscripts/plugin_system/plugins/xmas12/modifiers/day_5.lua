day_5 = class({})


--function day_5:GetTexture() return "kumamoto" end
function day_5:IsPermanent() return true end
function day_5:RemoveOnDeath() return false end
function day_5:IsHidden() return true end
function day_5:IsDebuff() return false end
function day_5:IsPurgable() return false end
function day_5:IsPurgeException() return false end
function day_5:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function day_5:DeclareFunctions()
	local funcs = {
	}
	return funcs
end

function day_5:OnCreated(kv)
    if not IsServer() then return end
    self:StartIntervalThink(1)
end

function day_5:OnIntervalThink()
    if not IsServer() then return end
    local hParent = self:GetParent()
    local vPos = hParent:GetAbsOrigin()
    local fRadius = 600
    local tUnits = FindUnitsInRadius(
        hParent:GetTeam(),
        vPos,
        nil,
        fRadius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_ALL,
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
        0,
        false
    )
    if #tUnits < 2 then
        hParent:AddNewModifier(hParent,nil,"modifier_fear",{duration = 1.2})
    end
end

