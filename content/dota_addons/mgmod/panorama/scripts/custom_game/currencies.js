"use strict";
var plugin_settings = {};
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
const this_window_id = "currencies";


(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );
    if (plugin_settings.enabled.VALUE == 0) {
        WindowRoot.SetHasClass("hidden",!isOpen);
    } else {
        var sSettings = CustomNetTables.GetAllTableValues( "currencies" );
        GameEvents.Subscribe( "open_window", open_window );
        CustomNetTables.SubscribeNetTableListener( "currencies" , SettingsUpdate );
    }
})();