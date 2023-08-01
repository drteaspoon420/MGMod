
var Upgrades = $.GetContextPanel().FindChildInLayoutFile("Upgrades");
var current_choises = 0;
var sending = false;
const this_plugin_id = "boosted";

function UpgradeOptionNew(data) {
    if (data.id == 1) {
        current_choises = current_choises + 1;
    }
    var upgradePanel = $.CreatePanel('Panel', Upgrades, '');
    upgradePanel.BLoadLayoutSnippet("UpgradeOption");
    if (data.rarity == 2) {
        upgradePanel.SetHasClass("rare",true);
    }
    if (data.rarity == 3) {
        upgradePanel.SetHasClass("ultra",true);
    }
    if (data.rarity == 4) {
        upgradePanel.SetHasClass("unique",true);
    }

    if (data.ability.includes("item_")) {
        var UpgradeOptionImage = upgradePanel.FindChildTraverse("UpgradeOptionImage");
        UpgradeOptionImage.visible = false
        var UpgradeOptionImageItem = upgradePanel.FindChildTraverse("UpgradeOptionImageItem");
        UpgradeOptionImageItem.itemname = data.ability;
    } else {
        var UpgradeOptionImage = upgradePanel.FindChildTraverse("UpgradeOptionImage");
        UpgradeOptionImage.abilityname = data.ability;
        var UpgradeOptionImageItem = upgradePanel.FindChildTraverse("UpgradeOptionImageItem");
        UpgradeOptionImageItem.visible = false
    }
    var UpgradeOptionLabel = upgradePanel.FindChildTraverse("UpgradeOptionLabel");


    if (data.rarity == 4) {
        //uniques 
        UpgradeOptionLabel.text = $.Localize("#Unique_" + data.key);
        upgradePanel.FindChildTraverse( "OptionButtonPlus" ).SetPanelEvent( 'onactivate', function () {
            pickoption( data.ability, data.key, 1, upgradePanel,data.rarity );
        } ); 
        upgradePanel.FindChildTraverse( "OptionButtonMinus" ).visible = false;
        var OptionButtonPlusText = upgradePanel.FindChildTraverse("OptionButtonPlusText");
        OptionButtonPlusText.text = "Select";
        UpgradeOptionLabel.SetPanelEvent( 'onmouseover', function () {
            $.DispatchEvent("DOTAShowTextTooltip", UpgradeOptionLabel, $.Localize("#Unique_" + data.key + "_Desc"));
        } ); 
        UpgradeOptionLabel.SetPanelEvent( 'onmouseout', function () {
            $.DispatchEvent("DOTAHideTextTooltip", UpgradeOptionLabel);
        } );

        ///normal stuff
    } else {
        /* if (data.key == "value") {
            UpgradeOptionLabel.text = $.Localize("#DOTA_Tooltip_Ability_" + data.ability);
        }
        else */
        if ($.Localize("#DOTA_Dev_Tooltip_Ability_" + data.ability + "_" + data.key) == "#DOTA_Dev_Tooltip_Ability_" + data.ability + "_" + data.key) {
            if ($.Localize("#DOTA_Tooltip_Ability_" + data.ability + "_" + data.key) == "#DOTA_Tooltip_Ability_" + data.ability + "_" + data.key) {
                UpgradeOptionLabel.text = data.key;
            } else {
                UpgradeOptionLabel.text = $.Localize("#DOTA_Tooltip_Ability_" + data.ability + "_" + data.key);
            }
        } else {
            UpgradeOptionLabel.text = $.Localize("#DOTA_Dev_Tooltip_Ability_" + data.ability + "_" + data.key)
        }
        let current_real = data.current_mult * data.current;
        let upgrade_real = data.current * data.upgrade * 0.01;
        let downgrade_real = data.current * data.downgrade * 0.01;
        UpgradeOptionLabel.SetPanelEvent( 'onmouseover', function () {
            $.DispatchEvent("DOTAShowTextTooltip", UpgradeOptionLabel, data.key + ": " + current_real.toFixed(2) + "<br/>Alt+Click to report non-functioning KV");
        } ); 
        UpgradeOptionLabel.SetPanelEvent( 'onmouseout', function () {
            $.DispatchEvent("DOTAHideTextTooltip", UpgradeOptionLabel);
        } );
        var OptionButtonPlusText = upgradePanel.FindChildTraverse("OptionButtonPlusText");
        var OptionButtonMinusText = upgradePanel.FindChildTraverse("OptionButtonMinusText");
        OptionButtonPlusText.text = Math.round(data.upgrade)+"%";
        OptionButtonMinusText.text = Math.round(data.downgrade)+"%";
        if (Math.round(data.current_mult*100) == Math.round(data.upgrade)) {
            //upgradePanel.FindChildTraverse( "OptionButtonPlusText" ).SetHasClass("DullUpgrade",true);
            upgradePanel.FindChildTraverse( "OptionButtonPlus" ).SetHasClass("DullUpgrade",true);
            upgradePanel.FindChildTraverse( "OptionButtonPlus" ).SetPanelEvent( 'onmouseover', function () {
                $.DispatchEvent("DOTAShowTextTooltip", upgradePanel.FindChildTraverse( "OptionButtonPlus" ), "Maxed");
            } ); 
            upgradePanel.FindChildTraverse( "OptionButtonPlus" ).SetPanelEvent( 'onmouseout', function () {
                $.DispatchEvent("DOTAHideTextTooltip", upgradePanel.FindChildTraverse( "OptionButtonPlus" ));
            } );
        } else {
            upgradePanel.FindChildTraverse( "OptionButtonPlus" ).SetHasClass("OptionButtonPlus",true);
            upgradePanel.FindChildTraverse( "OptionButtonPlus" ).SetPanelEvent( 'onmouseover', function () {
                $.DispatchEvent("DOTAShowTextTooltip", upgradePanel.FindChildTraverse( "OptionButtonPlus" ), current_real.toFixed(2) + " => " + upgrade_real.toFixed(2));
            } ); 
            upgradePanel.FindChildTraverse( "OptionButtonPlus" ).SetPanelEvent( 'onmouseout', function () {
                $.DispatchEvent("DOTAHideTextTooltip", upgradePanel.FindChildTraverse( "OptionButtonPlus" ));
            } );
        }
        if (Math.round(data.current_mult*100) == Math.round(data.downgrade)) {
            //upgradePanel.FindChildTraverse( "OptionButtonMinusText" ).SetHasClass("DullUpgrade",true);
            upgradePanel.FindChildTraverse( "OptionButtonMinus" ).SetHasClass("DullUpgrade",true);
            upgradePanel.FindChildTraverse( "OptionButtonMinus" ).SetPanelEvent( 'onmouseover', function () {
                $.DispatchEvent("DOTAShowTextTooltip", upgradePanel.FindChildTraverse( "OptionButtonMinus" ), "Maxed");
            } ); 
            upgradePanel.FindChildTraverse( "OptionButtonMinus" ).SetPanelEvent( 'onmouseout', function () {
                $.DispatchEvent("DOTAHideTextTooltip", upgradePanel.FindChildTraverse( "OptionButtonMinus" ));
            } );
        } else {
            upgradePanel.FindChildTraverse( "OptionButtonMinus" ).SetHasClass("OptionButtonMinus",true);
            upgradePanel.FindChildTraverse( "OptionButtonMinus" ).SetPanelEvent( 'onmouseover', function () {
                $.DispatchEvent("DOTAShowTextTooltip", upgradePanel.FindChildTraverse( "OptionButtonMinus" ), current_real.toFixed(2) + " => " + downgrade_real.toFixed(2));
            } ); 
            upgradePanel.FindChildTraverse( "OptionButtonMinus" ).SetPanelEvent( 'onmouseout', function () {
                $.DispatchEvent("DOTAHideTextTooltip", upgradePanel.FindChildTraverse( "OptionButtonMinus" ));
            } );
        }
        upgradePanel.FindChildTraverse( "OptionButtonPlus" ).SetPanelEvent( 'onactivate', function () {
            pickoption( data.id, 1, upgradePanel);
    
        } ); 
        upgradePanel.FindChildTraverse( "OptionButtonMinus" ).SetPanelEvent( 'onactivate', function () {
            pickoption( data.id, 0, upgradePanel);
        } );

        if (data.allow_ban) {
            upgradePanel.FindChildTraverse( "OptionButtonBan" ).SetPanelEvent( 'onactivate', function () {
                pickoption( data.id, 2, upgradePanel);
            } ); 
        } else {
            upgradePanel.FindChildTraverse( "OptionButtonBan" ).visible = false;
        }

    }
}

