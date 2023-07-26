"use strict";
var plugin_settings = {};
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var PluginListInternalScroll = $.GetContextPanel().FindChildInLayoutFile("PluginListInternalScroll");
var PluginSettingsBox = $.GetContextPanel().FindChildInLayoutFile("PluginSettingsBox");
var SettingsSaveSlots = $.GetContextPanel().FindChildInLayoutFile("SettingsSaveSlots");
var PluginListUnlockButtonText = $.GetContextPanel().FindChildInLayoutFile("PluginListUnlockButtonText");
var PluginListUnlock = $.GetContextPanel().FindChildInLayoutFile("PluginListUnlock");
var current_open = "";
var mutator_presets = {};
var forced_mode = {
    "lock_level": -1,
};


var local_player = Game.GetLocalPlayerInfo();
//index","player_selected_hero_entity_index":-1,"possible_hero_selection":"","player_level":0,"player_respawn_seconds":0,"player_gold":0,"player_networth":0,"player_team_id":5,"player_is_local":true,"player_has_host_privileges":true}
const bHost = local_player.player_has_host_privileges;

function CreateSettingsBlock(sPluginName,sPluginSettings)
{
    plugin_settings[sPluginName] = sPluginSettings;
    let PluginLabel = $.CreatePanel('Button', PluginListInternalScroll, 'PluginLabel');
    PluginLabel.BLoadLayoutSnippet("PluginLabel");
    let PluginLabelText = PluginLabel.FindChildInLayoutFile("PluginLabelText");
    if (sPluginSettings.enabled.VALUE == 1) {
        PluginLabel.SetHasClass("plugin_enabled_label",true);
        PluginLabelText.SetHasClass("plugin_enabled_text",true);
    };
    PluginLabelText.text = $.Localize("#Plugin_" +  sPluginName);
    PluginLabel.plugin = sPluginName;
    PluginLabel.SetPanelEvent(
        "onactivate", 
        function(){
            OpenPluginSettings(sPluginName);
        }
    );
    if (forced_mode != undefined && forced_mode.lock_level != undefined) {
        if (forced_mode.lock_level > 0) {
            if (forced_mode.unlocked[sPluginName] == undefined) {
                PluginLabel.SetHasClass("setting_disabled",true);
            }
        }
    }
	if (undefined==sPluginSettings.Order) {
		PluginLabel.SetAttributeInt("order",1000);
	} else {
		PluginLabel.SetAttributeInt("order",sPluginSettings.Order);
	}
}


function SortElements(elements,changes) {
	if (elements.length < 1) {
		return;
	}
	let parent = elements[0].GetParent();
	for (var i = 0; i < elements.length; i++) {
		if (i + 1 < elements.length) {
			let a = elements[i].GetAttributeInt("order",1000);
			let b = elements[i+1].GetAttributeInt("order",1000);
			if (a > b) {
				parent.MoveChildBefore(elements[i+1],elements[i]);
				changes = true;
			}
		}
	}
	if (changes) {
		$.Schedule( 0.01, function() {SortElements(parent.Children(),changes)} );
	}
}

