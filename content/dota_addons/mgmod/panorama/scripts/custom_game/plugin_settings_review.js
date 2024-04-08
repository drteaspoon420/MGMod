"use strict";
var plugin_settings = {};
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var PluginListInternalScroll = $.GetContextPanel().FindChildInLayoutFile("PluginListInternalScroll");
var PluginSettingsBox = $.GetContextPanel().FindChildInLayoutFile("PluginSettingsBox");
var current_open = "";

function CreateSettingsBlock(sPluginName,sPluginSettings)
{
    if (sPluginName == "core_teams") return;
    plugin_settings[sPluginName] = sPluginSettings;
    let PluginLabel = $.CreatePanel('Button', PluginListInternalScroll, 'PluginLabel');
    PluginLabel.BLoadLayoutSnippet("PluginLabel");
    let PluginLabelText = PluginLabel.FindChildInLayoutFile("PluginLabelText");
    if (sPluginSettings.enabled.VALUE == 1) {
        PluginLabel.SetHasClass("plugin_enabled_label",true);
        PluginLabelText.SetHasClass("plugin_enabled_text",true);
    }

    for (const key in sPluginSettings) {
        if (sPluginSettings[key].VALUE != undefined && sPluginSettings[key].DEFAULT != undefined && sPluginSettings[key].VALUE != sPluginSettings[key].DEFAULT) {
            PluginLabel.SetHasClass("has_changed",true);
            break
        }
    }
    PluginLabelText.text = $.Localize("#Plugin_" +  sPluginName);
    PluginLabel.plugin = sPluginName;
    PluginLabel.SetPanelEvent(
        "onactivate", 
        function(){
            OpenPluginSettings(sPluginName);
        }
    );
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
    if (sPluginSettings.enabled.VALUE != sPluginSettings.enabled.DEFAULT) {
        PluginEnabled.SetHasClass("has_changed",true);
    }
    PluginEnabled.enabled = false;
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
            panel.enabled = false;
            if (sPluginSettings[key].VALUE != sPluginSettings[key].DEFAULT) {
                panel.SetHasClass("has_changed",true);
            }
        }
    }
    current_open = sPluginName;
}



function UpdatePluginSettings(sPluginName) {
    let sPluginSettings = plugin_settings[sPluginName];
    let PluginSettings = PluginSettingsBox.FindChildInLayoutFile('PluginSettings');
    let PluginEnabled = PluginSettings.FindChildInLayoutFile("PluginEnabled");
    PluginEnabled.text = $.Localize("#Plugin_" +  sPluginName);
    if (sPluginSettings.enabled.VALUE == 1) {
        PluginEnabled.SetSelected(true);
    }
    PluginEnabled.enabled = false;
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
    SettingTypeBooleanInput.enabled = false;
    if (sPluginSettingData.UNIT != undefined) {
        SettingTypeBooleanInput.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting) + "(" + sPluginSettingData.UNIT +")";
    } else {
        SettingTypeBooleanInput.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting);
    }
    if (sPluginSettingData.VALUE == 1) {
        SettingTypeBooleanInput.SetSelected(true);
    }
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
    if (sPluginSettingData.UNIT != undefined) {
        SettingTypeNumberLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting) + " (" + sPluginSettingData.UNIT +")";
    } else {
        SettingTypeNumberLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting);
    }

    let SettingTypeNumberInput = SettingTypeNumber.FindChildInLayoutFile("SettingTypeNumberInput");
    SettingTypeNumberInput.enabled = false;
    let val = Number(sPluginSettingData.VALUE);
    if (val % 1 != 0) {
        val = val.toFixed(2);
    }
    SettingTypeNumberInput.text = val;
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
    SettingTypeDropdown.enabled = false;
    let SettingTypeDropdownLabel = SettingTypeDropdown.FindChildInLayoutFile("SettingTypeDropdownLabel");
    if (sPluginSettingData.UNIT != undefined) {
        SettingTypeDropdownLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting) + " (" + sPluginSettingData.UNIT +")";
    } else {
        SettingTypeDropdownLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting);
    }
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
    if (sPluginSettingData.UNIT != undefined) {
        SettingTypeTextLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting) + " (" + sPluginSettingData.UNIT +")";
    } else {
        SettingTypeTextLabel.text = $.Localize("#Plugin_" +  sPluginName + "_Option_" + sPluginSetting);
    }

    let SettingTypeTextInput = SettingTypeText.FindChildInLayoutFile("SettingTypeTextInput");
    SettingTypeTextInput.enabled = false;
    SettingTypeTextInput.text = sPluginSettingData.VALUE;
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
}

(function () {
    var sSettings = CustomNetTables.GetAllTableValues( "plugin_settings" );
    Cleanup();
    for (const key in sSettings) {
        CreateSettingsBlock(sSettings[key].key,sSettings[key].value);
    }
    let children = PluginListInternalScroll.Children();
    SortElements(children);
    CreateToggleButton();
})();

function CreateToggleButton() {
    
    var button_bar = FindDotaHudElement("ButtonBar");
    var existing_button = button_bar.FindChildTraverse("PluginSettingsReviewButton");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "PluginSettingsReviewButton" );
    panel.BLoadLayoutSnippet("PluginSettingsReviewButton");
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
