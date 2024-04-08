"use strict";
const this_window_id = "legends_of_dota";
var plugin_settings = {};
var hero_pools = {};
var ability_pools = {};
var player_data = {};
var current_view = 0;
var talent_toggle = 0;
var local_ability_cursor = 1;
const MainChoiseArea = $.GetContextPanel().FindChildTraverse("MainChoiseArea");
const ExtraChoiseArea = $.GetContextPanel().FindChildTraverse("ExtraChoiseArea");
const FinalActions = $.GetContextPanel().FindChildTraverse("FinalActions");
const pId = Players.GetLocalPlayer();

function DeleteDotaDefaults() {
    FindDotaHudElement("HeroPickScreen").style.opacity = "0";
    FindDotaHudElement("PreMinimapContainer").style.opacity = "0";
    //FindDotaHudElement("AvailableItemsContainer").style.opacity = "0";
    FindDotaHudElement("FriendsAndFoes").style.opacity = "0";
    //FindDotaHudElement("HeroPickingTeamComposition").style.opacity = "0";
    FindDotaHudElement("BattlePassContainer").style.opacity = "0";
    //FindDotaHudElement("PlusChallengeSelector").style.opacity = "0";
}

function PopulateTeams() {
    const team_ids = Game.GetAllTeamIDs();
    for (let i = 0; i < team_ids.length; i++) {
        const team_info = Game.GetTeamDetails(team_ids[i]);
        $.Msg(team_info);
    }
/*     Players.GetMaxPlayers();
    Players.GetMaxTeamPlayers();
    Game.GetAllPlayerIDs();

    Players.IsSpectator( iPlayerID );
    Players.GetPlayerColor( iPlayerID );
    Game.GetPlayerInfo( iPlayerID ); */
}

function PopulateHeroChoises() {
    for (const attribute in hero_pools) {
        const attribute_category = hero_pools[attribute];
        let category_panel = $.GetContextPanel().FindChildTraverse("category_panel_"+attribute);
        if (category_panel == undefined) {
            category_panel = CreateAttributeCategory(attribute);
        }
        const host_panel = category_panel.FindChildInLayoutFile("HeroCategoryContent");
        for (const key in attribute_category) {
            const hero_data = attribute_category[key];
            let hero_panel = category_panel.FindChildTraverse("hero_"+hero_data.name);
            if (hero_panel == undefined) {
                hero_panel = CreateHeroPanel(host_panel,hero_data);
            }
        }
        let children = host_panel.Children();
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
            host_panel.MoveChildAfter(children[i],children[i-1]);
        }
    }
}

function CreateAttributeCategory(key) {
    var panel = $.CreatePanel('Button', MainChoiseArea, "category_panel_"+key );
    panel.BLoadLayoutSnippet("HeroCategory");
    let name_panel = panel.FindChildInLayoutFile("category_name");
    if (name_panel != undefined)
    name_panel.text = key;
    return panel;
}

function CreateHeroPanel(category_panel,hero_data) {
    var panel = $.CreatePanel('Button',category_panel, hero_data.name );
    panel.BLoadLayoutSnippet("HeroOption"); 
    let avatar = panel.FindChildInLayoutFile("avatar");
    avatar.heroid = hero_data.id;

    panel.SetPanelEvent( 'onactivate', function () {
        PickHero(hero_data.id);
    });

    return panel;
}

function BanHero(id) {
    
}

function PickHero(id) {
    GameEvents.SendCustomGameEventToServer("hero_pick",{
        hero: id,
    });
    SetLocalHero(id);
    
    ShowAbilitySelection();
}

function SetLocalHero(id) {
    ExtraChoiseArea.FindChildInLayoutFile("LocalPortrait").heroid = id;
}