function OpenPluginSettings(sPluginName) {
    let sPluginSettings = plugin_settings[sPluginName]
    PluginSettingsBox.RemoveAndDeleteChildren();
    let PluginSettings = $.CreatePanel('Panel', PluginSettingsBox, 'PluginSettings');
    PluginSettings.BLoadLayoutSnippet("PluginSettings");
    let PluginEnabled = PluginSettings.FindChildInLayoutFile("PluginEnabled");
    PluginEnabled.text = $.Localize("#Plugin_" +  sPluginName);
    if (sPluginSettings.enabled.VALUE == 1) {
        PluginEnabled.SetSelected(true);
    }
    if (forced_mode != undefined && forced_mode.lock_level != undefined) {
        if (forced_mode.lock_level > 0) {
            if (forced_mode.unlocked[sPluginName] == undefined) {
                PluginEnabled.SetHasClass("setting_disabled",true);
                PluginEnabled.enabled = false;
            } else {
                if (forced_mode.unlocked[sPluginName].enabled == undefined) {
                    PluginEnabled.SetHasClass("setting_disabled",true);
                    PluginEnabled.enabled = false;
                } else {
                    PluginEnabled.enabled = bHost;
                }
            }
        } else {
            PluginEnabled.enabled = bHost;
        }
    } else {
        PluginEnabled.enabled = bHost;
    }
    PluginEnabled.SetPanelEvent(
        "onactivate", 
        function(){
            if (PluginEnabled.checked) {
                SettingChange(sPluginName,"enabled","1")
            } else {
                SettingChange(sPluginName,"enabled","0")
            }
        }
    );
    let PluginSettingsInternalScroll = PluginSettings.FindChildInLayoutFile("PluginSettingsInternalScroll");
    let tmp = {}
    let io = 0;
    for (const key in sPluginSettings) {
        if (key != "enabled" && key != "Order") {
            if (undefined==sPluginSettings[key].Order) {
                tmp[1000+io] = key;
                io = io + 1;
            } else {
                tmp[sPluginSettings[key].Order] = key;
            }
            
        }
    }
    for (const dkey in tmp) {
        const key = tmp[dkey];
        let panel = CreateSetting(sPluginName,key,sPluginSettings[key],PluginSettingsInternalScroll);
        if (panel) {
            if (undefined==sPluginSettings[key].Order) {
                panel.SetAttributeInt("order",1000);
            } else {
                panel.SetAttributeInt("order",sPluginSettings[key].Order);
            }
            if (forced_mode != undefined && forced_mode.lock_level != undefined) {
                if (forced_mode.lock_level > 0) {
                    if (forced_mode.unlocked[sPluginName] == undefined || forced_mode.unlocked[sPluginName][key] == undefined ) {
                        panel.SetHasClass("setting_disabled",true);
                        $.Msg(key)
                        panel.enabled = false;
                    } else {
                        panel.enabled = bHost;
                    }
                } else {
                    panel.enabled = bHost;
                }
            } else {
                panel.enabled = bHost;
            }
        }
    }
    //add other settings
    current_open = sPluginName;
    
}



function UpdatePluginSettings(sPluginName) {
    if (bHost)
        return;
    let sPluginSettings = plugin_settings[sPluginName];
    let PluginSettings = PluginSettingsBox.FindChildInLayoutFile('PluginSettings');
    let PluginEnabled = PluginSettings.FindChildInLayoutFile("PluginEnabled");
    PluginEnabled.text = $.Localize("#Plugin_" +  sPluginName);
    if (sPluginSettings.enabled.VALUE == 1) {
        PluginEnabled.SetSelected(true);
    }
    PluginEnabled.enabled = bHost;
    let PluginSettingsInternalScroll = PluginSettings.FindChildInLayoutFile("PluginSettingsInternalScroll");
    for (const key in sPluginSettings) {
        if (key == "Order" || key == "enabled") continue;
        let VALUE = sPluginSettings[key].VALUE;
        let TYPE = sPluginSettings[key].TYPE;
        let panel = PluginSettingsInternalScroll.FindChildInLayoutFile(key);
        if (panel != undefined) {
            if (TYPE == "boolean") {
                let input = panel.FindChildInLayoutFile("SettingTypeBooleanInput");
                if (VALUE == 1) {
                    if (!input.checked)
                        input.SetSelected(true);
                } else {
                    if (input.checked)
                        input.SetSelected(false);
                }
            }
            if (TYPE == "number") {
                let input = panel.FindChildInLayoutFile("SettingTypeNumberInput");
                let val = Number(VALUE);
                if (val % 1 != 0) {
                    val = val.toFixed(2);
                }
                if (input.text != val)
                    input.text = val;
            }
            if (TYPE == "dropdown") {
                let input = panel.FindChildInLayoutFile("SettingTypeDropdownInput");
                if (input.GetSelected() != VALUE)
                    input.SetSelected(VALUE);
            }
            if (TYPE == "text") {
                let input = panel.FindChildInLayoutFile("SettingTypeTextInput");
                if (input.text != VALUE)
                    input.text = VALUE;
            }
        } else {
            $.Msg("could not find",key);
        }
    }
    //add other settings
    
}

function SettingChange(sPluginName,sPluginSetting,sValue) {
    if (!bHost) return;
    GameEvents.SendCustomGameEventToServer("setting_change",{
		plugin:	sPluginName,
		setting: sPluginSetting,
		value: sValue
    });
}

function CreateSetting(sPluginName,sPluginSetting,sPluginSettingData,hParent) {
    if (sPluginSettingData.TYPE == "boolean") {
        return CreateSettingBoolean(sPluginName,sPluginSetting,sPluginSettingData,hParent);
    }
    if (sPluginSettingData.TYPE == "number") {
        return CreateSettingNumber(sPluginName,sPluginSetting,sPluginSettingData,hParent);
    }
    if (sPluginSettingData.TYPE == "dropdown") {
        return CreateSettingDropdown(sPluginName,sPluginSetting,sPluginSettingData,hParent);
    }
    if (sPluginSettingData.TYPE == "text") {
        return CreateSettingText(sPluginName,sPluginSetting,sPluginSettingData,hParent);
    }
    return undefined;
}