function GetSpecial(ability,key) {
    let hero_ent = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );
    let ablity = Entities.GetAbilityByName( hero_ent, ability );
    let value = Abilities.GetSpecialValueFor( ablity, key );
    return value;
}

function UpgradeOptionsNew(table,tableKey,data) {
    if (tableKey == Players.GetLocalPlayer() + "d") {
		$.Schedule( 0.2, function() {
            Upgrades.RemoveAndDeleteChildren();
            if (typeof(data) == "object") {
                if (Object.keys(data).length > 0) {
                    for (let key in data) {
                        UpgradeOptionNew(data[key]);
                    }
                }
            }
        } );
    }
}

function pickoption(id,plus,panel) {
    current_choises = current_choises - 1;
    var pls_b = plus;
    Upgrades.RemoveAndDeleteChildren();
    if (!sending) {
        sending = true;
        $.Schedule( 0.2, function() {
            sending = false;
            GameEvents.SendCustomGameEventToServer( "upgrade_hero", {
                plus: pls_b,
                id: id
            })});
    }
}
function KeepitReal() {
    if (Upgrades.GetChildCount() == 0) {
        let kvstuff = CustomNetTables.GetTableValue( "player_booster", Players.GetLocalPlayer() + "d" );
        UpgradeOptionsNew("player_booster",Players.GetLocalPlayer() + "d",kvstuff);
    }
}


(function init() {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_plugin_id );
    if (plugin_settings.enabled.VALUE == 0) {
        $.GetContextPanel().SetHasClass("hidden",true);
    } else {
        //GameEvents.Subscribe( "upgrade_option", UpgradeOptionNew);
        CustomNetTables.SubscribeNetTableListener("player_booster",UpgradeOptionsNew);
        let kvstuff = CustomNetTables.GetTableValue( "player_booster", Players.GetLocalPlayer() + "d" );
        UpgradeOptionsNew("player_booster",Players.GetLocalPlayer() + "d",kvstuff);
    }
})();
