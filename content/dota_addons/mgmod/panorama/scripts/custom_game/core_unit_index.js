"use strict";
var core_data_units;
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var UnitIndexerMain = $.GetContextPanel().FindChildInLayoutFile("UnitIndexerMain");
var SearchBoxInput = $.GetContextPanel().FindChildInLayoutFile("SearchBoxInput");
var SlotInput = $.GetContextPanel().FindChildInLayoutFile("SlotInput");
var SearchBox = $.GetContextPanel().FindChildInLayoutFile("SearchBox");
var HeroToggle = $.GetContextPanel().FindChildInLayoutFile("HeroToggle");
var NormalToggle = $.GetContextPanel().FindChildInLayoutFile("NormalToggle");
var WindowPanel;
var CategoryName = "";
var ReturnUUID = "";
const local_team = Players.GetTeam(Players.GetLocalPlayer());

function CreateWindow(sCategory,tAbilities) {

    let sorted_keys = Object.keys(tAbilities).sort()
    for (const index in sorted_keys) {
        const sUnit = tAbilities[sorted_keys[index]];
        let UnitChoise = $.CreatePanel('Button', WindowPanel, 'UnitChoise_' + sUnit);
        UnitChoise.BLoadLayoutSnippet("UnitChoise");
        let UnitImage = UnitChoise.FindChildInLayoutFile("UnitImage");
        let url = '"s2r://panorama/images/heroes/' + sUnit + '_png.vtex"';
        UnitImage.style["background-image"] = 'url(' + url + ')';

        UnitChoise.ability = sUnit;
        UnitChoise.AddClass("ability_choise");
        if (sUnit.startsWith("npc_dota_hero_")) {
            UnitChoise.AddClass("hero");
        } else {
            UnitChoise.AddClass("normal");
        }
        UnitChoise.AddClass(sCategory);
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
            $.DispatchEvent("DOTAHideTextTooltip", UnitChoise);
            }
        )
        UnitChoise.SetPanelEvent(
            "onactivate", 
            function(){
                ApplyUnit(sUnit);
            }
        )
    }
}

function OnSubmitSearch() {
    let search = SearchBoxInput.text;
    let ability_choises = WindowPanel.FindChildrenWithClassTraverse( "ability_choise" );
    let bShowHeroes = HeroToggle.checked;
    let bShowNormal = NormalToggle.checked;
    if (search == "") {
        for (const key in ability_choises) {
            let bShow = true;
            if (CategoryName != "" && !ability_choises[key].BHasClass(CategoryName) ) {
                bShow = false;
            }
            if (!bShowHeroes && ability_choises[key].BHasClass("hero")) {
                bShow = false;
            }
            if (!bShowNormal && ability_choises[key].BHasClass("normal")) {
                bShow = false;
            }
            ability_choises[key].SetHasClass("hidden",!bShow);
        }
    } else {
        for (const key in ability_choises) {
            let bShow = true;
            if (CategoryName != "" && !ability_choises[key].BHasClass(CategoryName) ) {
                bShow = false;
            }
            if (!bShowHeroes && ability_choises[key].BHasClass("hero")) {
                bShow = false;
            }
            if (!bShowNormal && ability_choises[key].BHasClass("normal")) {
                bShow = false;
            }
            if (!ability_choises[key].ability.includes(search)) {
                bShow = false;
            }
            ability_choises[key].SetHasClass("hidden",!bShow);
        }
    }
}

function ApplyUnit(sUnit) {
    GameEvents.SendCustomGameEventToServer("core_unit_indexer",{
        name: sUnit,
        caller: ReturnUUID
    });
    CategoryName = "";
    ReturnUUID = "";
    WindowRoot.SetHasClass("hidden",true);
}

function Cleanup() {
    UnitIndexerMain.RemoveAndDeleteChildren();
}

function core_unit_indexer(tEvent) {
    CategoryName = tEvent.name;
    ReturnUUID = tEvent.caller;
    WindowRoot.SetHasClass("hidden",false);
}

function sort_children(hPanel) {
    let children = hPanel.Children();
    children.sort(
        function(a, b){
            if (a.id < b.id) {
                return -1;
            }
            if (a.id > b.id) {
                return 1;
            }
            return 0;
        });
        
    for (let i = 1; i < children.length; i++) {
        hPanel.MoveChildAfter(children[i],children[i-1]);
    }
}

(function () {
        core_data_units = CustomNetTables.GetAllTableValues( "core_data_units" );
        core_data_units.sort();
        Cleanup();
        WindowPanel = $.CreatePanel('Panel', UnitIndexerMain, 'WindowPanel');
        WindowPanel.BLoadLayoutSnippet("WindowPanel");
        HeroToggle.SetSelected(true);
        NormalToggle.SetSelected(true);
        let bAny = false;
        for (const key in core_data_units) {
            bAny = true;
            CreateWindow(core_data_units[key].key,core_data_units[key].value);
        }
        $.Schedule(0.5,function() {
            sort_children(WindowPanel);
        });
        if (bAny) {
            GameEvents.Subscribe( "core_unit_indexer", core_unit_indexer );
        }
})();