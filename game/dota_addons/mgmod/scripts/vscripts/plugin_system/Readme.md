# Plugin System
This is the core of the mode. By design, every feature in this mode should bed encapculated into a plugin and be possible to be disabled.

## Plugin
Each plugin should have 'plugin.lua', 'plugin.txt' and 'settings.txt' files.
Also each plugin should be linked from the 'plugins.txt' of this folder:
```
#base "plugins/example_plugin/plugin.txt"
```
### plugin.txt
This file contains details that the plugin system will look for in your plugin.lua and when to make use of various functions you code. Example bellow:
```
"example_plugin" {
    "MainClass" "ExamplePlugin"
    "InitFunction" "Init"
    "StateRegistrations" {
        "PreGameStuff" "DOTA_GAMERULES_STATE_HERO_SELECTION" 
    }
    "FilterRegistrations" {
        "ExampleDamageFilter" "DamageFilter"
    }
    "CmdRegistrations" {
        "-test" "TestCmd"
    }
}
```
#### MainClass
The class object your plugin lives in.
#### InitFunction
This is called as soon as server loads the setup screen. This is called before lobby settings are final, NEVER do anything irreversible to player experience here.
#### StateRegistrations
You can register functions to be called at specific game states. [reference](https://moddota.com/api/#!/vscripts/DOTA_GameState)
Soonest you can use this is the `DOTA_GAMERULES_STATE_HERO_SELECTION` as it's the first state after host has selected settings.
In the example the plugin system will attempt to call `ExamplePlugin:PreGameStuff()` when hero selection starts.
#### FilterRegistrations
This kv block is for filters. The function you register here should return table of two values `{true, event}`, first value is for allowing the event to continue. return `false` if you want to completely halt the event from happening. second value is just the event table with your possible modifications to it.
Available filters:
* AbilityTuningValueFilter
* BountyRunePickupFilter
* DamageFilter
* ExecuteOrderFilter
* HealingFilter
* ItemAddedToInventoryFilter
* ModifierGainedFilter
* ModifyExperienceFilter
* ModifyGoldFilter
* RuneSpawnFilter
* TrackingProjectileFilter

#### CmdRegistrations
These are simple chat commands. The functin recieves three arguments. First is table of arguments/parameters user had after the command. Second is boolean value for team chat, if it was in all chat this is `false`. Third is the player id of the person using the chat command. 

### plugin.lua
This file should have:
A globally accessible class.
```
ExamplePlugin = class({})
_G.ExamplePlugin = ExamplePlugin
```
Also include any functions referenced in your StateRegistrations block. You can have any number of these.
You can also include an init function as referenced in the plugins.txt entry.
```
function ExamplePlugin:Init()
    print("[ExamplePlugin] found, we should arrive to custom game setup soon.")
end

function ExamplePlugin:PreGameStuff()
    print("[ExamplePlugin] hero selection has started")
end
```
If you added anything in 'FilterRegistrations' block, you also need to have those in your plugin script. Here is example damage filter.
```
function ExamplePlugin:ExampleDamageFilter(event)
--[[
    local attackerUnit = event.entindex_attacker_const and EntIndexToHScript(event.entindex_attacker_const)
	local damageType = event.damagetype_const
	local damage = event.damage
	local victimUnit = event.entindex_victim_const and EntIndexToHScript(event.entindex_victim_const)
 ]]
    event.damage = event.damage * 2
    return {true,event}
end
```
NOTE: we return table of two values. First is boolean, usually in filters this means the event can continue, if you want to cancel the event, have this be false instead. Second value is the event, any modifications to this is passed along to each plugin that has registered it and is enabled then finally event is processed.


If you added anything in 'CmdRegistrations' block, you also need to have those in your plugin script. These are 'chat' command. Here is example command.
```
function ExamplePlugin:TestCmd(tArgs,bTeam,iPlayer)
    print("this cmd was used in team chat? " .. bTeam)
    print("this cmd was used by player: " .. iPlayer)
    print("this cmd had following arguments:")
    DeepPrintTable(tArgs)
end
```

### settings.txt
Should contain the settings made available for players.
```
"plugin_settings"
{
    "Order" "1337"
    "enabled" {
        "TYPE" "boolean"
        "DEFAULT" "1"
    }
    "chance_to_do_a_thing"
    {
        "Order" "0"
        "TYPE" "number"
        "UNIT" "%"
        "DEFAULT" "100"
    }
    "time_before_a_cool_thing_happens"
    {
        "Order" "1"
        "TYPE" "number"
        "UNIT" "s"
        "DEFAULT" "120"
    }
}
```
If 'enabled' setting is not provided, it is auto created and set to 0 by default.
If 'Order' value is provided for whole settings, it should show up hopefully at wanted order in the plugin selection. 0 is reserved for 'Dota Settings'
'Order' value can also be used for the internal order of the settings. otherwise they appear in random order. If two settings have same 'Order' it will have conflict and not show up at all.

## Mutators
Mutators are more like collection of mini-presets. the `/mutators/main.txt` contains just link kv file to other files to keep the orginzation bit easier.
Each mutator has `settings` block where you add every setting you want to change for every plugin you want.
Optionally you can make use of 'tags' to make sure the mutator does not cause issues with others.

### add_tags
If your mutator does something but does not care if someone else did it already, but just makes sure all next mutators know about it. `add_tags` is space delimited string of tags you want to add. `mutator_delete_towers` mutator uses this to inform others with `no_towers` tag that there are no towers. so any mutators that may add or change towers know that they don't exits and there for useless or invalid.

### no_tags
If mutator wants to make sure some tag is not added. `no_tags` is space delimited string of tags you want to avoid. `mutator_tower_huggers` use this to make sure `no_towers` is not added because it requires towers to work.

### overlap_tags
If mutator does something that can only be done at same time by only one mutator you can use this. For example `mutator_boosted` and `mutator_nurgle` both make use of overriding KV values of abilities and items. This may cause weird issues or crashes so `overlap_tags` checks if the tag exists, if not then add it adds it and continues. otherwise it will not apply itself to avoid conflict.