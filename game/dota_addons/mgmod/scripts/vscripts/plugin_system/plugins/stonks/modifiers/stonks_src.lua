stonks_src = stonks_src or class({})



function stonks_src:GetTexture() return "stonks" end -- get the icon from a different ability
function stonks_src:IsPermanent() return true end
function stonks_src:RemoveOnDeath() return false end
function stonks_src:IsHidden() return false end
function stonks_src:IsDebuff() return false end
function stonks_src:AllowIllusionDuplicate() return true end

function stonks_src:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function stonks_src:OnCreated(event)
    if not IsServer() then return end
    if (event.stack ~= nil) then
        local total = event.stack
        if (total == 0) then
            self:SetStackCount(0)
            self:GetParent():CalculateStatBonus(true)
            self:GetParent():CalculateGenericBonuses()
            self:Destroy()
        else
            self:SetStackCount(total)
            self:GetParent():CalculateStatBonus(true)
            self:GetParent():CalculateGenericBonuses()
        end
    end
    if self:GetParent():IsIllusion() then
        self:SetStackCount(self:GetParent():GetPlayerOwner():GetAssignedHero():FindModifierByName(self:GetName()):GetStackCount())
    end
end

function stonks_src:OnRefresh(event)
    if not IsServer() then return end
    if (event.stack ~= nil) then
        local total = event.stack + self:GetStackCount()
        if (total == 0) then
            self:SetStackCount(0)
            self:GetParent():CalculateStatBonus(true)
            self:GetParent():CalculateGenericBonuses()
            self:Destroy()
        else
            self:SetStackCount(total)
            self:GetParent():CalculateStatBonus(true)
            self:GetParent():CalculateGenericBonuses()
        end
    end
end 

function stonks_src:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_REFLECT_SPELL,
	}
	return funcs
end

function stonks_src:GetReflectSpell(keys)
    if not IsServer() then return end
    local st = self:GetStackCount()
    local free = math.floor(st/1000)
    local remain = st%1000
    if free > 0 then
        for i=1,free do
        end
    end
    if RollPseudoRandomPercentage(remain*0.1,8002,self:GetParent()) then
        self:Reflect(keys)
    end
end

function stonks_src:Reflect(keys)
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local reflectedAbility = keys.ability
    local reflectedCaster = reflectedAbility:GetCaster()
    if IsValidEntity(self.reflect_stolen_ability) then
        self.reflect_stolen_ability:RemoveSelf()
    end
    local hAbility = parent:AddAbility(reflectedAbility:GetAbilityName())
    if hAbility then
        hAbility:SetStolen(true)
        hAbility:SetHidden(true)
        hAbility:SetLevel(reflectedAbility:GetLevel())
        parent:SetCursorCastTarget(reflectedCaster)
        hAbility:OnSpellStart()
        hAbility:SetActivated(false)
        self.reflect_stolen_ability = hAbility
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_spellshield.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(particle)
        parent:EmitSound("Hero_Antimage.SpellShield.Reflect")
    end
end