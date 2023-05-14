day_12 = class({})

--function day_12:GetTexture() return "kumamoto" end
function day_12:IsPermanent() return true end
function day_12:RemoveOnDeath() return false end
function day_12:IsHidden() return false end
function day_12:IsDebuff() return false end
function day_12:IsPurgable() return false end
function day_12:IsPurgeException() return false end
function day_12:GetAttributes()
	return  MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end


function day_12:OnCreated(kv)
    if not IsServer() then return end
    if self:GetParent():IsRealHero() then
        self:StartIntervalThink(0.3)
    end
end

function day_12:OnIntervalThink()
    if not IsServer() then return end
    local hParent = self:GetParent()
    local fTrace = 10
    while (fTrace < 400) do
        local nPos = hParent:GetAbsOrigin() + hParent:GetForwardVector() * (fTrace + 10)
        if GridNav:IsTraversable(nPos) and not GridNav:IsNearbyTree(nPos,10,false) then
            fTrace = fTrace + 10
        else
            break
        end
    end
    local vPos = hParent:GetAbsOrigin() + hParent:GetForwardVector() * fTrace
    AddFOWViewer(hParent:GetTeam(),vPos,fTrace,0.4,true)
end


function day_12:DeclareFunctions()
	local funcs = {
       MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE ,
	}
	return funcs
end

function day_12:GetBonusVisionPercentage()
    return -100
end

