"use strict";

let ab = "";
let kv = "";
function UpgradeReportCancel() {
    $.GetContextPanel().DeleteAsync(0);
}

function UpgradeReportSend() {
    let reason_v = $.GetContextPanel().FindChildInLayoutFile("UpgradeReportReason");
    let reason = Number(reason_v.GetSelected().id);

    GameEvents.SendCustomGameEventToServer( "upgrade_report_done", {
        ab: ab,
        kv: kv,
        reason: reason
    });

    $.GetContextPanel().DeleteAsync(0);
}

function upgrade_report(tEvent) {
    let ability_text = $.GetContextPanel().FindChildInLayoutFile("UpgradeReportAbility");
    let key_text = $.GetContextPanel().FindChildInLayoutFile("UpgradeReportKey");

    ab = tEvent.ab;
    kv = tEvent.kv;

    key_text.text = tEvent.kv;
    ability_text.text = $.Localize("#DOTA_Tooltip_Ability_" + tEvent.ab);
}

(function(){
    GameEvents.Subscribe( "upgrade_report", upgrade_report );
    GameEvents.SendCustomGameEventToServer( "dynamic_hud_callback", {});
})();