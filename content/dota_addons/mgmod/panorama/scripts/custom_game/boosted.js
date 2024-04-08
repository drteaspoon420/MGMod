"use strict";
var ability_values = {};
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var AbilityListInternalScroll = $.GetContextPanel().FindChildInLayoutFile("AbilityListInternalScroll");
var BoostedBox = $.GetContextPanel().FindChildInLayoutFile("BoostedBox");
var current_open = "";
var isOpen = false;
var plugin_settings = {};
var points = 0;
var points_mode = false;
var boosted_mode = "uninit";
const this_window_id = "boosted";

var local_player = Game.GetLocalPlayerInfo();
//index","player_selected_hero_entity_index":-1,"possible_hero_selection":"","player_level":0,"player_respawn_seconds":0,"player_gold":0,"player_networth":0,"player_team_id":5,"player_is_local":true,"player_has_host_privileges":true}

function CreateSettingsBlock(sAbilityName,sAbilitySettings)
{

    if (sAbilityName == "player_details") {
        UpdatePlayerDetails(sAbilitySettings);
        return;
    }
    let unit = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
    let iAbility = Entities.GetAbilityByName( unit, sAbilityName );
    let hide = (iAbility && iAbility > 0);
    ability_values[sAbilityName] = sAbilitySettings;
    let AbilityLabel = $.CreatePanel('Button', AbilityListInternalScroll, sAbilityName);
    AbilityLabel.BLoadLayoutSnippet("AbilityLabel");
    let AbilityLabelText = AbilityLabel.FindChildInLayoutFile("AbilityLabelText");
    AbilityLabelText.text = $.Localize("#DOTA_Tooltip_Ability_" +  sAbilityName);
    AbilityLabel.ability = sAbilityName;
    AbilityLabel.SetHasClass("hidden",!hide);
    AbilityLabel.SetPanelEvent(
        "onactivate", 
        function(){
            OpenAbilitySettings(sAbilityName);
        }
    );
}

function UpdatePlayerDetails(tPlayerDetails) {
    if (points_mode) {
        if (tPlayerDetails.points != undefined) {
            points = tPlayerDetails.points;
            var points_counter = WindowRoot.FindChildTraverse("BoostedPoints");
            points_counter.text = points;
        }
    }
}


function OpenAbilitySettings(sAbilityName) {
    let sAbilitySettings = ability_values[sAbilityName]
/*     $.Msg(sAbilityName);
    $.Msg(sAbilitySettings); */
    BoostedBox.RemoveAndDeleteChildren();
    let AbilitySettings = $.CreatePanel('Panel', BoostedBox, 'AbilitySettings');
    AbilitySettings.BLoadLayoutSnippet("AbilitySettings");
    let AbilitySettingsInternalScroll = AbilitySettings.FindChildInLayoutFile("AbilitySettingsInternalScroll");
    for (const key in sAbilitySettings) {
        if (boosted_mode == "points") {
            let panel = CreateSettingLeveling(sAbilityName,key,sAbilitySettings[key],AbilitySettingsInternalScroll);
        } else if (boosted_mode == "attributes") {
            let panel = CreateSettingAttributes(sAbilityName,key,sAbilitySettings[key],AbilitySettingsInternalScroll);
        } else if (boosted_mode == "free_form") {
            let panel = CreateSettingNumber(sAbilityName,key,sAbilitySettings[key],AbilitySettingsInternalScroll);
        }
    }
    //add other boosts
    current_open = sAbilityName;
    
}

function SettingChange(sAbilityName,sPluginSetting,sValue) {
    GameEvents.SendCustomGameEventToServer("boost_player",{
		ability:	sAbilityName,
		key: sPluginSetting,
		value: Number(sValue)
    });
}

function SettingChangePoints(sAbilityName,sPluginSetting,sValue) {
    GameEvents.SendCustomGameEventToServer("boost_player",{
        ability:	sAbilityName,
        key: sPluginSetting,
        value: Number(sValue)
    });
}


