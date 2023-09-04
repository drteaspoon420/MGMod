"use strict";
const this_window_id = "heroscreen_rework";
var plugin_settings = {};
var hero_pools = {};

function DeleteDotaDefaults() {
    FindDotaHudElement("HeroPickScreen").style.opacity = "0";
    FindDotaHudElement("PreMinimapContainer").style.opacity = "0";
    FindDotaHudElement("AvailableItemsContainer").style.opacity = "0";
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
        const attribute_category = hero_pools[key];
        let category_panel = $.GetContextPanel().FindChildTraverse("category_panel_"+key);
        if (category_panel == undefined) {
            category_panel = CreateAttributeCategory(key);
        }
        for (const key in attribute_category) {
            const hero_data = attribute_category[key];
            let hero_panel = category_panel.FindChildTraverse("hero_"+hero_data.id);
            if (hero_panel == undefined) {
                hero_panel = CreateHeroPanel(category_panel.Find,hero_data);
            }
        }
    }
}

function CreateAttributeCategory(key) {
    var panel = $.CreatePanel('Button', $.GetContextPanel().FindChildTraverse("MainChoiseArea"), "category_panel_"+key );
    panel.FindChildInLayoutFile("category_name").text = key;
    panel.BLoadLayoutSnippet("HeroCategory");
    return panel;
}

function CreateHeroPanel(category_panel,key) {
    var panel = $.CreatePanel('Button', $.GetContextPanel().FindChildTraverse("MainChoiseArea"), "category_panel_"+key );
    panel.FindChildInLayoutFile("category_name").text = key;
    panel.BLoadLayoutSnippet("HeroCategory");
    return panel;
}

function BanHero(id) {
    
}

function PickHero(id) {
    
}

function Init() {
    DeleteDotaDefaults();
    Game.SetRemainingSetupTime( -1);

    hero_pools = CustomNetTables.GetTableValue( "heroselection_rework", "hero_pools" );
    if (hero_pools.length > 0) {
        PopulateHeroChoises();
    }
    CustomNetTables.SubscribeNetTableListener("heroselection_rework",NetTableUpdate);
}

function NetTableUpdate(table,tableKey,data) {
    if (tableKey == "hero_pools") {
        hero_pools = data;
        if (hero_pools.length > 0) {
            PopulateHeroChoises();
        }
    }
}

(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );
    if (plugin_settings == undefined || plugin_settings.enabled == undefined || plugin_settings.enabled.VALUE == undefined  || plugin_settings.enabled.VALUE == 0) {
        $.GetContextPanel().DeleteAsync(0);
    } else {
        Init();
    }
})();