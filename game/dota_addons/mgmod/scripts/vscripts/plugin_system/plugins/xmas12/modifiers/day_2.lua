day_2 = class({})


--function day_2:GetTexture() return "kumamoto" end
function day_2:IsPermanent() return true end
function day_2:RemoveOnDeath() return false end
function day_2:IsHidden() return true end
function day_2:IsDebuff() return false end
function day_2:IsPurgable() return false end
function day_2:IsPurgeException() return false end
function day_2:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function day_2:DeclareFunctions()
	local funcs = {
        MODIFIER_EVENT_ON_SPENT_MANA
	}
	return funcs
end

function day_2:OnSpentMana(kv)
	if IsServer() then
		if kv.unit == self:GetParent() then
            local iGold = self:GetParent():GetGold()
            if iGold < kv.cost then
                local damage = {
                    attacker = self:GetParent(),
                    damage = kv.cost,
                    damage_type = DAMAGE_TYPE_PURE,
                    ability = kv.ability,
                    victim = self:GetParent()
                }
                if kv.ability:GetAbilityName() ~= "storm_spirit_ball_lightning" then
                    self:GetParent():GiveMana(kv.cost)
                end
                local fDamage = ApplyDamage( damage )
                self:GetParent():SpendGold(iGold,DOTA_ModifyGold_AbilityGold)
            else
                self:GetParent():SpendGold(kv.cost,DOTA_ModifyGold_AbilityGold)
                self:GetParent():GiveMana(kv.cost)
            end
        end
	end
end