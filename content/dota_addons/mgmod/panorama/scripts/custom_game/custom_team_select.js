

var WindowRoot = $.GetContextPanel().FindChildInLayoutFile("TeamBox");
var all_teams = [
    DOTATeam_t.DOTA_TEAM_GOODGUYS,
    DOTATeam_t.DOTA_TEAM_BADGUYS,
    DOTATeam_t.DOTA_TEAM_CUSTOM_1, 
    DOTATeam_t.DOTA_TEAM_CUSTOM_2,
    DOTATeam_t.DOTA_TEAM_CUSTOM_3,
    DOTATeam_t.DOTA_TEAM_CUSTOM_4,
    DOTATeam_t.DOTA_TEAM_CUSTOM_5,
    DOTATeam_t.DOTA_TEAM_CUSTOM_6,
    DOTATeam_t.DOTA_TEAM_CUSTOM_7,
    DOTATeam_t.DOTA_TEAM_CUSTOM_8,
    1
];
GameUI.CustomUIConfig().team_colors = {}
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#00ff00;"; // { 243, 201, 9 }		--		Yellow
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS] = "#ff0000;"; // { 243, 201, 9 }		--		Yellow
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = "#f3c909;"; // { 243, 201, 9 }		--		Yellow
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = "#FF6C00;"; // { 255, 108, 0 }		--		Orange
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = "#3455FF;"; // { 52, 85, 255 }		--		Blue
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4] = "#65d413;"; // { 101, 212, 19 }	--		Green
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_5] = "#815336;"; // { 129, 83, 54 }		--		Brown
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = "#1bc0d8;"; // { 27, 192, 216 }	--		Cyan
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = "#c7e40d;"; // { 199, 228, 13 }	--		Olive
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = "#8c2af4;"; // { 140, 42, 244 }	--		Purple
GameUI.CustomUIConfig().team_colors[1] = "#ffffff;"; // { 140, 42, 244 }	--		Purple

var forced_mode = {
    lock_level: -1,
};
var local_player = Game.GetLocalPlayerInfo();
const bHost = local_player.player_has_host_privileges;
var ReadyButtonTimer = $.GetContextPanel().FindChildInLayoutFile("ReadyButtonTimer");
var ReadyButtonID2 = $.GetContextPanel().FindChildInLayoutFile("ReadyButtonID2");
var ReadyButtonLabel = $.GetContextPanel().FindChildInLayoutFile("ReadyButtonLabel");


var ReadyTimerRunning = false;
var ReadyTimerValue = 60;

var bRedrawn = true;
function Cleanup() {
    WindowRoot.RemoveAndDeleteChildren();
    bRedrawn = true;
}


function hookSliderChange(panel, callback, onComplete) {
	var shouldListen = false;
	var checkRate = 0.03;
	var currentValue = panel.value;
    bRedrawn = false;

	var inputChangedLoop = function () {
        if (bRedrawn) {
            return;
        }
		if (currentValue != panel.value) {
			currentValue = panel.value;
			callback(panel, currentValue);
		}

		if (shouldListen) {
			$.Schedule(checkRate, inputChangedLoop);
		}
	};

	panel.SetPanelEvent("onmouseover", function () {
		shouldListen = true;
		//inputChangedLoop();
	});

	panel.SetPanelEvent("onmouseout", function () {
		shouldListen = false;
        if (bRedrawn) {
            return;
        }
		if (currentValue != panel.value) {
			currentValue = panel.value;
			callback(panel, currentValue);
            onComplete(panel, currentValue);
		}
	});
} 

function CreateTeam(iTeam,tTeam,hParent) {
    let TeamTray = $.CreatePanel('Panel', hParent, "team_tray_" + iTeam);
    TeamTray.BLoadLayoutSnippet("TeamTray");
    if (iTeam == 1) {
        TeamTray.SetHasClass("SpectatorTray",true);
    }
    let TeamTrayContent = TeamTray.FindChildInLayoutFile("TeamTrayContent");
    if (iTeam == 1) {
        TeamTrayContent.SetHasClass("SpectatorTrayContent",true);
    }
    if (tTeam.team_max_players > 0) {
        let tPlayers = Game.GetPlayerIDsOnTeam( iTeam );
        let occupied = 0;
        for (let i = 0; i < tPlayers.length; i++) {
            CreateSlotPlayer(iTeam,i,TeamTrayContent,tPlayers[i]);
            occupied += 1;
        }
        for (let i = occupied; i < tTeam.team_max_players; i++) {
            CreateSlotEmpty(iTeam,i,TeamTrayContent);
        }
    } else {
        if (!bHost || forced_mode.lock_level > 0) {
            TeamTray.SetHasClass("hidden",true);
        }
    }
    let TeamCountInput = TeamTray.FindChildInLayoutFile("TeamCountInput");
    if (!bHost || forced_mode.lock_level > 0) {
        TeamCountInput.SetHasClass("team_setting_hidden",true)
    }
    TeamCountInput.enabled = bHost;
    let TeamName = TeamTray.FindChildInLayoutFile("TeamName");
    TeamName.style.color = GameUI.CustomUIConfig().team_colors[iTeam];
    if (iTeam == 1) {
        TeamCountInput.SetHasClass("hidden",true);
        TeamName.text = $.Localize(tTeam.team_name);
    } else {
        TeamName.text = $.Localize(tTeam.team_name);
        TeamCountInput.min = 0;
        TeamCountInput.max = 24;
        TeamCountInput.increment = 1;
        TeamCountInput.text = tTeam.team_max_players;
        TeamCountInput.SetPanelEvent(
            "onblur", 
            function () {
                let val = Number(TeamCountInput.text);
                if (val % 1 != 0) {
                    val =  Math.round(val.toFixed(0));
                }
                if (val < 0) val = 0;
                if (val > 24) val = 24;
                TeamCountInput.text = val
                GameEvents.SendCustomGameEventToServer("setting_team_rescale",{
                    team:	iTeam,
                    number: val
                });
            },
        );
        TeamCountInput.SetPanelEvent(
            "oninputsubmit", 
            function () {
                let val = Number(TeamCountInput.text);
                if (val % 1 != 0) {
                    val =  Math.round(val.toFixed(0));
                }
                if (val < 0) val = 0;
                if (val > 24) val = 24;
                TeamCountInput.text = val
                GameEvents.SendCustomGameEventToServer("setting_team_rescale",{
                    team:	iTeam,
                    number: val
                });
            },
        );
    }
    return TeamTray;
}

