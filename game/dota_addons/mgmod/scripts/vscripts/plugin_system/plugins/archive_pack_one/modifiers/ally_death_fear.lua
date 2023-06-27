ally_death_fear = class({})


function ally_death_fear:GetTexture() return "kumamoto" end
function ally_death_fear:IsPermanent() return true end
function ally_death_fear:RemoveOnDeath() return false end
function ally_death_fear:IsHidden() return true end
function ally_death_fear:IsDebuff() return false end
function ally_death_fear:IsPurgable() return false end
function ally_death_fear:IsPurgeException() return false end
function ally_death_fear:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function ally_death_fear:DeclareFunctions()
	local funcs = {
        MODIFIER_EVENT_ON_DEATH
	}
	return funcs
end

function ally_death_fear:OnCreated(kv)
    if not IsServer() then return end
end
function ally_death_fear:OnDeath(kv)
	if not IsServer() then return end
    if kv.unit == self:GetParent() then return end
    if kv.unit:GetTeam() ~= self:GetParent():GetTeam() then return end
    if not self:GetParent():IsAlive() then return end
    if CalcDistanceBetweenEntityOBB(kv.unit,self:GetParent()) < 600 then
        self:GetParent():AddNewModifier(self:GetParent(),nil,"modifier_fear",{duration = 3})
    end
end

function ally_death_fear:OnModifierAdded(kv)
	if not IsServer() then return end
    if kv.unit == self:GetParent() then return end
end