# Setting up your dev enviorment on windows.
Replace the paths to your dota 2 and cloned repo.
```
mklink /J "E:\SteamLibrary\steamapps\common\dota 2 beta\content\dota_addons\mgmod" "E:\GitHub\MGMod\content\dota_addons\mgmod"
mkdir "E:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\mgmod"
mklink /J "E:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\mgmod\scripts" "E:\GitHub\MGMod\game\dota_addons\mgmod\scripts"
mklink /J "E:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\mgmod\resource" "E:\GitHub\MGMod\game\dota_addons\mgmod\resource"
cp "E:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\mgmod\addoninfo.txt" "E:\GitHub\MGMod\game\dota_addons\mgmod\addoninfo.txt"
```
Dota requires that the folder in `game` path is a real folder instead of junction and contains real `addoninfo.txt` rest of the folders can be junctions.
# Starting the map
We don't need copy and build `dota` map. Open console and run `dota_launch_custom_game mgmod dota`. 