function CreateSlotEmpty(iTeam,iSlot,hParent) {
    const ciTeam = iTeam;
    let PlayerSlot = $.CreatePanel('Panel', hParent, "team_tray_" + iTeam + "_slot_" + iSlot);
    PlayerSlot.BLoadLayoutSnippet("PlayerSlot");
    PlayerSlot.SetPanelEvent(
        "onactivate", 
        function(){
            Game.PlayerJoinTeam( ciTeam );
            $.Msg("joining ", ciTeam);
        }
    );

    return PlayerSlot;
}


function CreateSlotPlayer(iTeam,iSlot,hParent,iPlayer) {
    let PlayerSlot = $.CreatePanel('Panel', hParent, "team_tray_" + iTeam + "_slot_" + iSlot);
    PlayerSlot.BLoadLayoutSnippet("PlayerSlot");
    const PlayerInfo = Game.GetPlayerInfo( iPlayer );
    $.Msg(PlayerInfo);

    let PlayerAvatar = PlayerSlot.FindChildInLayoutFile("PlayerAvatar");
    let PlayerName = PlayerSlot.FindChildInLayoutFile("PlayerName");
    PlayerName.text = PlayerInfo.player_name;
    PlayerAvatar.steamid = PlayerInfo.player_steamid;
    
    return PlayerSlot;
}

function teams_changed(tEvent) {
    PreWork2();
}

function BuildUI() {
    
    for (let i = 0; i < all_teams.length; i++) {
        const team_info = Game.GetTeamDetails(all_teams[i]);
        CreateTeam(all_teams[i],team_info,WindowRoot);
    }
}


function PreWork() {
    Game.AutoAssignPlayersToTeams();
    $.Schedule(0.1,PreWork2);
}

function PreWork2() {
    Cleanup();
    BuildUI();
}

function forced_mode_update( table_name, key, value) {
    forced_mode = value;
    if (forced_mode.lock_level == undefined) {
        forced_mode.lock_level = -1;
    }
    unlock_remote();
}

function unlock_remote() {
    $.Msg("remote unlock");
    let c = 0;
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
    }
    if (c/d > (forced_mode.vote_treshold * 0.01)) {
        forced_mode.lock_level = 0;
        PreWork2();
    } else {
        const f = c/d;
        const tr = forced_mode.vote_treshold * 0.01;
        const from_tr = (f/tr)*100;
        PluginUnlockBar.value = from_tr;
    }
}


function OnAutoAssignPressed()
{
    if (!bHost) return;
    Game.ShufflePlayerTeamAssignments();
    $.Schedule(0.1,PreWork2);
}

//
function UpdateTimer()
{
    var gameTime = Game.GetGameTime();
    var transitionTime = Game.GetStateTransitionTime();


    if ( transitionTime >= 0 )
    {
        ReadyButtonTimer.text = Math.max( 0, Math.floor( transitionTime - gameTime ) );
    }
    $.Schedule( 0.1, UpdateTimer );
}

function ToggleTimer() {
    if (!bHost) return;
    let launching = Game.GetAutoLaunchEnabled();
    
    if (launching) {
        Game.SetTeamSelectionLocked( true );
        Game.SetAutoLaunchEnabled( false );
        Game.SetRemainingSetupTime( 4 ); 
        ReadyButtonID2.SetHasClass("CancelReady",launching);
        ReadyButtonLabel.text = "CANCEL START";
    } else {
        Game.SetTeamSelectionLocked( false );
        Game.SetRemainingSetupTime( 60 ); 
        Game.SetAutoLaunchDelay( 60 );
        Game.SetAutoLaunchEnabled( true );
        ReadyButtonID2.SetHasClass("CancelReady",launching);
        ReadyButtonLabel.text = "START GAME";
    }
}


(function () {
    forced_mode = CustomNetTables.GetTableValue( "forced_mode","initial" );
    if (forced_mode == undefined) {
        forced_mode = {
            lock_level: -1,
        };
    }
    GameEvents.Subscribe( "dota_player_team_changed", teams_changed );
    GameEvents.Subscribe( "dota_team_player_list_changed", teams_changed );
    GameEvents.Subscribe( "dota_player_selected_custom_team", teams_changed );
    GameEvents.Subscribe( "setting_team_rescale", teams_changed );
    CustomNetTables.SubscribeNetTableListener( "forced_mode" , forced_mode_update );
    const PlayerInfo = Game.GetPlayerInfo( Players.GetLocalPlayer() );
    if (PlayerInfo.player_team_id == 0) {
        $.Schedule(0.1,PreWork);
    } else {
        PreWork2();
    }
    UpdateTimer();
})();