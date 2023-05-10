drteaspoon_blink = class({})
function drteaspoon_blink:OnSpellStart()
	local hCaster = self:GetCaster()
	local vPoint = self:GetCursorPosition()
	local vOrigin = hCaster:GetAbsOrigin()
	local nMaxBlink = self:GetSpecialValueFor( "distance" )
    self:Blink(hCaster,vPoint,nMaxBlink,nMaxBlink)
end

function drteaspoon_blink:Blink(hTarget, vPoint, nMaxBlink, nClamp)
	local vOrigin = hTarget:GetAbsOrigin()
	ProjectileManager:ProjectileDodge(hTarget)
	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, hTarget)
	hTarget:EmitSound("DOTA_Item.BlinkDagger.Activate")
	local vDiff = vPoint - vOrigin
	if vDiff:Length2D() > nMaxBlink then
		vPoint = vOrigin + (vPoint - vOrigin):Normalized() * nClamp
	end
	hTarget:SetAbsOrigin(vPoint)
	FindClearSpaceForUnit(hTarget, vPoint, false)
	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, hTarget)
end