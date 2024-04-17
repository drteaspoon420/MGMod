# MGMod
MGMod for Dota 2. A little project to make modular experience of dota 2. Each module or 'plugin' should be self contained 'thing' and if left disabled should clean itself up from UI, etc.

## Plugin System
Core of the MGMod.
More info on plugin system at `game/dota_addons/mgmod/scripts/vscripts/plugin_system/Readme.md`

## Usage Guide
In Accordance to Apache License 2.0

## Contribution Guide
Anyone is welcome to contribute if they are willing to contribute under Apache License 2.0
### General
General improves to UI, script utility functions etc. are welcome, but will get curated. Not sure how to define guidelines here.</br>
Inclusion of TypeScript or other XYZLanguage -> Lua transcompiling is not welcome. This project does not need extra complexity in it's stack that requires maintenance.
### Plugins
Plugin Contributions are absolutely welcome. Each plugin needs to follow simple rules:
- No side effects! If the plugin is disabled, it should not do anything. Init function is always called at custom game settings screen. the `StateRegistrations` and `CmdRegistrations` are not called at all if your plugin is disabled.
- Cleanup UI when disabled! If you add UI for the plugin in the panorama's `custom_ui_manifest.xml` make sure you disable it if your plugin is disabled. Fetch your plugin settings from the `plugin_settings` net table and check `.enabled.VALUE == 0` and remove/hide your UI.
### Base Game KV Overrides
No! Any overrides are strictly forbiden. If you want to use this for your own `Dota 2 But...` mode, Fork this.</br>
If all plugins are disabled, the game should resemble the normal Dota 2 as closely as possible.

### Abilities
Contributions welcome. Try to keep it lua driven abilities. Keeping your contributions in your own folder named after you "the author" with ability names also either distinct or containing your author name.</br>
ex. `drteaspoon_multicast` in folder `/abilities/drteaspoon/multicast/`

### Items
Contributions welcome only if left upurchasable. Even if item is not added to the shop they are still visible when searched and may cause crashes in some cases.
TODO: I want to create custom shop UI for custom items at some point. Possibly mode/setting on the item sandbox.

### Units
Sure!

# Credits
I would like to thank everyone who even in small part, directly or inderectly has contributed to this modes existance. I hope to see more direct contributions to make this coolest dota 2 sandbox where one can play with rules and bend dota into experiences we have yet to try.

## Direct Authors
|Name|Role|
|----|----|
|DrTeaSpoon|Lead Development|
|Abraham Blink'in|Contributor|


## Indirect Authors
Timers Library by bmddota</br>
David Kolf's JSON module for Lua 5.1/5.2 by David Heiko Kolf

## Special thanks
Exposure and Feedback by Baumi and his community.</br>
Help and Support by Mod Dota community. moddota.com <3