function CreateSettingBoolean(sPluginName,sPluginSetting,sPluginSettingData,hParent) {
    let SettingTypeBoolean = $.CreatePanel('Panel', hParent, sPluginSetting);
    SettingTypeBoolean.BLoadLayoutSnippet("SettingTypeBoolean");
    let SettingTypeBooleanInput = SettingTypeBoolean.FindChildInLayoutFile("SettingTypeBooleanInput");
    SettingTypeBooleanInput.enabled = bHost;
    SettingTypeBooleanInput.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting);
    if (sPluginSettingData.VALUE == 1) {
        SettingTypeBooleanInput.SetSelected(true);
    }
    SettingTypeBooleanInput.SetPanelEvent(
        "onactivate", 
        function(){
            if (SettingTypeBooleanInput.checked) {
                SettingChange(sPluginName,sPluginSetting,"1");
            } else {
                SettingChange(sPluginName,sPluginSetting,"0");
            }
        }
    );
    let desc_dd = "#Plugin_" +  sPluginName + "_Option_" + sPluginSetting + "_Description";
    let desc = $.Localize(desc_dd);
    if (desc != desc_dd) {
        SettingTypeBooleanInput.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", SettingTypeBooleanInput, desc);
            }
            )
        SettingTypeBooleanInput.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTextTooltip", SettingTypeBooleanInput);
            }
        )
    }
    return SettingTypeBoolean;
}

function CreateSettingNumber(sPluginName,sPluginSetting,sPluginSettingData,hParent) {
    let SettingTypeNumber = $.CreatePanel('Panel', hParent, sPluginSetting);
    SettingTypeNumber.BLoadLayoutSnippet("SettingTypeNumber");
    let SettingTypeNumberLabel = SettingTypeNumber.FindChildInLayoutFile("SettingTypeNumberLabel");
    SettingTypeNumberLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting);

    let SettingTypeNumberInput = SettingTypeNumber.FindChildInLayoutFile("SettingTypeNumberInput");
    SettingTypeNumberInput.enabled = bHost;
    let val = Number(sPluginSettingData.VALUE);
    if (val % 1 != 0) {
        val = val.toFixed(2);
    }
    SettingTypeNumberInput.text = val;
    SettingTypeNumberInput.SetPanelEvent(
        "onblur", 
        function(){
            SettingChange(sPluginName,sPluginSetting,SettingTypeNumberInput.text);
        }
    );
    SettingTypeNumberInput.SetPanelEvent(
        "oninputsubmit", 
        function(){
            SettingChange(sPluginName,sPluginSetting,SettingTypeNumberInput.text);
        }
    );
    let desc_dd = "#Plugin_" +  sPluginName + "_Option_" + sPluginSetting + "_Description";
    let desc = $.Localize(desc_dd);
    if (desc != desc_dd) {
        SettingTypeNumberLabel.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", SettingTypeNumberLabel, desc);
            }
            )
        SettingTypeNumberLabel.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTextTooltip", SettingTypeNumberLabel);
            }
        )
    }
    return SettingTypeNumber;
}

function CreateSettingDropdown(sPluginName,sPluginSetting,sPluginSettingData,hParent) {

    let SettingTypeDropdown = $.CreatePanel('Panel', hParent, sPluginSetting);
    SettingTypeDropdown.BLoadLayoutSnippet("SettingTypeDropdown");
    let SettingTypeDropdownLabel = SettingTypeDropdown.FindChildInLayoutFile("SettingTypeDropdownLabel");
    SettingTypeDropdownLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting);
    
    let SettingTypeDropdownInput = SettingTypeDropdown.FindChildInLayoutFile("SettingTypeDropdownInput");

    let desc_dd = "#Plugin_" +  sPluginName + "_Option_" + sPluginSetting + "_Description";
    let desc = $.Localize(desc_dd);
    if (desc != desc_dd) {
        SettingTypeDropdownLabel.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", SettingTypeDropdownLabel, desc);
            }
            )
        SettingTypeDropdownLabel.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTextTooltip", SettingTypeDropdownLabel);
            }
        )
    }

    SettingTypeDropdownInput.SetPanelEvent(
        "oninputsubmit", 
        function(){
            SettingChange(sPluginName,sPluginSetting,SettingTypeDropdownInput.GetSelected().id);
            $.Msg("setting changed!");
        }
    );
	for (let i in sPluginSettingData.OPTIONS) {
		let txt = i;
		let opt = $.CreatePanel('Label', SettingTypeDropdownInput, txt);
		opt.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting + "_Drop_" + txt);
		SettingTypeDropdownInput.AddOption(opt);
		if (undefined!==sPluginSettingData.VALUE && sPluginSettingData.VALUE == txt) {
			SettingTypeDropdownInput.SetSelected(txt);
		}
	}

    return SettingTypeDropdown;
}

