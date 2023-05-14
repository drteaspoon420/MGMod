day_6 = class({})


LinkLuaModifier( "day_6_thinker", "plugin_system/plugins/xmas12/modifiers/day_6", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "day_6_death", "plugin_system/plugins/xmas12/modifiers/day_6", LUA_MODIFIER_MOTION_NONE )

--function day_6:GetTexture() return "kumamoto" end
function day_6:IsPermanent() return true end
function day_6:RemoveOnDeath() return false end
function day_6:IsHidden() return true end
function day_6:IsDebuff() return false end
function day_6:IsPurgable() return false end
function day_6:IsPurgeException() return false end
function day_6:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function day_6:DeclareFunctions()
	local funcs = {
	}
	return funcs
end

function day_6:OnCreated(kv)
    if not IsServer() then return end
    self:StartIntervalThink(5)
end

function day_6:OnIntervalThink()
    if not IsServer() then return end
    local hParent = self:GetParent()
    local vPos = hParent:GetAbsOrigin()
    CreateModifierThinker(hParent,nil,"day_6_thinker",{duration = 5},vPos,hParent:GetTeam(),false)
end

day_6_thinker = class({})


--function day_6_thinker:GetTexture() return "kumamoto" end
function day_6_thinker:IsHidden() return true end


function day_6_thinker:OnCreated(kv)
    if not IsServer() then return end
    local hParent = self:GetParent()
    local fIndex = ParticleManager:CreateParticle("particles/run_run.vpcf",PATTACH_WORLDORIGIN ,nil)
    local radius = 400
    ParticleManager:SetParticleControl(fIndex,0,hParent:GetAbsOrigin())
    ParticleManager:SetParticleControl(fIndex,1,Vector(radius,0,0))
    self:AddParticle(fIndex,true,false,1,false,false)

end

function day_6_thinker:OnDestroy( kv )
	if not IsServer() then return end

    local radius = 400
    local hParent = self:GetParent()
    local hCaster = self:GetCaster()

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
            hUnit:AddNewModifier(hCaster,nil,"day_6_death",{
                duration = 0.5
            })
            hUnit:AddNewModifier( hCaster, nil, "modifier_knockback", modifierKnockback );
        end
    end
end


day_6_death = class({})

function day_6_death:IsHidden()
	return true
end

function day_6_death:IsPurgable()
	return false
end

function day_6_death:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function day_6_death:OnDestroy( kv )
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