
item_cr_blink = class({})


function item_cr_blink:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    local vPoint = self:GetCursorPosition()
    local vOrigin = hCaster:GetAbsOrigin()
    local nMaxBlink = self:GetSpecialValueFor("blink_range")
    local nClamp = self:GetSpecialValueFor("blink_range_clamp")
    self:Blink(hCaster, vPoint, nMaxBlink, nClamp)
end

function item_cr_blink:Blink(hTarget, vPoint, nMaxBlink, nClamp)
    local vOrigin = hTarget:GetAbsOrigin()
    ProjectileManager:ProjectileDodge(hTarget)
    ParticleManager:CreateParticle("particles/econ/events/fall_2022/blink/blink_dagger_fall_2022_start.vpcf", PATTACH_ABSORIGIN, hTarget)
    hTarget:EmitSound("DOTA_Item.BlinkDagger.Activate")
    local vDiff = vPoint - vOrigin
    if vDiff:Length2D() > nMaxBlink then
        vPoint = vOrigin + (vPoint - vOrigin):Normalized() * nClamp
        self:StartCooldown(self:GetCooldownTime()*20)
    end
    hTarget:SetAbsOrigin(vPoint)
    FindClearSpaceForUnit(hTarget, vPoint, false)
    ParticleManager:CreateParticle("particles/econ/events/fall_2022/blink/blink_dagger_end_fall2022.vpcf", PATTACH_ABSORIGIN, hTarget)
end