"use strict";
var plugin_settings = {};
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var tCurrencies = {};
var iPlayer = Players.GetLocalPlayer();
const this_window_id = "currencies";
var tCurrencyNumbers = {}

function AddCurrency(sName,tData) {
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
}




function tCurrenciesUpdate( table_name, currency, table) {
    tCurrencies[currency] = table;
    if (tCurrencies[currency].share == 0) {
        tCurrencyNumbers[sName].text = tCurrencies[currency].amount[iPlayer];
    } else if (tCurrencies[currency].share == 1) {
        let iTeam = Players.GetTeam( iPlayer );
        tCurrencyNumbers[sName].text = tCurrencies[currency].amount[iTeam];
    } else if (tCurrencies[currency].share == 2) {
        tCurrencyNumbers[sName].text = tCurrencies[currency].amount[0];
    }
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
})();