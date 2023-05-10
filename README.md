# MGMod
MGMod for Dota 2. A little project to make modular experience of dota 2. Each module or 'plugin' should be self contained 'thing' and if left disabled should clean itself up from UI, etc.

## Plugin System
Core of the MGMod.
More info on plugin system at `game/dota_addons/mgmod/scripts/vscripts/plugin_system/Readme.md`

## Usage Guide
In Accordance to MIT Licence.

## Contribution Guide
Anyone is welcome to contribute if they are willing to contribute under MIT Licence.
### General
General improves to UI, script utility functions etc. are welcome, but will get curated. Not sure how to define guidelines here.
Inclusion of TypeScript or other XYZLanguage -> Lua transcompiling is not welcome. This project does not need extra complexity in it's stack that requires maintanance.
### Plugins
Plugin Contributions are absolutely welcome. Each plugin needs to follow simple rules:
- No side effects! If the plugin is disabled, it should not do anything. Init function is always called at custom game settings screen. the `StateRegistrations` and `CmdRegistrations` are not called at all if your plugin is disabled.
- Cleanup UI when disabled! If you add UI for the plugin in the panorama's `custom_ui_manifest.xml` make sure you disable it if your plugin is disabled. Fetch your plugin settings from the `plugin_settings` net table and check `.enabled.VALUE == 0` and remove/hide your UI.
### Base Game KV Overrides
No! Any overrides are strictly forbiden. If you want to use this for your own `Dota 2 But...` mode, Fork this.
If all plugins are disabled, the game should resemble the normal Dota 2 as closely as possible.

### Abilities
Contributions welcome. Try to keep it lua driven abilities. Keeping your contributions in your own folder named after you "the author" with ability names also either disntinc or containing your author name.
ex. `drteaspoon_multicast` in folder `/abilities/drteaspoon/multicast/`

### Items
Contributions welcome only if left unpurchable. Even if item is not added to the shop they are still visibile when searched and may cause crashes in some cases.
TODO: I want to create custom shop UI for custom items at some point. Possibly mode/setting on the item sandbox.

### Units
Sure!
