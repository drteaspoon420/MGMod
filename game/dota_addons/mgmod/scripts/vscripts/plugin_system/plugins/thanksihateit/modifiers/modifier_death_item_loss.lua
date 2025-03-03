modifier_death_item_loss = class({})


function modifier_death_item_loss:GetTexture() return "kumamoto" end
function modifier_death_item_loss:IsPermanent() return true end
function modifier_death_item_loss:RemoveOnDeath() return false end
function modifier_death_item_loss:IsHidden() return true end
function modifier_death_item_loss:IsDebuff() return false end
function modifier_death_item_loss:IsPurgable() return false end
function modifier_death_item_loss:IsPurgeException() return false end
function modifier_death_item_loss:GetAttributes()
	return  MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_death_item_loss:DeclareFunctions()
	local funcs = {
        MODIFIER_EVENT_ON_DEATH
	}
	return funcs
end

function modifier_death_item_loss:OnCreated(kv)
    if not IsServer() then return end
    --print("added item dropping")
end

function modifier_death_item_loss:OnDeath(kv)
	if not IsServer() then return end
    if kv.unit ~= self:GetParent() then return end
    local hParent = self:GetParent()
	if hParent:WillReincarnate() or hParent:IsReincarnating() then return end
    local tItems = {}
    for i=DOTA_ITEM_SLOT_1,DOTA_ITEM_SLOT_9 do
        local hItem = hParent:GetItemInSlot(i)
        if hItem ~= nil then
            table.insert(tItems,hItem)
        end
    end
    --print("item droping",#tItems)
    if #tItems > 0 then
        local n = Toolbox:GetRandomKey(tItems)
        local hDropItem = tItems[n]
        
        hParent:DropItemAtPositionImmediate(hDropItem,hParent:GetAbsOrigin())
        hDropItem:SetPurchaser(nil)
    end
end