function CreateSettingText(sPluginName,sPluginSetting,sPluginSettingData,hParent) {
    let SettingTypeText = $.CreatePanel('Panel', hParent, sPluginSetting);
    SettingTypeText.BLoadLayoutSnippet("SettingTypeText");
    let SettingTypeTextLabel = SettingTypeText.FindChildInLayoutFile("SettingTypeTextLabel");
    SettingTypeTextLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting);

    let SettingTypeTextInput = SettingTypeText.FindChildInLayoutFile("SettingTypeTextInput");
    SettingTypeTextInput.enabled = bHost;
    SettingTypeTextInput.text = sPluginSettingData.VALUE;
    SettingTypeTextInput.SetPanelEvent(
        "onblur", 
        function(){
            SettingChange(sPluginName,sPluginSetting,SettingTypeTextInput.text);
        }
    );
    SettingTypeTextInput.SetPanelEvent(
        "oninputsubmit", 
        function(){
            SettingChange(sPluginName,sPluginSetting,SettingTypeTextInput.text);
        }
    );
    let desc_dd = "#Plugin_" +  sPluginName + "_Option_" + sPluginSetting + "_Description";
    let desc = $.Localize(desc_dd);
    if (desc != desc_dd) {
        SettingTypeTextLabel.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", SettingTypeTextLabel, desc);
            }
            )
        SettingTypeTextLabel.SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTextTooltip", SettingTypeTextLabel);
            }
        )
    }
    return SettingTypeText;
}


function SettingsUpdate( table_name, sPluginName, sPluginSettings) {
    if (plugin_settings[sPluginName].enabled.VALUE != sPluginSettings.enabled.VALUE) {
        let children = PluginListInternalScroll.Children();
        for (const key in children) {
            if (children[key].plugin) {
                if (children[key].plugin == sPluginName) {
                    let PluginLabel = children[key]; 
                    PluginLabel.SetHasClass("plugin_enabled_label",sPluginSettings.enabled.VALUE == 1);
                    let PluginLabelText = PluginLabel.FindChildInLayoutFile("PluginLabelText");
                    PluginLabelText.SetHasClass("plugin_enabled_text",sPluginSettings.enabled.VALUE == 1);
                }
            }
        }
    }
    plugin_settings[sPluginName] = sPluginSettings;
    if (sPluginName == current_open) {
        UpdatePluginSettings(sPluginName);
    }
}

function Cleanup() {
    PluginListInternalScroll.RemoveAndDeleteChildren();
    SettingsSaveSlots.RemoveAndDeleteChildren();
}

function CreateSaveSlot(iSlot) {
    let SettingsSaveSlot = $.CreatePanel('Button', SettingsSaveSlots, 'SettingsSaveSlot_' + iSlot);
    SettingsSaveSlot.BLoadLayoutSnippet("SettingsSaveSlot");
    let SettingsSaveSlotText = SettingsSaveSlot.FindChildInLayoutFile("SettingsSaveSlotText");
    SettingsSaveSlotText.text = iSlot;
    if (bHost) {
        SettingsSaveSlot.SetPanelEvent(
            "onactivate", 
            function(){
                SaveSlotLoad(iSlot)
            }
        );
    }
}

function SaveSlotLoad(iSlot) {
    for (let iSlot_n = 0; iSlot_n <= 10; iSlot_n++) {
        let SettingsSaveSlot = SettingsSaveSlots.FindChildInLayoutFile('SettingsSaveSlot_' + iSlot_n);
        SettingsSaveSlot.SetHasClass("slot_selected",iSlot_n == iSlot);
    }
    let msg = {
        slot: Number(iSlot)
    };
    GameEvents.SendCustomGameEventToServer("settings_save_slot",msg);
    $.Msg("sent message");
    $.Msg(msg);
    
}

function ActivateSaveSlot(iSlot,settings) {
    let SettingsSaveSlot = SettingsSaveSlots.FindChildInLayoutFile('SettingsSaveSlot_' + iSlot);
    SettingsSaveSlot.SetHasClass("active_slot",true);
    let slot_data = FormatSlotData(settings.data);
    SettingsSaveSlot.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowTextTooltip", SettingsSaveSlot, slot_data);
        }
        )
    SettingsSaveSlot.SetPanelEvent(
        "onmouseout", 
        function(){
        $.DispatchEvent("DOTAHideTextTooltip", SettingsSaveSlot);
        }
    )
}