function ToggleTalents() {
    if (talent_toggle == 0) {
        talent_toggle = 1;
        const linkable = MainChoiseArea.FindChildrenWithClassTraverse("AbilityOption");
        for (const key in linkable) {
            const thing = linkable[key]
            if (thing.data != undefined && thing.data.category != undefined) {
                thing.SetHasClass("hidden", (thing.data.category != "talent"));
                thing.SetHasClass("recommend_talent",false);
            }
        }

        
        if (player_data[pId] != undefined && player_data[pId].abilities != undefined) {
            for (let i = 1; i < 7; i++) {
                if (player_data[pId].abilities["s"+i] != undefined) {
                    const o_data = FindAbilityData(player_data[pId].abilities["s"+i].name);
                    RecommendLinked(o_data.name,o_data.linked)
                }
            }
            for (let i = 15; i < 26; i++) {
                if (player_data[pId].abilities["s"+i] != undefined) {
                    const o_data = FindAbilityData(player_data[pId].abilities["s"+i].name);
                    RecommendLinked(o_data.name,o_data.linked)
                }
            }
        }
    } else if (talent_toggle == 1) {
        talent_toggle = 0;
        const linkable = MainChoiseArea.FindChildrenWithClassTraverse("AbilityOption");
        for (const key in linkable) {
            const thing = linkable[key]
            if (thing.data != undefined && thing.data.category != undefined) {
                thing.SetHasClass("hidden", (thing.data.category == "talent"));
            }
        }
    }
}

function is_linked(a,b) {
    for (const i in b.linked) {
        const ll = b.linked[i];
        if (ll == a.name) return true;
    }
    for (const i in a.linked) {
        const ll = a.linked[i];
        if (ll == b.name) return true;
    }
    return false;
}


function ShowHeroSelection() {
    if (current_view == 2) return;
    current_view = 0;
    MainChoiseArea.RemoveAndDeleteChildren();
    UpdateHeroSelection();
    FinalActions.SetHasClass("hidden",true);
}
function UpdateHeroSelection() {
    PopulateHeroChoises();

}
function ShowAbilitySelection() {
    if (current_view == 2) return;
    FinalActions.SetHasClass("hidden",false);
    current_view = 1;
    MainChoiseArea.RemoveAndDeleteChildren();
    UpdateAbilitySelection();
    talent_toggle = 1;
    ToggleTalents();
    MoveCursor(1);
}
function UpdateAbilitySelection() {
    PopulateAbilityChoises();

}

function PopulateAbilityChoises() {
    const content_box = MainChoiseArea;
    $.Msg(ability_pools);
    for (const hero in ability_pools) {
        const hero_category = ability_pools[hero];
        let category_panel = content_box.FindChildTraverse("category_panel_"+hero_category.key);
        if (category_panel == undefined) {
            category_panel = CreateAbilityCategory(hero_category.key);
        }
        for (const key in hero_category.value) {
            const ability_data = hero_category.value[key];
           let ability_panel = category_panel.FindChildTraverse(ability_data.name);
            if (ability_panel == undefined) {
                ability_panel = CreateAbilityPanel(category_panel.FindChildInLayoutFile("AbilityCategoryContent"),ability_data);
            }
        }
    }
    let children = content_box.Children();
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
        content_box.MoveChildAfter(children[i],children[i-1]);
    }
}

function CreateAbilityCategory(key) {
    var panel = $.CreatePanel('Button', MainChoiseArea, "hero_panel_"+key );
    panel.BLoadLayoutSnippet("AbilityCategory");
    return panel;
}

function CreateAbilityPanel(category_panel,ability_data) {
    const panel = $.CreatePanel('Button',category_panel, ability_data.name );
    panel.BLoadLayoutSnippet("AbilityOption"); 
    let icon = panel.FindChildInLayoutFile("icon");
    icon.abilityname = ability_data.name;

    panel.SetPanelEvent( 'onactivate', function () {
        PickAbility(ability_data);
    });
    
    panel.SetPanelEvent(
        "onmouseover", 
        function(){
            if (GameUI.IsControlDown()) {
                $.DispatchEvent("DOTAShowTextTooltip", panel, ability_data.name);
            } else {
/*                 if (ability_data.name.startsWith("special_bonus_")) {
                    let localized = $.Localize("#DOTA_Tooltip_ability_" + ability_data.name);
                    $.DispatchEvent("DOTAShowTextTooltip", panel, localized);
                } else { */
                    $.DispatchEvent("DOTAShowAbilityTooltip", panel, ability_data.name);
/*                 } */
            }
            HighlightLinked(ability_data.name,ability_data.linked);
        }
        );
    panel.SetPanelEvent(
        "onmouseout", 
        function(){
            $.DispatchEvent("DOTAHideAbilityTooltip", panel);
            $.DispatchEvent("DOTAHideTextTooltip", panel);
        }
    );
    panel.data = ability_data;

    return panel;
}