function CreateSettingNumber(sAbilityName,sPluginSetting,sPluginSettingData,hParent) {
    let AbilitySpecial = $.CreatePanel('Panel', hParent, 'AbilitySpecial');
    AbilitySpecial.BLoadLayoutSnippet("AbilitySpecial");
    let AbilitySpecialText = AbilitySpecial.FindChildInLayoutFile("AbilitySpecialText");
    let ll = "#DOTA_Tooltip_Ability_" +  sAbilityName + "_" + sPluginSetting;
    let bMouseOver = false;
    if ($.Localize(ll) == ll) {
        AbilitySpecialText.text = sPluginSetting;
    } else {
        AbilitySpecialText.text = $.Localize(ll);
        bMouseOver = true;
    }

    let AbilitySpecialInput = AbilitySpecial.FindChildInLayoutFile("AbilitySpecialInput");
    AbilitySpecialInput.text = Number(sPluginSettingData).toFixed(2);

    AbilitySpecialInput.SetPanelEvent(
        "oninputsubmit", 
        function(){
            SettingChange(sAbilityName,sPluginSetting,AbilitySpecialInput.text);
        }
    );
    AbilitySpecialInput.SetPanelEvent(
        "onblur", 
        function(){
            SettingChange(sAbilityName,sPluginSetting,AbilitySpecialInput.text);
        }
    );

    if (bMouseOver) {
        AbilitySpecialText.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", AbilitySpecialText, sPluginSetting);
            }
            )
        AbilitySpecialText.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTextTooltip", AbilitySpecialText);
            }
        )
    }


    return AbilitySpecial;
}

function CreateSettingLeveling(sAbilityName,sPluginSetting,sPluginSettingData,hParent) {
    let AbilitySpecialPoints = $.CreatePanel('Panel', hParent, 'AbilitySpecialPoints');
    AbilitySpecialPoints.BLoadLayoutSnippet("AbilitySpecialPoints");
    let AbilitySpecialPointsText = AbilitySpecialPoints.FindChildInLayoutFile("AbilitySpecialPointsText");
    let ll = "#DOTA_Tooltip_Ability_" +  sAbilityName + "_" + sPluginSetting;
    let bMouseOver = false;
    if ($.Localize(ll) == ll) {
        AbilitySpecialPointsText.text = sPluginSetting;
    } else {
        AbilitySpecialPointsText.text = $.Localize(ll);
        bMouseOver = true;
    }

    let AbilitySpecialPointsValue = AbilitySpecialPoints.FindChildInLayoutFile("AbilitySpecialPointsValue");
    AbilitySpecialPointsValue.text = Number(sPluginSettingData*100).toFixed(0) + "%";

    if (bMouseOver) {
        AbilitySpecialPointsText.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", AbilitySpecialPointsText, sPluginSetting);
            }
            )
        AbilitySpecialPointsText.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTextTooltip", AbilitySpecialPointsText);
            }
        )
    }
    //buttons
    let LevelupSpecial_Plus = AbilitySpecialPoints.FindChildInLayoutFile("LevelupSpecial_Plus");
    let LevelupSpecial_Minus = AbilitySpecialPoints.FindChildInLayoutFile("LevelupSpecial_Minus");
    
    LevelupSpecial_Plus.SetPanelEvent(
        "onactivate", 
        function(){
            SettingChangePoints(sAbilityName,sPluginSetting,1.0)
        }
    )
    LevelupSpecial_Minus.SetPanelEvent(
        "onactivate", 
        function(){
            SettingChangePoints(sAbilityName,sPluginSetting,-1.0)
        }
    )
    return AbilitySpecialPoints;
}

