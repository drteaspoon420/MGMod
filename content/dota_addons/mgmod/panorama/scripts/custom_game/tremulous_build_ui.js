const container = $.GetContextPanel().FindChildInLayoutFile("BuildingOptions");

function DOTABuildingPickerClosed() {
    $.GetContextPanel().SetHasClass("ShowPicker",false);
    $.GetContextPanel().DeleteAsync(0.21);
}

function BuildingOption(name,cost) {
    
    var panel = $.CreatePanel('Panel', container, 'BuildingOption');
    panel.BLoadLayoutSnippet("BuildingOption");
    panel.FindChildInLayoutFile("BuildingImage").abilityname = name;
    panel.FindChildrenWithClassTraverse( "BuildingName" )[0].text =  $.Localize("#DOTA_Tooltip_Ability_" +  name);
    panel.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowAbilityTooltip", panel, name);
        });
    panel.SetPanelEvent(
        "onmouseout", 
        function(){
            $.DispatchEvent("DOTAHideAbilityTooltip", panel);
        }
    );
    panel.SetPanelEvent( 'onactivate', function () {
        PickBuilding(name);
    });
    panel.FindChildInLayoutFile("GoldCost").text = cost;


}

function PickBuilding(name) {
    GameEvents.SendCustomGameEventToServer("building_pick",{
        name: name,
    });
    DOTABuildingPickerClosed();
}


(function () {
    container.RemoveAndDeleteChildren();

    BuildingOption("tremulous_build_ancient",8);
    BuildingOption("tremulous_build_spawn",4);
    BuildingOption("tremulous_build_tower",3);
    BuildingOption("tremulous_build_shrine",3);
    BuildingOption("tremulous_build_shop",4);
    BuildingOption("tremulous_build_barracks",5);

    $.GetContextPanel().SetHasClass("ShowPicker",true);
})();