function bTestTalentSlot(ability_data) {
    return (local_ability_cursor > 6 && local_ability_cursor < 15 );
}

function PickAbility(ability_data) {
    if (ability_data.category == "talent" && bTestTalentSlot(ability_data)) {
        GameEvents.SendCustomGameEventToServer("ability_pick",{
            name: ability_data.name,
            category: ability_data.category,
            slot: local_ability_cursor
        });
    } else if (!bTestTalentSlot(ability_data) && ability_data.category != "talent" ) {
        GameEvents.SendCustomGameEventToServer("ability_pick",{
            name: ability_data.name,
            category: ability_data.category,
            slot: local_ability_cursor
        });
    }
}

function MoveCursor(i) {
    if (i == local_ability_cursor) return;
    const oSlot = ExtraChoiseArea.FindChildTraverse("LocalAbility_" + local_ability_cursor);
    if (oSlot != undefined) {
        oSlot.SetHasClass("active_slot",false);
    }

    local_ability_cursor = i;
    if (i > 6 && i < 15 && talent_toggle == 0) {
        ToggleTalents();
    } else if ((i < 7 || i > 14) && talent_toggle == 1) {
        ToggleTalents();
    }

    const nSlot = ExtraChoiseArea.FindChildTraverse("LocalAbility_" + local_ability_cursor);
    if (nSlot != undefined) {
        nSlot.SetHasClass("active_slot",true);
    }
}

function RecommendLinked(name,olink) {
    const linkable = MainChoiseArea.FindChildrenWithClassTraverse("linkable");
    for (const key in linkable) {
        const thing = linkable[key]
        if (thing.data != undefined && thing.data.linked != undefined) {

            let bFound = false;
            for (const i in olink) {
                const ll = olink[i];
                if (ll == thing.data.name) bFound = true;
            }
            for (const i in thing.data.linked) {
                const ll = thing.data.linked[i];
                if (ll == name) bFound = true;
            }
            if (bFound) {
                thing.SetHasClass("recommend_talent", true);
                $.Msg("recommending " + thing.data.name);
            }
        }
    }
}

function HighlightLinked(name,olink) {
    const linkable = MainChoiseArea.FindChildrenWithClassTraverse("linkable");
    for (const key in linkable) {
        const thing = linkable[key]
        if (thing.data != undefined && thing.data.linked != undefined) {

            let bFound = false;
            for (const i in olink) {
                const ll = olink[i];
                if (ll == thing.data.name) bFound = true;
            }
            for (const i in thing.data.linked) {
                const ll = thing.data.linked[i];
                if (ll == name) bFound = true;
            }
            thing.SetHasClass("link_active", bFound);
        }
    }
}

function Ready() {
    GameEvents.SendCustomGameEventToServer("player_ready",{
    });
}

function UpdatePlayerStatus() {
    if (player_data != undefined && player_data[pId] != undefined) {
        if (player_data[pId].hero != undefined)
            SetLocalHero(player_data[pId].hero);
        if (player_data[pId].abilities != undefined) {
            for (let i = 1; i < 26; i++) {
                if (player_data[pId].abilities["s"+i] != undefined) {
                    $.Msg(player_data[pId].abilities["s"+i]);
                    const ability_name = player_data[pId].abilities["s"+i].name;
                    const ablity_select = ExtraChoiseArea.FindChildTraverse("LocalAbility_" + i);
                    ablity_select.abilityname = ability_name;
                    ablity_select.data = FindAbilityData(ability_name);
                    ablity_select.SetPanelEvent(
                        "onmouseover", 
                        function(){
                            if (GameUI.IsControlDown()) {
                                $.DispatchEvent("DOTAShowTextTooltip", ablity_select, ablity_select.data.name);
                            } else {
                                $.DispatchEvent("DOTAShowAbilityTooltip", ablity_select, ablity_select.data.name);
                            }
                            HighlightLinked(ablity_select.data.name,ablity_select.data.linked);
                        }
                        );
                    ablity_select.SetPanelEvent(
                        "onmouseout", 
                        function(){
                            $.DispatchEvent("DOTAHideAbilityTooltip", ablity_select);
                            $.DispatchEvent("DOTAHideTextTooltip", ablity_select);
                            HighlightLinked("none",{});
                        }
                    );
                }
            }
        }
        if (player_data[pId].ready != undefined && player_data[pId].ready == true) {
            if (current_view != 2)
            ShowReadyScreen();
        }
    }
}

