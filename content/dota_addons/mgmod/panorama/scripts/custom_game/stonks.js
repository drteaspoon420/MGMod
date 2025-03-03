"use strict";
var ability_values = {};
var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("WindowRoot");
var current_open = "";
var isOpen = false;
var plugin_settings = {};
const this_window_id = "stonks";
const local_team = Players.GetTeam(Players.GetLocalPlayer());

var stonks = [];
var last_sort = 0;
var last_price = 100;

function FlashPositive(stonk) {
    let panel = $('#listing_' + stonk);
    panel.SetHasClass("PositiveFlash",true);
    $.Schedule(0.3, function(){
            panel.SetHasClass("PositiveFlash",false);
		});
}

function FlashNegative(stonk) {
    let panel = $('#listing_' + stonk);
    panel.SetHasClass("NegativeFlash",true);
    $.Schedule(0.3, function(){
            panel.SetHasClass("NegativeFlash",false);
		});
}

function StonksCountUniform() {
    let main = $('#stonks_list')
    let children = main.Children()
    switch (last_price) {
        case 1:
            last_price = 10;
            break;
        case 10:
            last_price = 100;
            break;
        case 100:
            last_price = 1000;
            break;
        case 1000:
            last_price = 10000;
            break;
        case 10000:
            last_price = 1;
            break;
    }
    for (let i = 0; i < children.length; i++) {
        $("#listing_" + children[i].stonk + "_ammount").text = last_price
    }
}


function SortStonksName() {
    let main = $('#stonks_list')
    let children = main.Children()
    if (last_sort != 1) {
        children.sort(
            function(a, b){
                if(a.id < b.id) { return -1; }
                if(a.id > b.id) { return 1; }
                return 0;
            });
        last_sort = 1;
    } else {
        children.sort(
            function(a, b){
                if(a.id > b.id) { return -1; }
                if(a.id < b.id) { return 1; }
                return 0;
            });
            last_sort = -1;
    }
    for (let i = 1; i < children.length; i++) {
        main.MoveChildAfter(children[i],children[i-1])
    }
}

function SortStonksPrice() {
    let main = $('#stonks_list')
    let children = main.Children()
    children.sort(
        function(a, b){
            return 0;
        });
        
    if (last_sort != 2) {
        children.sort(
            function(a, b){
                if(stonks[a.stonk].price < stonks[b.stonk].price) { return -1; }
                if(stonks[a.stonk].price > stonks[b.stonk].price) { return 1; }
                return 0;
            });
        last_sort = 2;
    } else {
        children.sort(
            function(a, b){
                if(stonks[a.stonk].price > stonks[b.stonk].price) { return -1; }
                if(stonks[a.stonk].price < stonks[b.stonk].price) { return 1; }
                return 0;
            });
            last_sort = -1;
    }
    for (let i = 1; i < children.length; i++) {
        main.MoveChildAfter(children[i],children[i-1])
    }
}

function SortStonksLeft() {
    let main = $('#stonks_list')
    let children = main.Children()
    if (last_sort != 3) {
        children.sort(
            function(a, b){
                if(stonks[a.stonk].available < stonks[b.stonk].available) { return -1; }
                if(stonks[a.stonk].available > stonks[b.stonk].available) { return 1; }
                return 0;
            });
        last_sort = 3;
    } else {
        children.sort(
            function(a, b){
                if(stonks[a.stonk].available > stonks[b.stonk].available) { return -1; }
                if(stonks[a.stonk].available < stonks[b.stonk].available) { return 1; }
                return 0;
            });
        last_sort = -1;
    }
    for (let i = 1; i < children.length; i++) {
        main.MoveChildAfter(children[i],children[i-1])
    }
}

