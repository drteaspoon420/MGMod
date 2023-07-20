"use strict";
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var isOpen = false;
const this_window_id = "souls_plugin";
var plugin_settings;



function SoulsUpdate( table_name, team, table) {
    var team_score = WindowRoot.FindChildTraverse(team);
    if (team_score) {
        team_score.text = table.earned;
    }

    
}

(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );
    if (plugin_settings.enabled.VALUE == 0) {
        WindowRoot.SetHasClass("hidden",true);
        var button_bar = FindDotaHudElement("ButtonBar");
        var existing_button = button_bar.FindChildTraverse("ButtonBar_Bsrpg");
        if (existing_button) {
            existing_button.DeleteAsync(0);
        } 
    } else {
        WindowRoot.SetHasClass("hidden",false);
        CustomNetTables.SubscribeNetTableListener( "souls_collected" , SoulsUpdate );
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
    var existing_button = button_bar.FindChildTraverse("ButtonBar_SoulCollector");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "ButtonBar_SoulCollector" );
    panel.BLoadLayoutSnippet("ButtonBar_SoulCollector");
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
