health_cap = health_cap or class({})



function health_cap:GetTexture() return end -- get the icon from a different ability

function health_cap:IsPermanent() return true end
function health_cap:RemoveOnDeath() return false end
function health_cap:IsHidden() return true end
function health_cap:IsDebuff() return false end

function health_cap:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function health_cap:OnCreated(event)
    if not IsServer() then return end
    self:StartIntervalThink(0.3)
end


function health_cap:OnIntervalThink()
    if not IsServer() then return end
    local health = self:GetParent():GetHealth()
    if (health > 500) then
        self:GetParent():SetHealth(500)
    end
end