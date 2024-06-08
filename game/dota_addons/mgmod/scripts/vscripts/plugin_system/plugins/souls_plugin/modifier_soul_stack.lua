modifier_soul_stack = modifier_soul_stack or class({})
function modifier_soul_stack:IsPermanent() return true end
function modifier_soul_stack:RemoveOnDeath() return false end
function modifier_soul_stack:GetTexture() return "soul_stack" end
function modifier_soul_stack:IsHidden() return false end
function modifier_soul_stack:IsDebuff() return false end
function modifier_soul_stack:IsPurgeException() return false end
function modifier_soul_stack:AllowIllusionDuplicate() return false end
function modifier_soul_stack:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_soul_stack:OnCreated(kv)
	if not IsServer() then return end
	self:SetStackCount(kv.stack)
	self:StartIntervalThink(1.0)
	self:GetParent():EmitSound("Item.PickUpGemWorld")
end

function modifier_soul_stack:OnRefresh(kv)
	if not IsServer() then return end
	self:SetStackCount(self:GetStackCount() + kv.stack)
	self:GetParent():EmitSound("Item.PickUpGemWorld")
end

function modifier_soul_stack:OnIntervalThink()
	if not IsServer() then return end
	if self:GetParent():IsInRangeOfShop(DOTA_SHOP_HOME,true) or self:GetParent():IsInRangeOfShop(DOTA_SHOP_SECRET,true) then
		SoulsPlugin:EarnSouls(self:GetParent(),self:GetStackCount())
		self:Destroy()
	end
end