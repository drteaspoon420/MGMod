if modifier_ability_link == nil then
    modifier_ability_link = class({})
end
function modifier_ability_link:IsDebuff() return false end
function modifier_ability_link:DestroyOnExpire() return false end
function modifier_ability_link:IsDebuff() return false end
function modifier_ability_link:IsHidden() return false end
function modifier_ability_link:IsPermanent() return true end
function modifier_ability_link:IsPurgable() return false end
function modifier_ability_link:IsPurgeException() return false end
function modifier_ability_link:IsStunDebuff() return false end
function modifier_ability_link:AllowIllusionDuplicate() return false end
function modifier_ability_link:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_ability_link:OnCreated(keys)
    if not IsServer() then return end
    self.linked = {}
	self:StartIntervalThink(1)
end

function modifier_ability_link:OnIntervalThink()
    if not IsServer() then return end

    local hMain = self:GetAbility()
    if hMain == nil then return end
    local iLevel = hMain:GetLevel()
    for i=1,#self.linked do
        local hAbility = self.linked[i];
        if hAbility ~= nil and hAbility:GetLevel() ~= iLevel then
            hAbility:SetLevel(iLevel)
        end
    end
end

function modifier_ability_link:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ABILITY_EXECUTED}
end

function modifier_ability_link:SetLink(hAbility)
    table.insert(self.linked,hAbility)
end

function modifier_ability_link:OnAbilityExecuted(keys)
    if not IsServer() then return end
    if keys.ability ~= self:GetAbility() then return end
    for i=1,#self.linked do
        local hAbility = self.linked[i];
        local hParent = self:GetParent()
        modifier_ability_link:CastAbility(hAbility,keys,hParent)
    end
end


function modifier_ability_link:CastAbility(hAbility,keys,hParent)
    local vTarget = keys.new_pos or hParent:GetAbsOrigin()
    local hTarget = keys.target or hParent
    hParent:SetCursorPosition(vTarget)
    hParent:SetCursorCastTarget(hTarget)
    hParent:CastAbilityImmediately(hAbility,hParent:GetPlayerOwnerID())
    hAbility:EndCooldown()
end