drteaspoon_black_king_bar = class({})
function drteaspoon_black_king_bar:OnSpellStart()
    self:GetCaster():AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_drteaspoon_black_king_bar",
        {
            duration = self:GetSpecialValueFor("duration")
        }
    )
    
    EmitSoundOn("DOTA_Item.BlackKingBar.Activate", self:GetCaster())
    
end
LinkLuaModifier("modifier_drteaspoon_black_king_bar","abilities/drteaspoon/black_king_bar/ability",LUA_MODIFIER_MOTION_NONE)
modifier_drteaspoon_black_king_bar = class({})
function modifier_drteaspoon_black_king_bar:IsPermanent() return false end
function modifier_drteaspoon_black_king_bar:RemoveOnDeath() return true end
function modifier_drteaspoon_black_king_bar:IsHidden() return false end
function modifier_drteaspoon_black_king_bar:IsDebuff() return false end
function modifier_drteaspoon_black_king_bar:DestroyOnExpire() return true end
function modifier_drteaspoon_black_king_bar:GetAttributes()
	return  MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_drteaspoon_black_king_bar:OnCreated()
    if not IsServer() then return end
    if not self.buff_fx then
        self.buff_fx = ParticleManager:CreateParticle("particles/drteaspoon_bkb.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(self.buff_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
        self:AddParticle(self.buff_fx, false, false, -1, false, false)
    end
end

function modifier_drteaspoon_black_king_bar:CheckState()
	local state = {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
	return state
end