Wiggle = class({})
_G.Wiggle = Wiggle
Wiggle.hero_stacks = {}

function Wiggle:Init()
    --print("[Wiggle] found")
end

function Wiggle:PreGameStuff()
    local hero_stacks = LoadKeyValues('scripts/vscripts/plugin_system/plugins/wiggle/hero_stacks.txt')
    if not (hero_stacks == nil or not next(hero_stacks)) then
        Wiggle.hero_stacks = hero_stacks
    else
        Wiggle.hero_stacks = {}
    end
end
