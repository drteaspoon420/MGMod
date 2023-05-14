day_8 = class({})


--function day_8:GetTexture() return "kumamoto" end
function day_8:IsPermanent() return false end
function day_8:RemoveOnDeath() return true end
function day_8:IsHidden() return true end
function day_8:IsDebuff() return false end
function day_8:IsPurgable() return false end
function day_8:IsPurgeException() return false end

function day_8:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
	return funcs
end

function day_8:OnCreated(kv)
    if not IsServer() then return end
    self.health = (self.health or 0) + (kv.health or 0)
    self.mana = (self.mana or 0) + (kv.mana or 0)
    self.damage = (self.damage or 0) + (kv.damage or 0)
    self:SetHasCustomTransmitterData(true)
end

function day_8:OnDestroy(kv)
    if not IsServer() then return end
    local hParent = self:GetParent()
    local iTeam = hParent:GetTeam()
    local vPos = hParent:GetAbsOrigin()

    local tMod = {
        health = (self.health or 0) + hParent:GetMaxHealth() * 0.1,
        mana = (self.mana or 0) + hParent:GetMaxMana() * 0.1,
        damage = (self.damage or 0) + hParent:GetDamageMax() * 0.1,
    }

    Timers:CreateTimer(
        0.2,
        function()
            local tUnits = FindUnitsInRadius(
                iTeam,
                vPos,
                nil,
                FIND_UNITS_EVERYWHERE,
                DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                DOTA_UNIT_TARGET_ALL,
                0,
                FIND_CLOSEST,
                false
            )
            if #tUnits > 0 then
                local i = 1
                while #tUnits > i do
                    local hUnit = tUnits[i]
                    if hUnit:IsAlive() then
                        hUnit:AddNewModifier(hUnit,nil,"day_8",tMod)
                        local fIndex = ParticleManager:CreateParticle("particles/econ/events/ti9/maelstorm_ti9.vpcf",PATTACH_WORLDORIGIN ,nil)
                        ParticleManager:SetParticleControl(fIndex,0,vPos)
                        ParticleManager:SetParticleControl(fIndex,1,hUnit:GetAbsOrigin())
                        ParticleManager:SetParticleControl(fIndex,2,Vector(1,1,1))
                        ParticleManager:ReleaseParticleIndex(fIndex)
                        break
                    end
                    i = i + 1
                end
            end
        end
    )
end

function day_8:OnRefresh(kv)
    if not IsServer() then return end
    self.health = (self.health or 0) + (kv.health or 0)
    self.mana = (self.mana or 0) + (kv.mana or 0)
    self.damage = (self.damage or 0) + (kv.damage or 0)
    self:SendBuffRefreshToClients()
    self:GetParent():CalculateGenericBonuses()
end

function day_8:AddCustomTransmitterData()
    return {
        health = self.health,
        mana = self.mana,
        damage = self.damage,
    }
end
function day_8:HandleCustomTransmitterData( data )
    self.health = data.health
    self.mana = data.mana
    self.damage = data.damage
end

function day_8:GetModifierExtraHealthBonus()
    return self.health
end
function day_8:GetModifierExtraManaBonus()
    return self.mana
end
function day_8:GetModifierPreAttack_BonusDamage()
    return self.damage
end

