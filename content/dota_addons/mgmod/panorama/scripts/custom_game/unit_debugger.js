"use strict";
var DataContent = $.GetContextPanel().FindChildInLayoutFile("debug_content");

function DebugData(table,tableKey,data) {
    if (tableKey == "unit_debug") {
        DataContent.RemoveAndDeleteChildren();
        DebugUnit(data,DataContent);
    }
}

function DebugUnit(data,root) {
    for (const key in data) {
        const element = data[key];
        if (typeof(element) != "object") {
            CreateKeyPanel(root,key,element)
        } else {
            CreateKeyPanel(root,key,">>")
            const drop = CreateDrop(root,key);
            DebugUnit(element,drop);
        }
    }
}

function CreateKeyPanel(parent,key,value) {
    var panel = $.CreatePanel('Panel', parent, key );
    panel.BLoadLayoutSnippet("UnitDebuggerData");
    var text_panel = panel.FindChildTraverse("UnitDebuggerDataLabelKey");
    text_panel.text = key;
    var value_panel = panel.FindChildTraverse("UnitDebuggerDataLabelValue");
    value_panel.text = value;
}

function CreateDrop(parent,key) {
    var panel = $.CreatePanel('Panel', parent, key );
    panel.BLoadLayoutSnippet("UnitDebuggerDataDrop");
    return panel;
}

function Debug() {
    let iEnt = Players.GetLocalPlayerPortraitUnit();
    GameEvents.SendCustomGameEventToServer("debug_unit",{
        target: iEnt
    });
    Game.EmitSound("General.Buy");
}

(function () {
    CustomNetTables.SubscribeNetTableListener( "debug_data" , DebugData );
    $.Msg("debugger loaded");
})();