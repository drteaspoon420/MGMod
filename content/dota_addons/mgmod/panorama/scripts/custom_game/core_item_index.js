"use strict";
var core_data_items;
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var ItemIndexerMain = $.GetContextPanel().FindChildInLayoutFile("ItemIndexerMain");
var SearchBoxInput = $.GetContextPanel().FindChildInLayoutFile("SearchBoxInput");
var SlotInput = $.GetContextPanel().FindChildInLayoutFile("SlotInput");
var SearchBox = $.GetContextPanel().FindChildInLayoutFile("SearchBox");
var RecipeToggle = $.GetContextPanel().FindChildInLayoutFile("RecipeToggle");
var NormalToggle = $.GetContextPanel().FindChildInLayoutFile("NormalToggle");
var WindowPanel;
var CategoryName = "";
var ReturnUUID = "";
const local_team = Players.GetTeam(Players.GetLocalPlayer());

function CreateWindow(sCategory,tAbilities) {
    
    let sorted_keys = Object.keys(tAbilities).sort();
    for (const index in sorted_keys) {
        const sItem = tAbilities[sorted_keys[index]];
        let ItemChoise = $.CreatePanel('Button', WindowPanel, 'ItemChoise_' + sItem);
        ItemChoise.BLoadLayoutSnippet("ItemChoise");
        let ItemImage = ItemChoise.FindChildInLayoutFile("ItemImage");
        ItemImage.itemname = sItem;
        ItemChoise.ability = sItem;
        ItemChoise.AddClass("ability_choise");
        if (sItem.startsWith("item_recipe_")) {
            ItemChoise.AddClass("recipe");
        } else {
            ItemChoise.AddClass("normal");
        }
        ItemChoise.AddClass(sCategory);

        ItemChoise.SetPanelEvent(
            "onmouseover", 
            function(){
                if (GameUI.IsControlDown()) {
                    $.DispatchEvent("DOTAShowAbilityTooltip", ItemChoise, sItem);
                } else {
                    $.DispatchEvent("DOTAShowTextTooltip", ItemChoise, sItem);
                }
            }
            )
        ItemChoise.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideAbilityTooltip", ItemChoise);
            $.DispatchEvent("DOTAHideTextTooltip", ItemChoise);
            }
        )
        ItemChoise.SetPanelEvent(
            "onactivate", 
            function(){
                ApplyItem(sItem);
            }
        )
    }
}

function OnSubmitSearch() {
    let search = SearchBoxInput.text;
    let ability_choises = WindowPanel.FindChildrenWithClassTraverse( "ability_choise" );
    let bShowRecipes = RecipeToggle.checked;
    let bShowNormal = NormalToggle.checked;
    if (search == "") {
        for (const key in ability_choises) {
            let bShow = true;
            if (CategoryName != "" && !ability_choises[key].BHasClass(CategoryName) ) {
                bShow = false;
            }
            if (!bShowRecipes && ability_choises[key].BHasClass("recipe")) {
                bShow = false;
            }
            if (!bShowNormal && ability_choises[key].BHasClass("normal")) {
                bShow = false;
            }
            ability_choises[key].SetHasClass("hidden",!bShow);
        }
    } else {
        for (const key in ability_choises) {
            let bShow = true;
            if (CategoryName != "" && !ability_choises[key].BHasClass(CategoryName) ) {
                bShow = false;
            }
            if (!bShowRecipes && ability_choises[key].BHasClass("recipe")) {
                bShow = false;
            }
            if (!bShowNormal && ability_choises[key].BHasClass("normal")) {
                bShow = false;
            }
            if (!ability_choises[key].ability.includes(search)) {
                bShow = false;
            }
            ability_choises[key].SetHasClass("hidden",!bShow);
        }
    }
}

function ApplyItem(sItem) {
    GameEvents.SendCustomGameEventToServer("core_item_indexer",{
        name: sItem,
        caller: ReturnUUID
    });
    CategoryName = "";
    ReturnUUID = "";
    WindowRoot.SetHasClass("hidden",true);
}

function Cleanup() {
    ItemIndexerMain.RemoveAndDeleteChildren();
}

function core_item_indexer(tEvent) {
    CategoryName = tEvent.name;
    ReturnUUID = tEvent.caller;
    WindowRoot.SetHasClass("hidden",false);
}

function sort_children(hPanel) {
    let children = hPanel.Children();
    children.sort(
        function(a, b){
            if (a.id < b.id) {
                return -1;
            }
            if (a.id > b.id) {
                return 1;
            }
            return 0;
        });
        
    for (let i = 1; i < children.length; i++) {
        hPanel.MoveChildAfter(children[i],children[i-1]);
    }
}

(function () {
        core_data_items = CustomNetTables.GetAllTableValues( "core_data_items" );
        core_data_items.sort();
        Cleanup();
        WindowPanel = $.CreatePanel('Panel', ItemIndexerMain, 'WindowPanel');
        WindowPanel.BLoadLayoutSnippet("WindowPanel");
        RecipeToggle.SetSelected(true);
        NormalToggle.SetSelected(true);
        let bAny = false;
        for (const key in core_data_items) {
            bAny = true;
            CreateWindow(core_data_items[key].key,core_data_items[key].value);
        }
        $.Schedule(0.5,function() {
            sort_children(WindowPanel);
        });
        if (bAny) {
            GameEvents.Subscribe( "core_item_indexer", core_item_indexer );
        }
})();