no_backdoor = no_backdoor or class({})


function no_backdoor:GetTexture() return "alchemist_chemical_rage" end

function no_backdoor:IsPermanent() return true end
function no_backdoor:RemoveOnDeath() return false end
function no_backdoor:IsHidden() return true end
function no_backdoor:IsDebuff() return false end
function no_backdoor:IsPurgeException() return false end
function no_backdoor:AllowIllusionDuplicate() return false end

function no_backdoor:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function no_backdoor:CheckState()
    --local active = self:GetStackCount() == 1
    local active = self:GetParent():HasModifier("modifier_backdoor_protection_active")
	local funcs = {
        [MODIFIER_STATE_ATTACK_IMMUNE] = active,
        [MODIFIER_STATE_MAGIC_IMMUNE] = active
	}
	return funcs
end

function no_backdoor:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
	return funcs
end

function no_backdoor:GetModifierIncomingDamage_Percentage()
    if self:GetParent():HasModifier("modifier_backdoor_protection_active") then
        return -1000 -- * self:GetStackCount()
    else
        return 0
    end
end

--[[ function no_backdoor:OnCreated(data)
    if not IsServer() then return end
    --self:StartIntervalThink(1)
end


function no_backdoor:OnIntervalThink()
    if not IsServer() then return end
    local hUnit = self:GetParent()
    if hUnit:HasModifier("modifier_backdoor_protection_active") then
        self:SetStackCount(1)
    else
        self:SetStackCount(0)
    end
end ]]