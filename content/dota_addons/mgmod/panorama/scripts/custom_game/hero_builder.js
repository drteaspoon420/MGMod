"use strict";
var ability_registery;
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var HeroBuilderMain = $.GetContextPanel().FindChildInLayoutFile("HeroBuilderMain");
var SearchBoxInput = $.GetContextPanel().FindChildInLayoutFile("SearchBoxInput");
var SlotInput = $.GetContextPanel().FindChildInLayoutFile("SlotInput");
var SearchBox = $.GetContextPanel().FindChildInLayoutFile("SearchBox");
var WindowPanel;
var iCurrentSlot = 0;
var isOpen = false;

const this_window_id = "hero_builder";
var plugin_settings = {};
const local_team = Players.GetTeam(Players.GetLocalPlayer());

function CreateWindow(sWindow,tPurpose) {
    //Create button to open

    //Create window

    for (const index in tPurpose.ability) {
        const sAbility = tPurpose.ability[index];
        let AbilityChoise = $.CreatePanel('Button', WindowPanel, 'AbilityChoise');
        AbilityChoise.BLoadLayoutSnippet("AbilityChoise");
        let AbilityImage = AbilityChoise.FindChildInLayoutFile("AbilityImage");
        AbilityImage.abilityname = sAbility;
        AbilityChoise.ability = sAbility;
        AbilityChoise.AddClass("ability_choise");

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
        if (tPurpose.event == "add_basic_ability") {
            AbilityChoise.SetPanelEvent(
                "onactivate", 
                function(){
                    ApplyAbility(sAbility,0);
                }
            )
        }
/*         if (tPurpose.event == "add_ultimate_ability") {
            AbilityChoise.SetPanelEvent(
                "onactivate", 
                function(){
                    ApplyUltimate(sAbility,0);
                }
            )
        } */
        if (tPurpose.event == "add_talent_ability") {
            AbilityChoise.SetPanelEvent(
                "onactivate", 
                function(){
                    ApplyTalent(sAbility,0);
                }
            )
        }
    }
}

function OnSubmitSearch() {
    let search = SearchBoxInput.text;
    let ability_choises = WindowPanel.FindChildrenWithClassTraverse( "ability_choise" );
    if (search == "") {
        for (const key in ability_choises) {
            ability_choises[key].SetHasClass("hidden",false);
        }
    } else {
        for (const key in ability_choises) {
            ability_choises[key].SetHasClass("hidden",!ability_choises[key].ability.includes(search));
        }
    }
}

function GetEnt() {
    let iEnt = Players.GetLocalPlayerPortraitUnit();
/*     let iEnt = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
    let iEnts = Players.GetSelectedEntities( Players.GetLocalPlayer()  );
    if (iEnts[0]) {
        iEnt = iEnts[0];
    } */

    return iEnt;
}

function ApplyAbility(sAbility,iLevel) {
    if (GameUI.IsAltDown()) {
        GameEvents.SendCustomGameEventToServer("ban_basic_ability",{
            ability: sAbility,
        });
    } else {
        let iEnt = GetEnt();
        let iSlot = iCurrentSlot;
        GameEvents.SendCustomGameEventToServer("add_basic_ability",{
            target: iEnt,
            level: iLevel,
            ability: sAbility,
            force: GameUI.IsControlDown(),
            slot: iSlot,
        });
        Game.EmitSound("General.Buy");
        $.Schedule(0.2,function() {
        load_unit_skill_slots();
        });
    }
}

/* function ApplyUltimate(sAbility,iLevel) {
    let iEnt = GetEnt();
    let iSlot = SlotInput.text;
    GameEvents.SendCustomGameEventToServer("add_ultimate_ability",{
        target: iEnt,
        level: iLevel,
        ability: sAbility,
        force: GameUI.IsControlDown(),
        slot: iSlot,
    });
    Game.EmitSound("General.Buy");
} */

function ApplyTalent(sAbility,iLevel) {
    if (GameUI.IsAltDown()) {
        GameEvents.SendCustomGameEventToServer("ban_talent_ability",{
            ability: sAbility,
        });
    } else {
        let iEnt = GetEnt();
        let iSlot = iCurrentSlot;
        GameEvents.SendCustomGameEventToServer("add_talent_ability",{
            target: iEnt,
            level: iLevel,
            ability: sAbility,
            force: GameUI.IsControlDown(),
            slot: iSlot,
        });
        Game.EmitSound("General.Buy");
        $.Schedule(0.2,function() {
        load_unit_skill_slots();
        });
    }
}

