LinkLuaModifier( "day_4_modifier_1", "plugin_system/plugins/xmas12/abilities/day_4", LUA_MODIFIER_MOTION_NONE )
day_4 = class({})
function day_4:GetIntrinsicModifierName() return "day_4_modifier_1" end
day_4_modifier_1 = class({})
function day_4_modifier_1:IsHidden() return true end


function day_4_modifier_1:DeclareFunctions()
    if IsServer() then return { MODIFIER_EVENT_ON_DEATH }end
    return {}
end

function day_4_modifier_1:CheckState()
    return {
[MODIFIER_STATE_ROOTED] = true
    }
end

function day_4_modifier_1:OnDeath(event)
    if not IsServer() then return end
    if event.unit == self:GetParent() then
        self:GetParent():AddNoDraw()
        local hAbility = self:GetAbility()
        local radius = 400
        local hParent = self:GetParent()

        local fIndex = ParticleManager:CreateParticle("particles/explosion.vpcf",PATTACH_WORLDORIGIN ,nil)
        ParticleManager:SetParticleControl(fIndex,0,hParent:GetAbsOrigin())
        ParticleManager:SetParticleControl(fIndex,1,Vector(radius,0,0))
        ParticleManager:SetParticleControl(fIndex,60,Vector(255,255,255))
        ParticleManager:ReleaseParticleIndex(fIndex)
        EmitSoundOn("Item.BlackPowder",hParent)
        local vPos = hParent:GetAbsOrigin()
        local tUnits = FindUnitsInRadius(
            hParent:GetTeam(),
            vPos,
            nil,
            radius,
            DOTA_UNIT_TARGET_TEAM_BOTH,
            DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
            0,
            0,
            false
        )
        local speed = 2000
        
        local modifierKnockback =
        {
            center_x = vPos.x,
            center_y = vPos.y,
            center_z = vPos.z,
            duration = 0.5,
            knockback_duration = 0.5,
            knockback_distance = 600,
            knockback_height = 50,
        }

        for u,hUnit in pairs(tUnits) do
            if hUnit ~= nil then
                local vDif = (hUnit:GetAbsOrigin() - vPos)
                local vector = vDif:Normalized()
                hUnit:AddNewModifier(event.attacker,hAbility,"day_4_modifier_2",{
                    duration = 0.5
                })

                hUnit:AddNewModifier( hParent, hAbility, "modifier_knockback", modifierKnockback );
            end
        end
    end
end
LinkLuaModifier( "day_4_modifier_2", "plugin_system/plugins/xmas12/abilities/day_4", LUA_MODIFIER_MOTION_NONE )
day_4_modifier_2 = class({})

--------------------------------------------------------------------------------
-- Classifications
function day_4_modifier_2:IsHidden()
	return true
end

function day_4_modifier_2:IsPurgable()
	return false
end

function day_4_modifier_2:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function day_4_modifier_2:OnDestroy( kv )
	if not IsServer() then return end

    local damage = {
        attacker = self:GetCaster(),
        damage = 1000,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
        victim = self:GetParent()
    }
    ApplyDamage( damage )
end