
function check_map() {
    $.Schedule( 1.0, function() {
        let map_info = Game.GetMapInfo();
        if (map_info.map_display_name == "") {
            check_map();
        } else {
            if (Game.GetMapInfo().map_display_name === 'boosted') {
                const Boosted = $.GetContextPanel().FindChildTraverse("seq_bg_boosted");
                Boosted.SetHasClass("hidden",false);
            }
        }
    });
}

(function () {
    check_map();
})();