"use strict";

const this_plugin_id = "universal_upgrade_options";
var mainHud = $.GetContextPanel().GetParent().GetParent().GetParent();
var UpgradeOptions = $.GetContextPanel().FindChildInLayoutFile("UpgradeOptions");

var core_data = [];
var core_links = [];

function UpgradeOption(name,id,x,y,links) {
    if (!name) {name = "unfound";}
    
    let UpgradeOption = $.CreatePanel('Button', UpgradeOptions, "UU_" + name);
    UpgradeOption.BLoadLayoutSnippet("UpgradeOption");
    let UpgradeImage = UpgradeOption.FindChildInLayoutFile("UpgradeImage");
    UpgradeImage.src = "file://{images}/custom_game/no_icon_64px.png"
/*     let UpgradeCost = UpgradeOption.FindChildInLayoutFile("UpgradeCost");
    UpgradeCost.text = cost;
    let UpgradeLevel = UpgradeOption.FindChildInLayoutFile("UpgradeLevel");
    if (max == 0) {
        UpgradeLevel.text = current + "/∞";
    } else {
        UpgradeLevel.text = current + "/" + max;
    }
    let UpgradeName = UpgradeOption.FindChildInLayoutFile("UpgradeName");
    UpgradeName.text = $.Localize("UU_" + name); */

    UpgradeOption.style.position = x+"px "+ y +"px 0px;";
    
    UpgradeOption.SetPanelEvent(
        "onmouseover", 
        function(){
            $.DispatchEvent("DOTAShowTitleImageTextTooltip", UpgradeOption, $.Localize("UU_" + name), 
            "file://{images}/custom_game/no_icon_64px.png"
            , $.Localize("UU_" + name + "_Description"));
        }
    );

    UpgradeOption.SetPanelEvent(
        "onmouseout", 
        function(){
            $.DispatchEvent("DOTAHideTitleImageTextTooltip", UpgradeOption);
        }
    );

    core_data[id] = {x,y};

    for (const k in links) {
        const lid = links[k];
        $.Msg(links[k]);
        let lk = lid +"|"+id;
        if (id < lid) {
            lk = id +"|"+lid;
        }
        if (!core_links[lk]) {
            if (core_data[lid]) {
                core_links[lk] = true;
                CreateLinkElement(id,lid);
            } 
        } else {
            $.Msg("rejected: "+lk);
        }
    }
}

function CreateLinkElement(a,b) {
    $.Msg(a,"|",b);
    let pos_a = core_data[a];
    let pos_b = core_data[b];
    let dx = pos_a.x-pos_b.x;
    let dy = pos_a.y-pos_b.y;
    let deg = Math.atan2((dx),(dy)) * (180/Math.PI);
    let LinkPanel = $.CreatePanel('Panel', UpgradeOptions, "link");
    let height = Math.sqrt(dx*dx + dy*dy);
    let x = pos_b.x+16;
    let y = pos_b.y+16;
    LinkPanel.style["margin-left"] = x + "px;";
    LinkPanel.style["margin-top"] = y + "px;";
    LinkPanel.style["transform-origin"] = "0% 0%";
    LinkPanel.style.height = height + "px;";
    LinkPanel.style.width = "4px;";
    LinkPanel.style.transform = 'rotateZ('+ deg*-1 +'deg);';
    LinkPanel.style["background-color"] = "#00000099";
    LinkPanel.style["z-index"] = -1;
    LinkPanel.style["box-shadow"] = "fill #00000099 0px 0px 4px 0px";
}

function Cleanup() {
    UpgradeOptions.RemoveAndDeleteChildren();
}

function radial(x,y,r,i,c,off) {
    x = x + Math.sin(Math.PI*2*(i/c)+off)*r;
    y = y + Math.cos(Math.PI*2*(i/c)+off)*r;
    return {x,y};
}

(function () {
    Cleanup();
    let c = 0;
    let r_center = {x: 400,y: 400};
    let jk = 0;
    UpgradeOption("coolio" + c,c++,r_center.x,r_center.y,[]);
    for (let i = 0; i < 6; i++) {
        let p = radial(r_center.x,r_center.y,50,i,6,0);
        UpgradeOption("coolio" + c,c++,p.x,p.y,[jk]);
    }
    for (let i = 0; i < 6; i++) {
        let p = radial(r_center.x,r_center.y,100,i,6,Math.PI*0.2);
        UpgradeOption("coolio" + c,c++,p.x,p.y,[jk+i+1]);
    }
    for (let i = 0; i < 6; i++) {
        let p = radial(r_center.x,r_center.y,100,i,6,Math.PI*0.37);
        UpgradeOption("coolio" + c,c++,p.x,p.y,[jk+i+7,jk+(i+7)%6+7]);
        //link later
    }
    
    const forced_links = {
        34:13,53:14,72:15,91:16,110:17,
    }
    for (let j = 1; j < 6; j++) {
        let center = radial(r_center.x,r_center.y,270,j,6,0);
        let jk = (j)*19;
        UpgradeOption("coolio" + c,c++,center.x,center.y,[]);
        let offbo = j*Math.PI/3;
        for (let i = 0; i < 6; i++) {
            let p = radial(center.x,center.y,50,i,6,offbo);
            UpgradeOption("coolio" + c,c++,p.x,p.y,[jk]);
        }
        for (let i = 0; i < 6; i++) {
            let p = radial(center.x,center.y,100,i,6,Math.PI*0.2+offbo);
            UpgradeOption("coolio" + c,c++,p.x,p.y,[jk+i+1]);
        }
        for (let i = 0; i < 6; i++) {
            let p = radial(center.x,center.y,100,i,6,Math.PI*0.37+offbo);
            if (forced_links[c] != undefined) {
                const l = forced_links[c];
                UpgradeOption("coolio" + c,c++,p.x,p.y,[l,jk+i+7,jk+(i+7)%6+7]);
            } else {
                UpgradeOption("coolio" + c,c++,p.x,p.y,[jk+i+7,jk+(i+7)%6+7]);
            }
        }
    }
    const forced_links2 = {
        117:[106,84],
        116:[87,65],
        115:[68,46],
        114:[49,27],
    }
    for (let j = 2; j < 6; j++) {
        let offbo = (Math.PI/3)+Math.PI*1.5;
        let p = radial(r_center.x,r_center.y,300,j,6,offbo);
        const flink = forced_links2[c]
        UpgradeOption("coolio" + c,c++,p.x,p.y,flink);
    }

})();