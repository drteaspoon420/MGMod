"use strict";
var modifier_registery;
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var ModifierSpawnerRoot = $.GetContextPanel().FindChildInLayoutFile("ModifierSpawnerRoot");
var SearchBoxInput = $.GetContextPanel().FindChildInLayoutFile("SearchBoxInput");
var ModifierDataInput = $.GetContextPanel().FindChildInLayoutFile("ModifierDataInput");
var SearchBox = $.GetContextPanel().FindChildInLayoutFile("SearchBox");
var iCount = 0;
var WindowPanel;
var isOpen = false;
const this_window_id = "modifier_window";

function CreateWindow(sWindow,tPurpose) {
    //Create button to open

    //Create window

    for (const index in tPurpose.modifier) {
        const sModifier = tPurpose.modifier[index];
        let ModifierChoise = $.CreatePanel('Button', WindowPanel, 'ModifierChoise');
        ModifierChoise.BLoadLayoutSnippet("ModifierChoise");
        let ModifierImage = ModifierChoise.FindChildInLayoutFile("ModifierImage");
        ModifierImage.abilityname = sModifier;
        ModifierChoise.modifier = sModifier;
        ModifierChoise.AddClass("modifier_choise");
        let localized = $.Localize("#DOTA_Tooltip_" + sModifier);
        let localized_desc = $.Localize("#DOTA_Tooltip_" + sModifier + "_Description");
        ModifierChoise.SetPanelEvent(
            "onmouseover", 
            function(){
                if (GameUI.IsControlDown()) {
                    $.DispatchEvent("DOTAShowTitleTextTooltip", ModifierChoise, localized,localized_desc);
                } else {
                    $.DispatchEvent("DOTAShowTextTooltip", ModifierChoise, sModifier);
                }
            }
            )
        ModifierChoise.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip", ModifierChoise);
                $.DispatchEvent("DOTAHideTitleTextTooltip", ModifierChoise);
            }
        )
        if (tPurpose.event == "add_basic_modifier") {
            ModifierChoise.SetPanelEvent(
                "onactivate", 
                function(){
                    ApplyModifier(sModifier);
                }
            )
        }
    }
}

function OnSubmitSearch() {
    let search = SearchBoxInput.text;
    let modifier_choises = WindowPanel.FindChildrenWithClassTraverse( "modifier_choise" );
    if (search == "") {
        for (const key in modifier_choises) {
            modifier_choises[key].SetHasClass("hidden",false);
        }
    } else {
        for (const key in modifier_choises) {
            modifier_choises[key].SetHasClass("hidden",!modifier_choises[key].modifier.includes(search));
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
function ApplyModifier(sModifier) {
    let iEnt = GetEnt();
    let sData = ModifierDataInput.text;
    GameEvents.SendCustomGameEventToServer("add_basic_modifier",{
        target: iEnt,
        modifier: sModifier,
        data: sData,
    });
    Game.EmitSound("General.Buy");
}

function Cleanup() {
    ModifierSpawnerRoot.RemoveAndDeleteChildren();
}

function modifier_spawner_error(event) {
    let modifier_choises = WindowPanel.FindChildrenWithClassTraverse( "modifier_choise" );
    for (const key in modifier_choises) {
        if (modifier_choises[key].modifier == event.modifier) {
            modifier_choises[key].DeleteAsync( 0.01 );
        }
    }
    $.Msg("invalid modifier " + event.modifier);
    $.Schedule(0.5,()=>{Game.EmitSound("General.Dead")});
    
}

(function () {
    modifier_registery = CustomNetTables.GetAllTableValues( "modifier_registery" );
    Cleanup();
    WindowPanel = $.CreatePanel('Panel', ModifierSpawnerRoot, 'WindowPanel');
    WindowPanel.BLoadLayoutSnippet("WindowPanel");
    let bAny = false;
    for (const key in modifier_registery) {
        bAny = true;
        CreateWindow(modifier_registery[key].key,modifier_registery[key].value);
    }
    
    if (!bAny) {
        Cleanup();
        var button_bar = FindDotaHudElement("ButtonBar");
        var existing_button = button_bar.FindChildTraverse("ButtonBar_ModifierSpawner");
        if (existing_button) {
            existing_button.DeleteAsync(0);
        } 
    } else {
        CreateToggleButton();
        GameEvents.Subscribe( "open_window", open_window );
        GameEvents.Subscribe( "modifier_spawner_error", modifier_spawner_error );
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
    var existing_button = button_bar.FindChildTraverse("ButtonBar_ModifierSpawner");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "ButtonBar_ModifierSpawner" );
    panel.BLoadLayoutSnippet("ButtonBar_ModifierSpawner");
    panel.SetPanelEvent( 'onactivate', function () {
		CloseBuilder();
    });
    panel.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowTextTooltip", panel, "Add Modifiers");
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
