
fish_master_curse = class({})

function fish_master_curse:OnSpellStart()
    if not IsServer() then return end
end

LinkLuaModifier( "modifier_fish_master_curse", "plugin_system/plugins/halloween/abilities/fish_master_curse", LUA_MODIFIER_MOTION_NONE )


modifier_fish_master_curse = class({})
function modifier_fish_master_curse:IsHidden() return false end


function modifier_fish_master_curse:OnCreated( kv )
	if IsServer() then
		local hParent = self:GetParent()
        self.follow_target
		if hParent then 
	        local nFXIndex = ParticleManager:CreateParticle( "particles/items5_fx/repair_kit.vpcf", PATTACH_ABSORIGIN_FOLLOW, hParent );
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hParent, PATTACH_POINT_FOLLOW, "attach_hitloc", hParent:GetOrigin(), true )
			ParticleManager:SetParticleControlEnt( nFXIndex, 1, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, hParent:GetOrigin(), true  )
			EmitSoundOn( "DOTA_Item.RepairKit.Target", hParent )
	        self:AddParticle( nFXIndex, false, false, -1, false, false )
			self.m_nFXIndex = nFXIndex
			self:StartIntervalThink( 1 )
		end
	end
end

function modifier_fish_master_curse:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle( self.m_nFXIndex, false )

		if self.nFXTimer ~= nil then
			ParticleManager:DestroyParticle( self.nFXTimer, true )
		end
	end
end


function modifier_fish_master_curse:OnIntervalThink()
	if IsServer() then
        --order following the conga target
	end
end

function modifier_fish_master_curse:IsPurgable()
	return false
end
