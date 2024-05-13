modifier_mango_damage_stacks = modifier_mango_damage_stacks or class({})

function modifier_mango_damage_stacks:GetTexture() return "item_enchanted_mango" end -- get the icon from a different ability

function modifier_mango_damage_stacks:IsPermanent() return true end
function modifier_mango_damage_stacks:RemoveOnDeath() return false end
function modifier_mango_damage_stacks:IsHidden() return false end
function modifier_mango_damage_stacks:IsDebuff() return false end

function modifier_mango_damage_stacks:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT           -- Modifier passively remains until strictly removed. 
		+ MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE -- Allows modifier to be assigned to invulnerable entities. 
end
