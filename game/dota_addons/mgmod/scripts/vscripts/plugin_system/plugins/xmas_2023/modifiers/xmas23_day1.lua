xmas23_day1 = class({})

xmas23_day1.item_bans = {
    item_rapier = 1,
    item_aegis = 1,
}
--function xmas23_day1:GetTexture() return "kumamoto" end
function xmas23_day1:IsPermanent() return true end
function xmas23_day1:RemoveOnDeath() return false end
function xmas23_day1:IsHidden() return true end
function xmas23_day1:IsDebuff() return false end
function xmas23_day1:IsPurgable() return false end
function xmas23_day1:IsPurgeException() return false end
function xmas23_day1:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function xmas23_day1:DeclareFunctions()
	local funcs = {
	}
	return funcs
end

function xmas23_day1:OnCreated(kv)
    if not IsServer() then return end
    self:StartIntervalThink(3.14159265359)
end



function xmas23_day1:OnIntervalThink()
    if not IsServer() then return end
    local hUnit = self:GetParent()
    if hUnit ~= nil and hUnit:HasInventory() then
        for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_TRANSIENT_CAST_ITEM do
            local item = hUnit:GetItemInSlot(i)
            if item ~= nil then
                sItem = item:GetAbilityName()
                if (xmas23_day1.item_bans[sItem] == nil) then
                    item:OnEquip()
                end
            end
        end
    end
end
