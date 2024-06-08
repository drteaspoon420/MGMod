modifier_soul_droplet = modifier_soul_droplet or class({})
function modifier_soul_droplet:IsPermanent() return true end
function modifier_soul_droplet:RemoveOnDeath() return false end
function modifier_soul_droplet:IsHidden() return true end
function modifier_soul_droplet:IsDebuff() return false end
function modifier_soul_droplet:IsPurgeException() return false end
function modifier_soul_droplet:AllowIllusionDuplicate() return true end
function modifier_soul_droplet:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_soul_droplet:OnCreated(kv)
	if not IsServer() then return end
	self:SetStackCount(kv.stack)
	self:StartIntervalThink(0.4)
	self.time = 60/0.4

	--PARTICLE TIME!
	local iFxIndex = ParticleManager:CreateParticle("particles/souls/ward_skull_rubick.vpcf",PATTACH_ABSORIGIN,self:GetParent())
	ParticleManager:SetParticleControl(iFxIndex,0,self:GetParent():GetAbsOrigin() + Vector(0,0,50))
	self:AddParticle(iFxIndex,false,false,1,false,false)
end

function modifier_soul_droplet:OnIntervalThink()
	if not IsServer() then return end
	local tHeroes = FindUnitsInRadius(
		DOTA_TEAM_NEUTRALS,
		self:GetParent():GetAbsOrigin(),
		nil,
		100,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)
	if #tHeroes > 0 then
		for i=1,#tHeroes do
			local hHero = tHeroes[i]
			if hHero:IsRealHero() and not hHero:IsClone() then
				local hModifier = hHero:AddNewModifier(hHero,nil,"modifier_soul_stack",{stack = self:GetStackCount()})
				self:Destroy()
				UTIL_Remove(self:GetParent())
				return
			end
		end
	else
		if self.time == 0 then
			self:Destroy()
			UTIL_Remove(self:GetParent())
		else
			self.time = self.time - 1
		end
	end
end