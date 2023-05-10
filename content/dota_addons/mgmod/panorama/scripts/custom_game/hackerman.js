"use strict";
var unit_registery;
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var HackermanRoot = $.GetContextPanel().FindChildInLayoutFile("HackermanRoot");
var HackerInput = $.GetContextPanel().FindChildInLayoutFile("HackerInput");
var SearchBox = $.GetContextPanel().FindChildInLayoutFile("SearchBox");
var iCount = 0;
var WindowPanel;
var Row;
var isOpen = false;
const in_row = 20;
const this_window_id = "hackerman";

function CreateWindow(sWindow,tPurpose) {
    //Create button to open

    //Create window

}

function OnSubmitHack() {
    let search = HackerInput.text;

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
function ApplyUnit(sUnit) {
    let iEnt = GetEnt();
    GameEvents.SendCustomGameEventToServer("add_basic_unit",{
        target: iEnt,
        unit: sUnit,
    });
    Game.EmitSound("General.Buy");
}

function Cleanup() {
    HackermanRoot.RemoveAndDeleteChildren();
}


(function () {
    Cleanup();
    WindowPanel = $.CreatePanel('Panel', HackermanRoot, 'WindowPanel');
    WindowPanel.BLoadLayoutSnippet("WindowPanel");
    Row = $.CreatePanel('Panel', WindowPanel, 'Row');
    Row.BLoadLayoutSnippet("Row");

    let bAny = true;
    if (!bAny) {
        Cleanup();
        var button_bar = FindDotaHudElement("ButtonBar");
        var existing_button = button_bar.FindChildTraverse("ButtonBar_Hackerman");
        if (existing_button) {
            existing_button.DeleteAsync(0);
        } 
    } else {
        CreateToggleButton();
        GameEvents.Subscribe( "open_window", open_window );
        GameEvents.Subscribe( "unit_spawner_error", unit_spawner_error );
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
    var existing_button = button_bar.FindChildTraverse("ButtonBar_Hackerman");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "ButtonBar_Hackerman" );
    panel.BLoadLayoutSnippet("ButtonBar_Hackerman");
    panel.SetPanelEvent( 'onactivate', function () {
		CloseBuilder();
    });
    panel.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowTextTooltip", panel, "Add Units");
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
