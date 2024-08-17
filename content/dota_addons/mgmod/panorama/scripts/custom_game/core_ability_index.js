"use strict";
var core_data_abilities;
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var AbilityIndexerMain = $.GetContextPanel().FindChildInLayoutFile("AbilityIndexerMain");
var SearchBoxInput = $.GetContextPanel().FindChildInLayoutFile("SearchBoxInput");
var SlotInput = $.GetContextPanel().FindChildInLayoutFile("SlotInput");
var SearchBox = $.GetContextPanel().FindChildInLayoutFile("SearchBox");
var TalentToggle = $.GetContextPanel().FindChildInLayoutFile("TalentToggle");
var NormalToggle = $.GetContextPanel().FindChildInLayoutFile("NormalToggle");
var WindowPanel;
var CategoryName = "";
var ReturnUUID = "";
const local_team = Players.GetTeam(Players.GetLocalPlayer());

function CreateWindow(sCategory,tAbilities) {

    let sorted_keys = Object.keys(tAbilities).sort();
    for (const index in sorted_keys) {
        const sAbility = tAbilities[sorted_keys[index]];
        let AbilityChoise = $.CreatePanel('Button', WindowPanel, 'AbilityChoise_' + sAbility);
        AbilityChoise.BLoadLayoutSnippet("AbilityChoise");
        let AbilityImage = AbilityChoise.FindChildInLayoutFile("AbilityImage");
        AbilityImage.abilityname = sAbility;
        AbilityChoise.ability = sAbility;
        AbilityChoise.AddClass("ability_choise");
        if (sAbility.startsWith == undefined) {
            $.Msg("invalid ability?")
            $.Msg(sAbility)
            return;
        }
        if (sAbility.startsWith("special_")) {
            AbilityChoise.AddClass("talent");
        } else {
            AbilityChoise.AddClass("normal");
        }
        AbilityChoise.AddClass(sCategory);

        AbilityChoise.SetPanelEvent(
            "onmouseover", 
            function(){
                if (GameUI.IsControlDown()) {
                    $.DispatchEvent("DOTAShowAbilityTooltip", AbilityChoise, sAbility);
                } else {
                    $.DispatchEvent("DOTAShowTextTooltip", AbilityChoise, sAbility);
                }
            }
            )
        AbilityChoise.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideAbilityTooltip", AbilityChoise);
            $.DispatchEvent("DOTAHideTextTooltip", AbilityChoise);
            }
        )
        AbilityChoise.SetPanelEvent(
            "onactivate", 
            function(){
                ApplyAbility(sAbility);
            }
        )
    }
}

function OnSubmitSearch() {
    let search = SearchBoxInput.text;
    let ability_choises = WindowPanel.FindChildrenWithClassTraverse( "ability_choise" );
    let bShowTalents = TalentToggle.checked;
    let bShowNormal = NormalToggle.checked;
    if (search == "") {
        for (const key in ability_choises) {
            let bShow = true;
            if (CategoryName != "" && !ability_choises[key].BHasClass(CategoryName) ) {
                bShow = false;
            }
            if (!bShowTalents && ability_choises[key].BHasClass("talent")) {
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
            if (!bShowTalents && ability_choises[key].BHasClass("talent")) {
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

function ApplyAbility(sAbility) {
    GameEvents.SendCustomGameEventToServer("core_ability_indexer",{
        name: sAbility,
        caller: ReturnUUID
    });
    CategoryName = "";
    ReturnUUID = "";
    WindowRoot.SetHasClass("hidden",true);
}

function Cleanup() {
    AbilityIndexerMain.RemoveAndDeleteChildren();
}

function core_ability_indexer(tEvent) {
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
        core_data_abilities = CustomNetTables.GetAllTableValues( "core_data_abilities" );
        core_data_abilities.sort();
        Cleanup();
        WindowPanel = $.CreatePanel('Panel', AbilityIndexerMain, 'WindowPanel');
        WindowPanel.BLoadLayoutSnippet("WindowPanel");
        TalentToggle.SetSelected(true);
        NormalToggle.SetSelected(true);
        let bAny = false;
        for (const key in core_data_abilities) {
            bAny = true;
            CreateWindow(core_data_abilities[key].key,core_data_abilities[key].value);
        }
        $.Schedule(0.5,function() {
            sort_children(WindowPanel);
        });
        if (bAny) {
            GameEvents.Subscribe( "core_ability_indexer", core_ability_indexer );
        }
})();