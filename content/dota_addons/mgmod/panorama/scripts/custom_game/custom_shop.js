
function Cleanup() {
    let custom_shop_grid = FindDotaHudElement("GridCustomShopItems");
    custom_shop_grid.RemoveAndDeleteChildren();
}
(function () {
    Cleanup();
    let custom_shop_tittle = FindDotaHudElement("CustomShopTitle");
    custom_shop_tittle.text = "MG Mod Shop";
    let custom_shop_grid = FindDotaHudElement("GridCustomShopItems");

    let custom_shop_row = $.CreatePanel('Panel', $.GetContextPanel(), "ShopItems_customshop" );
	custom_shop_row.SetParent(custom_shop_grid);
    custom_shop_row.SetHasClass("ShopItemRowContainer",true);
    custom_shop_row.SetHasClass("LeftRow",true);
    let custom_shop_label = $.CreatePanel('Label', custom_shop_row, "ShopItemsHeader" );
    custom_shop_label.text = "Chaos Reign"

    let custom_shop_container = $.CreatePanel('Panel', custom_shop_row, "ShopItemsContainer" );

    let item_block = $.CreatePanel('DOTAShopItem', custom_shop_container, "test_item_block" );
    let image = item_block.FindChildTraverse("ItemImage")
    image.itemname = "item_ruthless_dagger";

    let item_block2 = $.CreatePanel('DOTAShopItem', custom_shop_container, "test_item_block2" );
    let image2 = item_block2.FindChildTraverse("ItemImage")
    image2.itemname = "item_ruthless_dagger";

    let item_block3 = $.CreatePanel('DOTAShopItem', custom_shop_container, "test_item_block3" );
    let image3 = item_block3.FindChildTraverse("ItemImage")
    image3.itemname = "item_ruthless_dagger";

    let item_block4 = $.CreatePanel('DOTAShopItem', custom_shop_container, "test_item_block4" );
    let image4 = item_block4.FindChildTraverse("ItemImage")
    image4.itemname = "item_ruthless_dagger";


    
})();


function GetDotaHud() {
    $.Msg("lol!");
    var panel = $.GetContextPanel();
    while (panel && panel.id !== 'Hud') {
        panel = panel.GetParent();
	}

    if (!panel) {
        throw new Error('Could not find Hud root from panel with id: ' + $.GetContextPanel().id);
	}
	return panel;
}
function FindDotaHudElement(id) {
	return GetDotaHud().FindChildTraverse(id);
}