function FormatSlotData(slot_data) {
    let result = "";
    let tOptionTable = {};
    let option = slot_data.split("|");
    for (const key in option) {
        let mordor = option[key].split("&");
        if (!tOptionTable[mordor[0]]) {
            tOptionTable[mordor[0]] = {};
        }
        tOptionTable[mordor[0]][mordor[1]] = mordor[2];
    }

    for (const key in tOptionTable) {
        result += "" + key + " [";
        for (const subkey in tOptionTable[key]) {
            result += subkey + " = " + tOptionTable[key][subkey] + " ";
        }
        result += "] </br>";
    }
    
    return result;
}

function SlotsUpdate( table_name, slot_name, settings) {
    let iSlot = slot_name.split("_").pop();
    $.Msg("update slot ",slot_name," ",iSlot)
    if (iSlot != undefined && !isNaN(Number(iSlot))) {
        ActivateSaveSlot(Number(iSlot),settings);
    }
}

function fixtable(t) {
    let nt = {};
    for (const key in t) {
        const element = t[key];
        nt[element.key] = element.value;
    }
    return nt;
}

function forced_mode_update( table_name, key, value) {
    forced_mode = value;
    unlock_remote();
}


function unlock_local() {
    GameEvents.SendCustomGameEventToServer("settings_vote_unlock",{});
}

function unlock_remote() {
    let c = 0;
    let t = "?";
    const players_max = Players.GetMaxPlayers();
    let d = 0;
    for (let i = 0; i < players_max; i++) {
        if (Players.IsValidPlayerID( i )) {
            d++;
        }
    }
    for (const key in forced_mode.votes) {
        const element = forced_mode.votes[key];
        c++;
        t = t + "!";
    }
    if (c/d > (forced_mode.vote_treshold * 0.01)) {
        forced_mode.lock_level = 0;
        PluginListUnlock.SetHasClass("hidden",true);
        let all = WindowRoot.FindChildrenWithClassTraverse("setting_disabled");
        for (const key in all) {
            all[key].SetHasClass("setting_disabled",false);
            if (bHost) {
                all[key].enabled = true;
            }
        }
    } else {
        PluginListUnlockButtonText.text = "Unlock" + t;
        PluginListUnlockButtonText.SetHasClass("unlock_1",c == 1);
        PluginListUnlockButtonText.SetHasClass("unlock_2",c == 2);
        PluginListUnlockButtonText.SetHasClass("unlock_3",c == 3);
        PluginListUnlockButtonText.SetHasClass("unlock_4",c == 4);
        PluginListUnlockButtonText.SetHasClass("unlock_5",c == 5);
        PluginListUnlockButtonText.SetHasClass("unlock_6",c == 6);
        PluginListUnlockButtonText.SetHasClass("unlock_7",c == 7);
        PluginListUnlockButtonText.SetHasClass("unlock_8",c == 8);
        PluginListUnlockButtonText.SetHasClass("unlock_9",c == 9);
    }
}

(function () {
    mutator_presets = fixtable(CustomNetTables.GetAllTableValues( "mutator_presets" ));
    forced_mode = CustomNetTables.GetTableValue( "forced_mode","initial" );
    if (forced_mode == undefined) {
        PluginListUnlock.SetHasClass("hidden",true);
    }
    var sSettings = CustomNetTables.GetAllTableValues( "plugin_settings" );
    Cleanup();
    for (const key in sSettings) {
        CreateSettingsBlock(sSettings[key].key,sSettings[key].value);
    }
    let children = PluginListInternalScroll.Children();
    SortElements(children);
    CustomNetTables.SubscribeNetTableListener( "plugin_settings" , SettingsUpdate );

    for (let iSlot = 0; iSlot <= 10; iSlot++) {
        CreateSaveSlot(iSlot);
    }
    var sSaveSlots = CustomNetTables.GetAllTableValues( "save_slots" );
    for (const key in sSaveSlots) {
        let iSlot = sSaveSlots[key].key.split("_").pop();
        if (iSlot != undefined && !isNaN(Number(iSlot))) {
            ActivateSaveSlot(Number(iSlot),sSaveSlots[key].value);
        }
    }
    CustomNetTables.SubscribeNetTableListener( "save_slots" , SlotsUpdate );
    CustomNetTables.SubscribeNetTableListener( "forced_mode" , forced_mode_update );

    


})();
