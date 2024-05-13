"use strict";
var mainHud = $.GetContextPanel().GetParent().GetParent().GetParent();
var inventory_items = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("inventory");
var stash_items = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("stash");
var center_block = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("center_block");
const localplayer = Players.GetLocalPlayer();
const this_plugin_id = "smithing";
var plugin_settings;
let ilocal = -1;
let all_slots = [];


function find_slot(i) {
    return inventory_items.FindChildTraverse("inventory_slot_" + i);
}

function smithing_update(event) {
}

function loop() {
    $.Schedule(1,function() {
        loop();
    });
    update();
}

function update() {
    update_player_view();
}


function update_player_view() {
    let iUnit = Players.GetLocalPlayerPortraitUnit();
    if (Entities.IsInventoryEnabled( iUnit )) {
        for (let index = 0; index < 17; index++) {
            let iCount = 0;
            const iItem = Entities.GetItemInSlot( iUnit, index );
            if (iItem != -1) {
                const s = Abilities.GetAbilityName(iItem);
                if (s != "item_ward_dispenser") {
                    iCount = Items.GetSecondaryCharges(iItem);
                }
            }
            data(iCount,index);
        }
    } else {
        for (let index = 0; index < 17; index++) {
            let iCount = 0;
            data(iCount,index);
        }
    }
}
function init() {
    all_slots = [];
    let slot_names = [];
    slot_names[0] = "inventory_slot_0";
    slot_names[1] = "inventory_slot_1";
    slot_names[2] = "inventory_slot_2";
    slot_names[3] = "inventory_slot_3";
    slot_names[4] = "inventory_slot_4";
    slot_names[5] = "inventory_slot_5";
    slot_names[6] = "inventory_slot_6";
    slot_names[7] = "inventory_slot_7";
    slot_names[8] = "inventory_slot_8";

    slot_names[9] = "inventory_slot_0";
    slot_names[10] = "inventory_slot_1";
    slot_names[11] = "inventory_slot_2";
    slot_names[12] = "inventory_slot_3";
    slot_names[13] = "inventory_slot_4";
    slot_names[14] = "inventory_slot_5";

    slot_names[15] = "inventory_tpscroll_slot";
    slot_names[16] = "inventory_neutral_slot";
    for (let index = 0; index < 9; index++) {
        let o = inventory_items.FindChildTraverse(slot_names[index]);
        if (o) {
            all_slots[index] = add_bonus(o,index);
        }
    }

    for (let index = 9; index < 15; index++) {
        let o = stash_items.FindChildTraverse(slot_names[index]);
        if (o) {
            all_slots[index] = add_bonus(o,index);
        }
    }

    for (let index = 15; index < 17; index++) {
        let o = center_block.FindChildTraverse(slot_names[index]);
        if (o) {
            all_slots[index] = add_bonus(o,index);
        }
    }
}

function add_bonus(panel,i) {
    var bonus = $.CreatePanel('Label', $.GetContextPanel(), "smithing_slot_" + i );
    bonus.BLoadLayoutSnippet("Bonus");
    bonus.SetHasClass("SMITHMASTER",true);
    bonus.text = "";

	bonus.SetParent(panel);
    return bonus;
}
function cleanup() {
    let SMITHMASTER = mainHud.FindChildTraverse("HUDElements").FindChildrenWithClassTraverse( "SMITHMASTER" );
    for (const key in SMITHMASTER) {
        SMITHMASTER[key].DeleteAsync(0.1);
    }
}
function data(iCount,iIndex) {
    if (all_slots[iIndex] != undefined) {
        if (iCount > 0) {
           all_slots[iIndex].text = "+" + iCount;
       } else {
           all_slots[iIndex].text = "";
       }
    } else {
        $.Msg("missing slot",iIndex);
    }
}
(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_plugin_id );
    
    if (plugin_settings.enabled.VALUE == 0) {
        return;
    }

    cleanup();
    init();
    GameEvents.Subscribe( "dota_player_update_query_unit", update );
    GameEvents.Subscribe( "dota_inventory_changed", update );
    GameEvents.Subscribe( "dota_inventory_changed_query_unit", update );
    GameEvents.Subscribe( "dota_inventory_item_added", update );
    GameEvents.Subscribe( "dota_inventory_item_changed", update );
    GameEvents.Subscribe( "dota_inventory_player_got_item", update );
    GameEvents.Subscribe( "inventory_updated", update );
    GameEvents.Subscribe( "smithing_update", update );
})();