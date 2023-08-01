"use strict";
var unit_registery;
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var UnitSpawnerRoot = $.GetContextPanel().FindChildInLayoutFile("UnitSpawnerRoot");
var SearchBoxInput = $.GetContextPanel().FindChildInLayoutFile("SearchBoxInput");
var SearchBox = $.GetContextPanel().FindChildInLayoutFile("SearchBox");
var iCount = 0;
var WindowPanel;
var isOpen = false;
const this_window_id = "unit_window";

function CreateWindow(sWindow,tPurpose) {
    //Create button to open

    //Create window

    for (const index in tPurpose.unit) {
        const sUnit = tPurpose.unit[index];
        let UnitChoise = $.CreatePanel('Button', WindowPanel, 'UnitChoise');
        UnitChoise.BLoadLayoutSnippet("UnitChoise");
        let UnitImage = UnitChoise.FindChildInLayoutFile("UnitImage");
        UnitImage.heroname = sUnit;
        UnitChoise.unit = sUnit;
        UnitChoise.AddClass("unit_choise");

        UnitChoise.SetPanelEvent(
            "onmouseover", 
            function(){
                if (GameUI.IsControlDown()) {
                    $.DispatchEvent("DOTAShowTextTooltip", UnitChoise, $.Localize("#" + sUnit));
                } else {
                    $.DispatchEvent("DOTAShowTextTooltip", UnitChoise, sUnit);
                }
            }
            )
        UnitChoise.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTextTooltip", UnitChoise);
            }
        )
        if (tPurpose.event == "add_basic_unit") {
            UnitChoise.SetPanelEvent(
                "onactivate", 
                function(){
                    ApplyUnit(sUnit);
                }
            )
        }
    }
}

function OnSubmitSearch() {
    let search = SearchBoxInput.text;
    let unit_choises = WindowPanel.FindChildrenWithClassTraverse( "unit_choise" );
    if (search == "") {
        for (const key in unit_choises) {
            unit_choises[key].SetHasClass("hidden",false);
        }
    } else {
        for (const key in unit_choises) {
            unit_choises[key].SetHasClass("hidden",!unit_choises[key].unit.includes(search));
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
function ApplyUnit(sUnit) {
    let iEnt = GetEnt();
    GameEvents.SendCustomGameEventToServer("add_basic_unit",{
        target: iEnt,
        unit: sUnit,
    });
    Game.EmitSound("General.Buy");
}

function Cleanup() {
    UnitSpawnerRoot.RemoveAndDeleteChildren();
}

function unit_spawner_error(event) {
    let unit_choises = WindowPanel.FindChildrenWithClassTraverse( "unit_choise" );
    for (const key in unit_choises) {
        if (unit_choises[key].unit == event.unit) {
            unit_choises[key].DeleteAsync( 0.01 );
        }
    }
    $.Msg("invalid unit " + event.unit);
    $.Schedule(0.5,()=>{Game.EmitSound("General.Dead")});
    
}

(function () {
    unit_registery = CustomNetTables.GetAllTableValues( "unit_registery" );
    Cleanup();
    WindowPanel = $.CreatePanel('Panel', UnitSpawnerRoot, 'WindowPanel');
    WindowPanel.BLoadLayoutSnippet("WindowPanel");

    let bAny = false;
    for (const key in unit_registery) {
        bAny = true;
        CreateWindow(unit_registery[key].key,unit_registery[key].value);
    }
    
    if (!bAny) {
        Cleanup();
        var button_bar = FindDotaHudElement("ButtonBar");
        var existing_button = button_bar.FindChildTraverse("ButtonBar_UnitSpawner");
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
    var existing_button = button_bar.FindChildTraverse("ButtonBar_UnitSpawner");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "ButtonBar_UnitSpawner" );
    panel.BLoadLayoutSnippet("ButtonBar_UnitSpawner");
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
