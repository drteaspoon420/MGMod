#  Setting up your dev enviorment on windows.
Replace the paths to your dota 2 and cloned repo.
```
mklink /J "D:\SteamLibrary\steamapps\common\dota 2 beta\content\dota_addons\mgmod" "D:\GitHub\MGMod\content\dota_addons\mgmod"
mkdir "D:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\mgmod"
mklink /J "D:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\mgmod\scripts" "D:\GitHub\MGMod\game\dota_addons\mgmod\scripts"
mklink /J "D:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\mgmod\resource" "D:\GitHub\MGMod\game\dota_addons\mgmod\resource"
cp "D:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\mgmod\addoninfo.txt" "D:\GitHub\MGMod\game\dota_addons\mgmod\addoninfo.txt"
```
Dota requires that the folder in `game` path is a real folder instead of junction and contains real `addoninfo.txt` rest of the folders can be junctions.