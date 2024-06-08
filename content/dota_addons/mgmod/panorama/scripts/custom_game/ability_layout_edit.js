"use strict";
var mainHud = $.GetContextPanel().GetParent().GetParent().GetParent();
var abilitiesHud = mainHud.FindChildTraverse("AbilitiesAndStatBranch").FindChildTraverse("abilities");
var ability_slots = [];
var added_elements = [];

function update_buttons() {
    ability_slots = [];
    for (let i = 0; i < 12; i++) {
        let e = abilitiesHud.FindChildTraverse( "Ability"+i )
        if (e != undefined) {
            e = e.FindChildTraverse("ButtonWell");
            if (e != undefined) {
                $.Msg("found slot " + i);
                let hOld = e.FindChildTraverse("edit_button");
                if (hOld != undefined) {
                    hOld.DeleteAsync(0);
                }
                ability_slots.push(e);
            }
        }
    }
    added_elements = [];
    for (const key in ability_slots) {
        const hParent = ability_slots[key];
        let edit_button = $.CreatePanel('Button', $.GetContextPanel(), "edit_button");
        edit_button.SetHasClass("edit_button",true);
        edit_button.SetParent(hParent);
        added_elements.push(edit_button);
        $.Msg("added button " + key);
    }

    
    $.Schedule(1,function() {
        update_buttons();
    });
}

(function () {
    update_buttons();
})();