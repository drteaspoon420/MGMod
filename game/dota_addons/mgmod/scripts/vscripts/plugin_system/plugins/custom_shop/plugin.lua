CustomShopsPlugin = class({})
_G.CustomShopsPlugin = CustomShopsPlugin
CustomShopsPlugin.settings = {
}
ItemSpawnerPlugin.npc_items = {}
ItemSpawnerPlugin.npc_items_custom = {}

CustomShopsPlugin.shops = {}

function CustomShopsPlugin:Init()
    print("[CustomShopsPlugin] found")
end

function CustomShopsPlugin:ApplySettings()
    CustomShopsPlugin.settings = PluginSystem:GetAllSetting("custom_items")
	local file = LoadKeyValues('scripts/npc/items.txt')
    if not (file == nil or not next(file)) then
        CustomShopsPlugin.npc_items = file
    end
	local file_custom = LoadKeyValues('scripts/npc/npc_items_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        CustomShopsPlugin.npc_items_custom = file_custom
    end
    for k,v in pairs(CustomShopsPlugin.npc_items) do
        if v ~= nil and type(v) == 'table' then
            CustomShopsPlugin:AddItem(k,v)
        end 
    end
    for k,v in pairs(CustomShopsPlugin.npc_items_custom) do
        if v ~= nil and type(v) == 'table' then
            if CustomShopsPlugin.npc_items[k] == nil then
                CustomShopsPlugin:AddItem(k,v)
            end
        end 
    end
    CustomShopsPlugin:UpdateLists()
end


function CustomShopsPlugin:AddItem(sItem,tItemData)

    if tItemData.ItemPurchasable ~= nil and tItemData.ItemPurchasable == 0 then
        if tItemData.CustomShopPurchasable == nil or tItemData.CustomShopPurchasable == 0 then
            return
        end
    end
    local sList = "uncategorized"
    if tItemData.ItemRecipe ~= nil and tItemData.ItemRecipe == 1 then return end
    if tItemData.ItemCost == nil then return end
    if tItemData.ItemQuality ~= nil then sList = tItemData.ItemQuality end
    if CustomShopsPlugin.shops[sList] == nil then CustomShopsPlugin.shops[sList] = {} end
    CustomShopsPlugin.shops[sList][sItem] = {
        ItemName = sItem,
        ItemCost = tItemData.ItemCost
    }
end

function CustomShopsPlugin:UpdateLists()
    for k,v in pairs(CustomShopsPlugin.shops) do
        print(k)
        DeepPrintTable(v)
        CustomNetTables:SetTableValue("custom_shops", k, v)
    end
end

function CustomShopsPlugin:CustomBuy(sItem)
    local s = Toolbox:split(sItem,"_")
    local sRecipeName = "item_recipe"
    for i=2,#s do
        sRecipeName = sRecipeName .. "_" .. s[i]
    end
    local tItemRecipeData = GetAbilityKeyValuesByName(sRecipeName)
    if tItemRecipeData ~= nil then
        print("item has recipe")
        DeepPrintTable(tItemRecipeData)
    else
        CustomShopsPlugin:TryBuy(sItem)
    end
end