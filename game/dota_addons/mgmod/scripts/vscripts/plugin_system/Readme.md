# Plugin System
This is the core of the mode. By design, every feature in this mode should bed encapculated into a plugin and be possible to be disabled.

## Plugin
Each plugin should have 'plugin.lua' and 'settings.txt' files.
Also each plugin should have entry in the 'plugins.txt' of this folder:
```
"example_plugin" {
    "MainClass" "ExamplePlugin"
    "InitFunction" "Init"
    "StateRegistrations" {
        "PreGameStuff" "DOTA_GAMERULES_STATE_HERO_SELECTION" 
    }
}
```
### plugin.lua
This file should have:
A globally accessible class.
```
ExamplePlugin = class({})
_G.ExamplePlugin = ExamplePlugin
```
Also include any functions referenced in your StateRegistrations block. You can have any number of these.
You can also include an init function as referenced in the plugins.txt entry.
NOTE: `InitFunction` is called before lobby settings are final, NEVER do anything irreversible to player experience here.
```
function ExamplePlugin:Init()
    print("[ExamplePlugin] found, we should arrive to custom game setup soon.")
end

function ExamplePlugin:PreGameStuff()
    print("[ExamplePlugin] hero selection has started")
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
}
```
If 'enabled' setting is not provided, it is auto created and set to 0 by default.
If 'Order' value is provided for whole settings, it should show up hopefully at wanted order in the plugin selection. 0 is reserved for 'Dota'
'Order' value can also be used for the internal order of the settings. otherwise they appear in random order.


##