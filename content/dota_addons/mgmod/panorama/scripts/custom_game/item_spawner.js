"use strict";
var item_registery;
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var ItemSpawnerRoot = $.GetContextPanel().FindChildInLayoutFile("ItemSpawnerRoot");
var SearchBoxInput = $.GetContextPanel().FindChildInLayoutFile("SearchBoxInput");
var SearchBox = $.GetContextPanel().FindChildInLayoutFile("SearchBox");
var iCount = 0;
var WindowPanel;
var isOpen = false;
const this_window_id = "item_window";

function CreateWindow(sWindow,tPurpose) {
    //Create button to open

    //Create window

    for (const index in tPurpose.item) {
        const sItem = tPurpose.item[index];
        let ItemChoise = $.CreatePanel('Button', WindowPanel, 'ItemChoise');
        ItemChoise.BLoadLayoutSnippet("ItemChoise");
        let ItemImage = ItemChoise.FindChildInLayoutFile("ItemImage");
        ItemImage.itemname = sItem;
        ItemChoise.item = sItem;
        ItemChoise.AddClass("item_choise");

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
        if (tPurpose.event == "add_basic_item") {
            ItemChoise.SetPanelEvent(
                "onactivate", 
                function(){
                    ApplyItem(sItem);
                }
            )
        }
    }
}

function OnSubmitSearch() {
    let search = SearchBoxInput.text;
    let item_choises = WindowPanel.FindChildrenWithClassTraverse( "item_choise" );
    if (search == "") {
        for (const key in item_choises) {
            item_choises[key].SetHasClass("hidden",false);
        }
    } else {
        for (const key in item_choises) {
            item_choises[key].SetHasClass("hidden",!item_choises[key].item.includes(search));
        }
    }
    

}

function GetEnt() {
    let iEnt = Players.GetLocalPlayerPortraitUnit();
/*     let iEnt = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
    let iEnts = Players.GetSelectedEntities( Players.GetLocalPlayer()  );
    if (iEnts[0]) {
        iEnt = iEnts[0];
    } */

    return iEnt;
}
function ApplyItem(sItem) {
    let iEnt = GetEnt();
    GameEvents.SendCustomGameEventToServer("add_basic_item",{
        target: iEnt,
        item: sItem,
    });
    Game.EmitSound("General.Buy");
}

function Cleanup() {
    ItemSpawnerRoot.RemoveAndDeleteChildren();
}

function item_spawner_error(event) {
    let item_choises = WindowPanel.FindChildrenWithClassTraverse( "item_choise" );
    for (const key in item_choises) {
        if (item_choises[key].item == event.item) {
            item_choises[key].DeleteAsync( 0.01 );
        }
    }
    $.Msg("invalid item " + event.item);
    $.Schedule(0.5,()=>{Game.EmitSound("General.Dead")});
    
}

(function () {
    item_registery = CustomNetTables.GetAllTableValues( "item_registery" );
    Cleanup();
    WindowPanel = $.CreatePanel('Panel', ItemSpawnerRoot, 'WindowPanel');
    WindowPanel.BLoadLayoutSnippet("WindowPanel");

    let bAny = false;
    for (const key in item_registery) {
        bAny = true;
        CreateWindow(item_registery[key].key,item_registery[key].value);
    }
    
    if (!bAny) {
        Cleanup();
        var button_bar = FindDotaHudElement("ButtonBar");
        var existing_button = button_bar.FindChildTraverse("ButtonBar_ItemSpawner");
        if (existing_button) {
            existing_button.DeleteAsync(0);
        } 
    } else {
        CreateToggleButton();
        GameEvents.Subscribe( "open_window", open_window );
        GameEvents.Subscribe( "item_spawner_error", item_spawner_error );
    }
})();

function CloseBuilder() {
    isOpen = !isOpen;
    if (isOpen) {
        GameEvents.SendEventClientSide( "open_window", {
            window_id: this_window_id
        } )
    }
    WindowRoot.SetHasClass("hidden",!isOpen);
}

function open_window(event) {
    if (event.window_id != this_window_id) {
        isOpen = false;
        WindowRoot.SetHasClass("hidden",!isOpen);
    }
}

function CreateToggleButton() {
    var button_bar = FindDotaHudElement("ButtonBar");
    var existing_button = button_bar.FindChildTraverse("ButtonBar_ItemSpawner");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "ButtonBar_ItemSpawner" );
    panel.BLoadLayoutSnippet("ButtonBar_ItemSpawner");
    panel.SetPanelEvent( 'onactivate', function () {
		CloseBuilder();
    });
    panel.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowTextTooltip", panel, "Add Items");
        }
        )
    panel.SetPanelEvent(
        "onmouseout", 
        function(){
        $.DispatchEvent("DOTAHideTextTooltip", panel);
        }
    )
	panel.SetParent(button_bar);
}

function GetDotaHud() {
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
