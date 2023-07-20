
var mainHud = $.GetContextPanel().GetParent().GetParent().GetParent()
var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")
var localID = Players.GetLocalPlayer()
var lastRememberedHero = Players.GetPlayerHeroEntityIndex( localID )
var mainShop = shopHud.FindChildTraverse("GridMainShop");
var shopHeaders = mainShop.FindChildTraverse("GridShopHeaders").FindChildTraverse("GridMainTabs");
var basicTab = shopHeaders.FindChildTraverse("GridBasicsTab");
var upgradesTab = shopHeaders.FindChildTraverse("GridUpgradesTab");
var neutralsTab = shopHeaders.FindChildTraverse("GridNeutralsTab");
var upgradeContent = mainShop.FindChildTraverse("GridUpgradeItems");

const this_plugin_id = "boosted";

function RemoveExtraTooltip() {
    var bob = mainHud.FindChildTraverse("Tooltips");
    var lol = bob.FindChildTraverse("DOTAAbilityTooltip");
    //DebugTree(lol);
    if (lol != undefined) {
        var tooltipContent = lol.FindChildTraverse("AbilityCoreDetails");
        if (tooltipContent != undefined) {
            var oldtooltip = tooltipContent.FindChildTraverse("AbilityExtraTooltip")
            if(oldtooltip != undefined){
                oldtooltip.style.visibility = "visible"
                oldtooltip.RemoveAndDeleteChildren()
                oldtooltip.DeleteAsync(0)
            }
        }
    }
}

function DebugTree(panel,s = "") {
    let children = panel.Children();
    for (let i = 0; i < children.length; i++) {
        $.Msg(s,children[i].id);
        DebugTree(children[i], s + "-");
    }
}

function InventoryExtraTooltip(object, entityIndex, inventorySlot){
	RemoveExtraTooltip();
    let eventData = ClientSideExtraInventory(entityIndex,inventorySlot);
	//GameEvents.SendCustomGameEventToServer( "ability_tooltip_extra_request", {entindex : entityIndex,  inventory : inventorySlot} )
    if (eventData) {
        CreateExtraTooltip(eventData);
    }
}

function ShopExtraTooltip(object, abilityName, guideName, entityIndex){
	RemoveExtraTooltip();
    let eventData = ClientSideExtraShop(abilityName,entityIndex);
	//GameEvents.SendCustomGameEventToServer( "ability_tooltip_extra_request", {entindex : entityIndex,  inventory : inventorySlot} )
    if (eventData) {
    CreateExtraTooltip(eventData);
    }
}

function CreateKeyPanel(parent,ability,key,value) {
    var panel = $.CreatePanel('Panel', parent, ability + "_" + key );
    panel.BLoadLayoutSnippet("AbilityChange");
    //panel.AddClass("AbilityChange");
    var text_panel = panel.FindChildTraverse("AbilityChangesLabelKey");
    var value_panel = panel.FindChildTraverse("AbilityChangesLabelValue");
    //$.Schedule( 0, function() {
        if (text_panel) {
            if ($.Localize("#DOTA_Dev_Tooltip_Ability_" + ability + "_" + key) == "#DOTA_Dev_Tooltip_Ability_" + ability + "_" + key) {
                if ($.Localize("#DOTA_Tooltip_Ability_" + ability + "_" + key) == "#DOTA_Tooltip_Ability_" + ability + "_" + key) {
                    text_panel.text = key;
                } else {
                    text_panel.text = $.Localize("#DOTA_Tooltip_Ability_" + ability + "_" + key);
                }
            } else {
                text_panel.text = $.Localize("#DOTA_Dev_Tooltip_Ability_" + ability + "_" + key)
            }
        }
        if (value_panel) {
            value_panel.text = (Math.floor(value*100)) + "%";
        }
    //});
    panel.SetHasClass("hidden",(Math.floor(value*100)) == 100);
}

function Explore(panel,s) {
    var o = panel.FindChildTraverse(s);
    o.style.visibility = "visible";
}

