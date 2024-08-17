"use strict";
function ToUrl(url) {
    $.DispatchEvent("ExternalBrowserGoToURL", url);
}


(function () {
    var hPanel = $.GetContextPanel();
    let children = hPanel.Children();
    for (let i = 0; i < children.length; i++) {
        children[i].SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTitleTextTooltip", children[i], $.Localize("#Setuplink_" +  children[i].id), $.Localize("#Setuplink_" +  children[i].id + "_desc") );
            }
            )
        children[i].SetPanelEvent(
            "onmouseout", 
            function(){
            $.DispatchEvent("DOTAHideTitleTextTooltip", children[i]);
            }
        )
    }
})();