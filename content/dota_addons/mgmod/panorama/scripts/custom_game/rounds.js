"use strict";
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var RoundText = $.GetContextPanel().FindChildInLayoutFile("RoundText");
var TimerText = $.GetContextPanel().FindChildInLayoutFile("TimerText");
var plugin_settings;
var round_data;
const this_window_id = "rounds";

function UpdateUI(tableName,tableSection,tEvent) {
    if (tableSection == "round_data") {
        round_data = tEvent;
        UpdateUI_Parsed();
    }
}

function UpdateUI_Parsed() {
    RoundText.text = round_data.current_round + "/" + round_data.max_rounds;
    TimeUpdate();
}

function TimeUpdate() {
    if (round_data.current_state !== 2) {
        TimerText.text = "--";
        return;
    }
    $.Schedule(1,function() {
        TimeUpdate();
    });
    let time = (round_data.round_end_time - Game.GetGameTime());
    let seconds = time.toFixed(0);
    TimerText.text = seconds;
}

(function () {
    
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );
    if (plugin_settings.enabled.VALUE == 1) {
        WindowRoot.SetHasClass("hidden",false);
        round_data = CustomNetTables.GetTableValue( "rounds", "round_data" );
        UpdateUI_Parsed();
        CustomNetTables.SubscribeNetTableListener( "rounds" , UpdateUI );
    }
})();