function ClientSideExtraInventory(entityIndex,inventorySlot) {
    let ability = Entities.GetItemInSlot( entityIndex, inventorySlot );
    let name = Abilities.GetAbilityName( ability );
    let team = Entities.GetTeamNumber( entityIndex );
    let kvstuff = CustomNetTables.GetTableValue( "hero_upgrades", name );
    let boosts = [];
    if (kvstuff) {
        for(var slot in kvstuff){
            if (kvstuff[slot][team] ) {
                boosts.push(
                    {
                        "ability": name,
                        "key": slot,
                        "value": kvstuff[slot][team],
                    });
            }
        }
        return {boosts: boosts};
    }
    return null
}

function ClientSideExtraShop(name,entityIndex) {
    let team = Entities.GetTeamNumber( entityIndex );
    let kvstuff = CustomNetTables.GetTableValue( "hero_upgrades", name );
    let boosts = [];
    if (kvstuff) {
        for(var slot in kvstuff){
            if (kvstuff[slot][team] ) {
                boosts.push(
                    {
                        "ability": name,
                        "key": slot,
                        "value": kvstuff[slot][team],
                    });
            }
        }
        return {boosts: boosts};
    }
    return null
}

function CreateExtraTooltip(eventData){
	var DOTAtooltipContent = mainHud.FindChildTraverse("Tooltips").FindChildTraverse("DOTAAbilityTooltip");
    //DebugTree(DOTAtooltipContent);
    //Explore(DOTAtooltipContent,"AbilityUpgradeProgress");
	var tooltipContent = DOTAtooltipContent.FindChildTraverse("AbilityCoreDetails");
	var descriptions = tooltipContent.FindChildTraverse("AbilityLore");
    tooltipContent.AddClass("hidden");
	RemoveExtraTooltip();
	var extratooltipContainer = $.CreatePanel("Panel", $.GetContextPanel(), "AbilityExtraTooltip");
    extratooltipContainer.AddClass("AbilityExtraTooltip");
    for(var slot in eventData.boosts){
        CreateKeyPanel( extratooltipContainer, eventData.boosts[slot]["ability"], eventData.boosts[slot]["key"], eventData.boosts[slot]["value"] )
    }
	extratooltipContainer.SetParent(tooltipContent);
	tooltipContent.MoveChildBefore( extratooltipContainer, descriptions );
}

function AbilityExtraTooltip(entityIndex, abilityname, abilityid)
{
	RemoveExtraTooltip()
    let eventData = ClientSideExtraShop(abilityname,abilityid);
	//GameEvents.SendCustomGameEventToServer( "ability_tooltip_extra_request", {pID : localID, entindex : abilityid,  item : abilityname} )
    if (eventData) {
    CreateExtraTooltip(eventData);
    }
}

(function(){
    plugin_settings = CustomNetTables.GetTableValue( "plugin_settings", this_plugin_id );
    if (plugin_settings.enabled.VALUE == 0) {
        $.GetContextPanel().SetHasClass("hidden",true);
    } else {
        $.RegisterForUnhandledEvent( "DOTAShowAbilityInventoryItemTooltip", InventoryExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAShowAbilityShopItemTooltip", ShopExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAShowAbilityTooltip", RemoveExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAShowAbilityTooltipForEntityIndex", AbilityExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAShowAbilityTooltipForGuide", RemoveExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAShowAbilityTooltipForHero", RemoveExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAShowAbilityTooltipForLevel", RemoveExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAShowRuneTooltip", RemoveExtraTooltip );
        
        $.RegisterForUnhandledEvent( "DOTAHideAbilityTooltip", RemoveExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAHideBuffTooltip", RemoveExtraTooltip );
        $.RegisterForUnhandledEvent( "DOTAHideRuneTooltip", RemoveExtraTooltip );
        //GameEvents.Subscribe("ability_tooltip_extra_response", CreateExtraTooltip);
        //GameEvents.Subscribe("ability_tooltip_extra_response_all", CreateExtraTooltipAll);
    }

})();