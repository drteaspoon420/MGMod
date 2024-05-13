
const this_plugin_id = "boosted";
var path_links = {};
const local_team = Players.GetTeam(Players.GetLocalPlayer());

var team_panels = {
    "2": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesRadiant"),
    "3": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesDire"),
    "6": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesCustom1"),
    "7": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesCustom2"),
    "8": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesCustom3"),
    "9": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesCustom4"),
    "10": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesCustom5"),
    "11": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesCustom6"),
    "12": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesCustom7"),
    "13": $.GetContextPanel().FindChildInLayoutFile("InspectUpgradesCustom8"),
};

function print() {
    $.Msg(arguments);
}

function linkPanel(path,panel) {
	var path_str = path[0];
	for (var i = 1; i < path.length; i++) {
		path_str = path_str + "&" + path[i];
	}
	path_links[path_str] = panel;
}

function getLinkedPanel(path) {

	path_str = path[0];
	for (var i = 1; i < path.length; i++) {
		path_str = path_str + "&" + path[i];
	}
	if (path_links[path_str]) {
		return path_links[path_str];
	}
    return undefined;
}

function UpdateInspector(table,tableKey,data) {
    var id = Number(table.split("_")[2]);
    if (isNaN(id)) return;
    
    CreateAbilityPanel(tableKey,data,id);

}

function CreateHeroPanel(iPlayer) {
    let iTeam = Players.GetTeam( iPlayer );
    if (team_panels[String(iTeam)] == undefined) return;
    
    hParent = team_panels[String(iTeam)]
    let hPanel = hParent.FindChildTraverse("player_" + iPlayer);
    if (hPanel == undefined) {
        hPanel = $.CreatePanel('Panel', hParent, "player_" + iPlayer);
        hPanel.BLoadLayoutSnippet("HeroMain");
        hPanel.FindChildInLayoutFile("HeroMainImage").heroid = Players.GetSelectedHeroID(iPlayer);

        const steamid = Game.GetPlayerInfo( iPlayer ).player_steamid;
        hPanel.FindChildTraverse("HeroMainAvatar").steamid = String(steamid);
    }
    return hPanel.FindChildInLayoutFile("HeroMainUpgrades")
}

function CreateCatPanel(ability,parent,iPlayer) {

    var cat = ability.split("_")[0];
    var panel = parent.FindChildTraverse(cat);
    if (panel == undefined) {
        panel = $.CreatePanel('Panel', parent, cat);
        panel.BLoadLayoutSnippet("AbilityCategory");
    }
    return panel;
}

function CreateAbilityPanel(ability,data,iPlayer) {
    var player_panel = CreateHeroPanel(iPlayer)
    var parent = CreateCatPanel(ability,player_panel,iPlayer);
    var panel = parent.FindChildTraverse(ability);
    if (panel == undefined) {
        panel = $.CreatePanel('Panel', parent, ability);
        panel.BLoadLayoutSnippet("AbilityMain");
        panel.FindChildTraverse("AbilityMainImage").abilityname = ability;
    }
    let c = true;
    for (let key in data) {
        let kv = data[key];
        if (!isNaN(kv)) {
            if ((Math.floor(kv*100)) !== 100) {
                c = false;
                CreateKeyPanel(panel,ability,key,kv);
            }
        }
    }
    panel.SetHasClass("hidden",c);
}

function CreateKeyPanel(parent,ability,key,value) {
    var panel = parent.FindChildTraverse(ability + "_" + key);
    if (panel == undefined) {
        panel = $.CreatePanel('Panel', parent.FindChildTraverse("AbilityMainUpgrades"), ability + "_" + key );
        panel.BLoadLayoutSnippet("AbilityChange");
        if ($.Localize("#DOTA_Dev_Tooltip_Ability_" + ability + "_" + key) == "#DOTA_Dev_Tooltip_Ability_" + ability + "_" + key) {
            if ($.Localize("#DOTA_Tooltip_Ability_" + ability + "_" + key) == "#DOTA_Tooltip_Ability_" + ability + "_" + key) {
                panel.FindChildTraverse("AbilityChangesLabelKey").text = key;
            } else {
                panel.FindChildTraverse("AbilityChangesLabelKey").text = $.Localize("#DOTA_Tooltip_Ability_" + ability + "_" + key);
            }
        } else {
            panel.FindChildTraverse("AbilityChangesLabelKey").text = $.Localize("#DOTA_Dev_Tooltip_Ability_" + ability + "_" + key)
        }
        panel.FindChildTraverse("AbilityChangeReport").SetPanelEvent( 'onactivate', function () {
            GameEvents.SendCustomGameEventToServer( "upgrade_report", {ab: ability,kv: key});
        } );
    }
    panel.FindChildTraverse( "AbilityChangesLabelValue" ).text = (Math.floor(value*100)) + "%";
    panel.SetHasClass("hidden",(Math.floor(value*100)) == 100);
}


(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_plugin_id );

    
    let local_disable = plugin_settings.enabled.VALUE == 0;

    if (!local_disable && plugin_settings.core_apply_team.VALUE != 1 && plugin_settings.core_apply_team.VALUE != local_team) {
        local_disable = true;
    }

    if (local_disable) {
        $.GetContextPanel().SetHasClass("hidden",true);
    } else {
        CreateToggleButton();
        CustomNetTables.SubscribeNetTableListener("player_upgrades_0",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_1",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_2",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_3",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_4",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_5",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_6",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_7",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_8",UpdateInspector);
        CustomNetTables.SubscribeNetTableListener("player_upgrades_9",UpdateInspector);
    }
})();

function CreateToggleButton() {
    
    var button_bar = FindDotaHudElement("ButtonBar");
    var existing_button = button_bar.FindChildTraverse("UpgradeInspectButton");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "UpgradeInspectButton" );
    panel.BLoadLayoutSnippet("UpgradeInspectButton");
    panel.SetPanelEvent( 'onactivate', function () {
		$.GetContextPanel().ToggleClass("hidden");
    });
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