function Cleanup() {
    HeroBuilderMain.RemoveAndDeleteChildren();
}

function hero_builder_error(event) {
    let ability_choises = WindowPanel.FindChildrenWithClassTraverse( "ability_choise" );
    for (const key in ability_choises) {
        if (ability_choises[key].ability == event.ability) {
            ability_choises[key].DeleteAsync( 0.01 );
        }
    }
    $.Msg("invalid ability " + event.ability);
    $.Schedule(0.5,()=>{Game.EmitSound("General.Dead")});
}

(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );

    let local_disable = plugin_settings.enabled.VALUE == 0;

    if (!local_disable && plugin_settings.core_apply_team.VALUE != 0 && plugin_settings.core_apply_team.VALUE != local_team) {
        local_disable = true;
    }

    if (local_disable) {
        Cleanup();
        var button_bar = FindDotaHudElement("ButtonBar");
        var existing_button = button_bar.FindChildTraverse("ButtonBar_HeroBuilder");
        if (existing_button) {
            existing_button.DeleteAsync(0);
        }
    } else {
        DebugTalents();
        ability_registery = CustomNetTables.GetAllTableValues( "ability_registery" );
        Cleanup();
        WindowPanel = $.CreatePanel('Panel', HeroBuilderMain, 'WindowPanel');
        WindowPanel.BLoadLayoutSnippet("WindowPanel");
    
        let bAny = false;
        for (const key in ability_registery) {
            bAny = true;
            CreateWindow(ability_registery[key].key,ability_registery[key].value);
        }
        if (bAny) {
            CreateToggleButton();
            GameEvents.Subscribe( "open_window", open_window );
            GameEvents.Subscribe( "hero_builder_error", hero_builder_error );
            GameEvents.Subscribe( "ban_list_export", ban_list_export );
            load_unit_skill_slots();
        }
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
    } else {
        load_unit_skill_slots();
    }
}

function load_unit_skill_slots() {
    let unit_skill_slots = $.GetContextPanel().FindChildTraverse( "UnitSkillList" );
    unit_skill_slots.RemoveAndDeleteChildren();
    
    $.Schedule(0,function() {
        let unit = Players.GetLocalPlayerPortraitUnit();
        let iCount = Entities.GetAbilityCount( unit );
        for (let i = 0; i < iCount; i++) {
            let iAbility = Entities.GetAbility( unit, i );
            let sAbility = Abilities.GetAbilityName( iAbility );
            $.Msg(i,": ",sAbility);
            let panel = $.CreatePanel('DOTAAbilityImage', unit_skill_slots, "UnitSkill" );
            panel.abilityname = sAbility;
            
            panel.SetPanelEvent(
                "onmouseover", 
                function(){
                    if (GameUI.IsControlDown()) {
                        $.DispatchEvent("DOTAShowAbilityTooltip", panel, sAbility);
                    } else {
                        $.DispatchEvent("DOTAShowTextTooltip", panel, sAbility);
                    }
                }
                )
            panel.SetPanelEvent(
                "onmouseout", 
                function(){
                $.DispatchEvent("DOTAHideAbilityTooltip", panel);
                $.DispatchEvent("DOTAHideTextTooltip", panel);
                }
            )
            panel.slot_id = i;
            panel.SetHasClass("active_slot",panel.slot_id == iCurrentSlot);
            panel.SetPanelEvent( 'onactivate', function () {
                iCurrentSlot = panel.slot_id;
                set_active_slot(iCurrentSlot);
            });
        }
    });
    
}
function set_active_slot(iSlot) {
    let unit_skill_slots = $.GetContextPanel().FindChildTraverse( "UnitSkillList" );
    let children = unit_skill_slots.Children();
    for (const key in children) {
        if (children[key].slot_id != undefined)
        children[key].SetHasClass("active_slot",children[key].slot_id == iSlot);
    }
}



function CreateToggleButton() {
    var button_bar = FindDotaHudElement("ButtonBar");
    var existing_button = button_bar.FindChildTraverse("ButtonBar_HeroBuilder");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "ButtonBar_HeroBuilder" );
    panel.BLoadLayoutSnippet("ButtonBar_HeroBuilder");
    panel.SetPanelEvent( 'onactivate', function () {
		CloseBuilder();
    });
    
    panel.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowTextTooltip", panel, "Add Abilities");
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

function DebugTalents() {
/*     let talent_box = FindDotaHudElement("DOTAStatBranch");
    let upgrade2 = talent_box.FindChildTraverse("UpgradeName2");
    $.Msg(upgrade2);
     */
}

function ban_list_export(event) {
    $.Msg(event.list);
}