function UpdateStonk( table_name, stonk, event) {
    let new_stonk = true;
    if (stonks[stonk]) {
        new_stonk = false;
    }
    
    let prev_price = event.price;;
    if (!new_stonk) {
        prev_price = stonks[stonk].price;
    }
    stonks[stonk] = {
        price: event.price,
        available: event.available
    }

    if (new_stonk) {
        var panel = $.CreatePanel('Panel',$('#stonks_list'),'listing_' + stonk);
        panel.SetHasClass("stonkListing",true);
        panel.stonk = stonk;
        var name = $.CreatePanel('Label',panel,'name_'+ stonk)
        name.SetHasClass("stonkName",true);
        name.text = $.Localize("#Dota_Tooltip_" + stonk)
        name.SetPanelEvent('onmouseover', (function () {
            $.DispatchEvent("DOTAShowTextTooltip", name, $.Localize("#Dota_Tooltip_" + stonk + "_Description"));
            }));
        name.SetPanelEvent('onmouseout', (function () {
            $.DispatchEvent("DOTAHideTextTooltip", name);
            }));
        var price = $.CreatePanel('Label',panel,'listing_' + stonk + '_price')
        price.SetHasClass("stonkPrice",true);
        var available = $.CreatePanel('Label',panel,'listing_' + stonk + '_availabe')
        available.SetHasClass("stonkAvailable",true);
        var ammount_box = $.CreatePanel('TextEntry',panel,'listing_' + stonk + '_ammount')
        ammount_box.SetHasClass("stonkAmount",true);
        ammount_box.text = 100
        var buy_button = $.CreatePanel('Button',panel,'')
        buy_button.SetHasClass("stonkBuy",true);
        buy_button.SetPanelEvent('onactivate', (function (){
            var ammount = Number($("#listing_" + stonk + "_ammount").text);
            if (isNaN(ammount) || ammount < 0) {
                ammount = 0
                $("#listing_" + stonk + "_ammount").text = ammount
            } else {
                GameEvents.SendCustomGameEventToServer( "stonk_buy", { "stonk" : stonk, "amount" : ammount } );
            }
        }))
        
        buy_button.SetPanelEvent('onmouseover', (function () {
            $.DispatchEvent("DOTAShowTextTooltip", buy_button, 'Buy');
            }));
        buy_button.SetPanelEvent('onmouseout', (function () {
            $.DispatchEvent("DOTAHideTextTooltip", buy_button);
            }));
        var sell_button = $.CreatePanel('Button',panel,'')
        sell_button.SetHasClass("stonkSell",true);
        
        sell_button.SetPanelEvent('onmouseover', (function () {
            $.DispatchEvent("DOTAShowTextTooltip", sell_button, 'Sell');
            }));
        sell_button.SetPanelEvent('onmouseout', (function () {
            $.DispatchEvent("DOTAHideTextTooltip", sell_button);
            }));
        sell_button.SetPanelEvent('onactivate', (function (){
            var ammount = Number($("#listing_" + stonk + "_ammount").text);
            if (isNaN(ammount) || ammount < 0) {
                ammount = 0
                $("#listing_" + stonk + "_ammount").text = ammount
            } else {
                GameEvents.SendCustomGameEventToServer( "stonk_sell", { "stonk" : stonk, "amount" : ammount } );
            }
        }))
    }

    $("#listing_" + stonk + "_availabe").text = event.available
    $("#listing_" + stonk + "_price").text = event.price + 'g'
    if (prev_price < event.price) {
        FlashPositive(stonk);
    } else if (prev_price > event.price) {
        FlashNegative(stonk);
    }
}



(function () {
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_window_id );
    let local_disable = plugin_settings.enabled.VALUE == 0;

    if (!local_disable && plugin_settings.core_apply_team.VALUE != 0 && plugin_settings.core_apply_team.VALUE != local_team) {
        local_disable = true;
    }

    if (local_disable) {
        var button_bar = FindDotaHudElement("ButtonBar");
        var existing_button = button_bar.FindChildTraverse("ButtonBar_Stonks");
        if (existing_button) {
            existing_button.DeleteAsync(0);
        } 
    } else {
        CreateToggleButton();
        GameEvents.Subscribe( "open_window", open_window );
        CustomNetTables.SubscribeNetTableListener( "stonks" , UpdateStonk );
        let start_stonks = CustomNetTables.GetAllTableValues( "stonks" );
        for (const key in start_stonks) {
            let data = start_stonks[key];
            UpdateStonk("stonks",data.key,data.value);
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
    }
}

function CreateToggleButton() {
    var button_bar = FindDotaHudElement("ButtonBar");
    var existing_button = button_bar.FindChildTraverse("ButtonBar_Stonks");
    if (existing_button) {
        existing_button.DeleteAsync(0);
    } 
    var panel = $.CreatePanel('Button', $.GetContextPanel(), "ButtonBar_Stonks" );
    panel.BLoadLayoutSnippet("ButtonBar_Stonks");
    panel.SetPanelEvent( 'onactivate', function () {
		CloseBuilder();
    });
    panel.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowTextTooltip", panel, "Stonks");
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