function CreateSettingAttributes(sAbilityName,sPluginSetting,sPluginSettingData,hParent) {
    let AbilitySpecialAttributes = $.CreatePanel('Panel', hParent, 'AbilitySpecialAttributes');
    AbilitySpecialAttributes.BLoadLayoutSnippet("AbilitySpecialAttributes");
    let AbilitySpecialAttributesText = AbilitySpecialAttributes.FindChildInLayoutFile("AbilitySpecialAttributesText");
    let ll = "#DOTA_Tooltip_Ability_" +  sAbilityName + "_" + sPluginSetting;
    let bMouseOver = false;
    if ($.Localize(ll) == ll) {
        AbilitySpecialAttributesText.text = sPluginSetting;
    } else {
        AbilitySpecialAttributesText.text = $.Localize(ll);
        bMouseOver = true;
    }

    let AbilitySpecialAttributesValue = AbilitySpecialAttributes.FindChildInLayoutFile("AbilitySpecialAttributesValue");
    AbilitySpecialAttributesValue.text = Number(sPluginSettingData.value*100).toFixed(0) + "%";
    AbilitySpecialAttributesValue.SetHasClass("attribute_"+ sPluginSettingData.attribute,true);

    if (bMouseOver) {
        AbilitySpecialAttributesText.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", AbilitySpecialAttributesText, sPluginSetting);
            }
            )
        AbilitySpecialAttributesText.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTextTooltip", AbilitySpecialAttributesText);
            }
        )
    }
    return AbilitySpecialAttributes;
}

function SettingsUpdate( table_name, sAbilityName, sAbilitySettings) {
/*     if (sAbilitySettings.length > 0) {
        $.Msg(sAbilitySettings); */
        if (!ability_values[sAbilityName]) {
            CreateSettingsBlock(sAbilityName,sAbilitySettings);
        } else {
            ability_values[sAbilityName] = sAbilitySettings;
            if (sAbilityName == current_open) {
                OpenAbilitySettings(sAbilityName);
            }
        }

/*     } else {
        $.Msg(sAbilityName);
        let dd = AbilityListInternalScroll.FindChildInLayoutFile(sAbilityName);
        if (dd) {
            dd.DeleteAsync(0.1);
            if (sAbilityName == current_open) {
                BoostedBox.RemoveAndDeleteChildren();
            }
        }
    } */
    HideAbilitiesNotOwned();
}

function HideAbilitiesNotOwned() {
    $.Schedule(0,function() {
        let unit = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
        let tChildren = AbilityListInternalScroll.Children()
        for (const key in tChildren) {
            let sAbility = tChildren[key].id;
            let iAbility = Entities.GetAbilityByName( unit, sAbility );
            let hide = (iAbility && iAbility > 0);
            tChildren[key].SetHasClass("hidden",!hide);
            if (hide && sAbility == current_open) {
                current_open = "";
            }
        }
    });
}


function Cleanup() {
    AbilityListInternalScroll.RemoveAndDeleteChildren();
}


(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );
    if (plugin_settings.enabled.VALUE == 0) {
        Cleanup();
        var button_bar = FindDotaHudElement("ButtonBar");
        var existing_button = button_bar.FindChildTraverse("ButtonBar_Boosted");
        if (existing_button) {
            existing_button.DeleteAsync(0);
        } 
    } else {
        boosted_mode = plugin_settings.boosted_mode.VALUE;
        points_mode = boosted_mode == "points";
        let iPlayer = Players.GetLocalPlayer();
        var sSettings = CustomNetTables.GetAllTableValues( "boosted_upgrades_" + iPlayer );
        Cleanup();
        for (const key in sSettings) {
            CreateSettingsBlock(sSettings[key].key,sSettings[key].value);
        }
        if (boosted_mode !== "free_form") {
            var player_details = WindowRoot.FindChildTraverse("PlayerDetails");
            player_details.SetHasClass("hidden",false);
        }
        CreateToggleButton();
        GameEvents.Subscribe( "open_window", open_window );
        CustomNetTables.SubscribeNetTableListener( "boosted_upgrades_" + iPlayer , SettingsUpdate );
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
    }
}

function CreateToggleButton() {
    var button_bar = FindDotaHudElement("ButtonBar");
    var existing_button = button_bar.FindChildTraverse("ButtonBar_Boosted");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "ButtonBar_Boosted" );
    panel.BLoadLayoutSnippet("ButtonBar_Boosted");
    panel.SetPanelEvent( 'onactivate', function () {
		CloseBuilder();
    });
    panel.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowTextTooltip", panel, "Boosted");
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
