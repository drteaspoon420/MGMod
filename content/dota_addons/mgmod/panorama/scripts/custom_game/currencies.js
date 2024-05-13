"use strict";
var plugin_settings = {};
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var tCurrencies = {};
var iPlayer = Players.GetLocalPlayer();
const this_window_id = "currencies";
const local_team = Players.GetTeam(Players.GetLocalPlayer());
var tCurrencyNumbers = {}
var currency_open;

function AddCurrency(sName,tData) {
    if (tData.share == 3)
        return;
    tCurrencies[sName] = tData;
    let CurrencyBox = $.CreatePanel('Panel', WindowRoot, 'CurrencyBox');
    CurrencyBox.BLoadLayoutSnippet("CurrencyBox");
    let CurrencyIcon = CurrencyBox.FindChildInLayoutFile("CurrencyIcon");
    CurrencyIcon.SetHasClass("currency_" + sName,true);
    CurrencyBox.SetHasClass("share_" + tData.share,true);
    CurrencyBox.SetHasClass("currency_box_" + sName,true);
    tCurrencyNumbers[sName] = CurrencyBox.FindChildInLayoutFile("CurrencyAmmount");
    if (tData.share == 0) {
        tCurrencyNumbers[sName].text = tData.amount[iPlayer];
    } else if (tData.share == 1) {
        let iTeam = Players.GetTeam( iPlayer );
        tCurrencyNumbers[sName].text = tData.amount[iTeam];
    } else if (tData.share == 2) {
        tCurrencyNumbers[sName].text = tData.amount[0];
    }
    
    if (plugin_settings[sName + "_gold_buy"].VALUE > 0) {
        CurrencyBox.SetPanelEvent(
            "onactivate", 
            function(){
                ShowOptionMenu(sName);
            }
        );
    }
}

function ShowOptionMenu(sName) {
    
    let CurrencyActionBox = $.CreatePanel('Panel', $.GetContextPanel(), sName + "_options");
    CurrencyActionBox.BLoadLayoutSnippet("CurrencyActionBox");
    CurrencyActionBox.SetAcceptsFocus(true)
    CurrencyActionBox.SetFocus();
    CurrencyActionBox.SetPanelEvent(
        "onblur", 
        function(){
            CurrencyActionBox.DeleteAsync(0);
        }
    );
    let spend_count = 0;
    for (const key in tCurrencies[sName].spend_options) {
        const option = tCurrencies[sName].spend_options[key];
        $.Msg(option);
        if (option.autobuy == false) {
            spend_count = 99;
        }
        if (option.team == 1 || local_team == option.team) {
            spend_count++;
        }
    }
    if (spend_count > 1) {
        for (const key in tCurrencies[sName].spend_options) {
            const option = tCurrencies[sName].spend_options[key];
            let CurrencyAction = $.CreatePanel('Panel', CurrencyActionBox, sName + "_options");
            CurrencyAction.BLoadLayoutSnippet("CurrencyAction");
            CurrencyAction.FindChildInLayoutFile("CurrencyLabel").text = $.Localize("#SpendOption_" + option.plugin_name + "_" + option.option_name);
            CurrencyAction.FindChildInLayoutFile("CurrencyCost").text = option.cost;
            CurrencyAction.SetPanelEvent(
                "onactivate", 
                function(){
                    GameEvents.SendCustomGameEventToServer("currency_spend",{
                        "currency": sName,
                        "option": option.fn
                    });
                }
            );
        }
    }
    for (const key in tCurrencies[sName].earn_options) {
        const option = tCurrencies[sName].earn_options[key];
        let CurrencyEarnAction = $.CreatePanel('Panel', CurrencyActionBox, sName + "_options");
        CurrencyEarnAction.BLoadLayoutSnippet("CurrencyEarnAction");
        CurrencyEarnAction.FindChildInLayoutFile("CurrencyCost").text = option.cost;
        CurrencyEarnAction.FindChildInLayoutFile("CurrencyEarn").text = option.earn;
        CurrencyEarnAction.SetPanelEvent(
            "onactivate", 
            function(){
                GameEvents.SendCustomGameEventToServer("currency_earn",{
                    "currency": sName,
                    "option": option.fn
                });
            }
        );
    }
}



function tCurrenciesUpdate( table_name, currency, table) {
    tCurrencies[currency] = table;
    if (tCurrencies[currency].share == 0) {
        tCurrencyNumbers[currency].text = tCurrencies[currency].amount[iPlayer];
    } else if (tCurrencies[currency].share == 1) {
        let iTeam = Players.GetTeam( iPlayer );
        tCurrencyNumbers[currency].text = tCurrencies[currency].amount[iTeam];
    } else if (tCurrencies[currency].share == 2) {
        tCurrencyNumbers[currency].text = tCurrencies[currency].amount[0];
    }
    $.Msg(tCurrencies);
}

function Cleanup() {
    WindowRoot.RemoveAndDeleteChildren();
}

(function () {
    
    Cleanup();
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );
    if (plugin_settings.enabled.VALUE == 0) {
        WindowRoot.SetHasClass("hidden",true);
    } else {
        tCurrencies = CustomNetTables.GetAllTableValues( "currencies" );
        for (const key in tCurrencies) {
            AddCurrency(tCurrencies[key].key,tCurrencies[key].value);
        }
        CustomNetTables.SubscribeNetTableListener( "currencies" , tCurrenciesUpdate );
    }
    if (Game.IsHUDFlipped()) {
        $.GetContextPanel().SetHasClass("flipped",true);
        WindowRoot.SetHasClass("map_left_window_root",true);
        WindowRoot.SetHasClass("map_right_window_root",false);
    } else {
        $.GetContextPanel().SetHasClass("flipped",false);
        WindowRoot.SetHasClass("map_left_window_root",false);
        WindowRoot.SetHasClass("map_right_window_root",true);
    }
})();