function ReselectHero() {
    if (current_view == 2) return;
    current_view = 0;
    ShowHeroSelection();
}

function ability_pick_response(tEvent) {
    if (tEvent.name == "failure") {
    } else if (tEvent.name == "random") {
        Game.EmitSound("General.Buy");
 } else {
        Game.EmitSound("General.Dead");
        if (local_ability_cursor == 14) {
            MoveCursor(7);
        } else if(local_ability_cursor == 6) {
            MoveCursor(1);
        } else if(local_ability_cursor == 25){
            MoveCursor(15);
        } else {
            MoveCursor(local_ability_cursor+1);
        }
        Game.EmitSound("General.Buy");
    }
}

function FindAbilityData(sname) {
    for (const hero in ability_pools) {
        const hero_category = ability_pools[hero];
        for (const key in hero_category.value) {
            const ability_data = hero_category.value[key];
            if (ability_data.name == sname) {
                return ability_data;
            }
        }
    }
}

function Init() {
    DeleteDotaDefaults();
    $.Msg("init!");
    if (plugin_settings.extra_abilities != undefined && plugin_settings.extra_abilities.VALUE != true) {
        const AbilityBoxExtra = ExtraChoiseArea.FindChildTraverse("AbilityBoxExtra");
        AbilityBoxExtra.DeleteAsync(0);
    }
    if (plugin_settings.allow_talents != undefined && plugin_settings.allow_talents.VALUE != true) {
        const TalentTree = ExtraChoiseArea.FindChildTraverse("TalentTree");
        TalentTree.DeleteAsync(0);
    }
    hero_pools = CustomNetTables.GetTableValue( "heroselection_rework", "hero_pools" );
    ability_pools = CustomNetTables.GetAllTableValues( "heroselection_rework_abilities");
    player_data = CustomNetTables.GetTableValue( "heroselection_rework", "player_data" );
    CustomNetTables.SubscribeNetTableListener("heroselection_rework",HeroNetTableUpdate);
    GameEvents.Subscribe( "ability_pick", ability_pick_response );
    if (player_data != undefined && player_data[pId] != undefined && player_data[pId].hero != undefined && player_data[pId].hero > 0) {
        SetLocalHero(player_data[pId].hero);
        if (player_data[pId].ready != undefined && player_data[pId].ready == true) {
            ShowReadyScreen();
        } else {
            ShowAbilitySelection();
        }
    } else {
        ShowHeroSelection();
    }
}

function ShowReadyScreen() {
    current_view = 2;
    MainChoiseArea.RemoveAndDeleteChildren();
    FinalActions.SetHasClass("hidden",false);
}

function UpdateReady() {
    let c = 0;
    let b = 0;
    for (const key in player_data) {
        const dd = player_data[key];
        c++;
        if (dd.ready != undefined && dd.ready == true) {
            b++;
        }
    }
    const ready_count = ExtraChoiseArea.FindChildTraverse("ready_count");
    if (ready_count != undefined) {
        ready_count.text = b+"/"+c;
    }
    
}

function HeroNetTableUpdate(table,tableKey,data) {
    if (tableKey == "hero_pools") {
        hero_pools = data;
        if (current_view == 0) {
            UpdateHeroSelection();
        }
    }
    if (tableKey == "player_data") {
        player_data = data;
        UpdatePlayerStatus();
        UpdateReady();
    }
}

(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );
    if (plugin_settings == undefined || plugin_settings.enabled == undefined || plugin_settings.enabled.VALUE == undefined  || plugin_settings.enabled.VALUE == 0) {
        $.GetContextPanel().DeleteAsync(0);
    } else {
        FinalActions.SetHasClass("hidden",true);
        Init();
    }
})();