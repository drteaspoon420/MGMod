modifier_mango_check = modifier_mango_check or class({})

function modifier_mango_check:GetTexture() return "item_enchanted_mango" end

function modifier_mango_check:IsPermanent() return true end
function modifier_mango_check:RemoveOnDeath() return false end
function modifier_mango_check:IsHidden() return false end
function modifier_mango_check:IsDebuff() return false end

function modifier_mango_check:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_mango_check:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_EXECUTED
	}
	return funcs
end


function modifier_mango_check:OnAbilityExecuted(event)
	if event.unit and event.ability then
		local name = event.ability:GetName()
		if name == "item_enchanted_mango" then 
			MangoPartyPlugin:ApplyMangoDamage(event.unit, event.ability)
			return
		end
		if MangoPartyPlugin.settings.lotus then
			if name == "item_famango" then
				MangoPartyPlugin:ApplyMangoDamage(event.unit, event.ability)
				return
			end
			if name == "item_great_famango" then 
				MangoPartyPlugin:ApplyMangoDamage(event.unit, event.ability)
				return
			end
			if name == "item_greater_famango" then 
				MangoPartyPlugin:ApplyMangoDamage(event.unit, event.ability)
				return
			end
		end
	end
end