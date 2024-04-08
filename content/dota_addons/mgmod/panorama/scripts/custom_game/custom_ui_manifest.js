
HidePickScreen();

function HidePickScreen() {
    if (!Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP)) {
        FindDotaHudElement("PreGame").style.opacity = "0";
        $.Schedule(1.0, HidePickScreen)
    }
    else {
        FindDotaHudElement("PreGame").style.opacity = "1";
    }
}