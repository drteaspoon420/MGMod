XMax23Plugin = class({})
_G.XMax23Plugin = XMax23Plugin

function XMax23Plugin:Init()
    --print("[XMax23Plugin] found")
end

function XMax23Plugin:ApplySettings()
    XMax23Plugin.settings = PluginSystem:GetAllSetting("xmas_2023")
    --Towers give mana but you have 0 mana regen elsewhere.
    LinkLuaModifier( "xmas23_day1", "plugin_system/plugins/xmas_2023/modifiers/xmas23_day1", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "xmas23_day2", "plugin_system/plugins/xmas_2023/modifiers/xmas23_day2", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "xmas23_day3", "plugin_system/plugins/xmas_2023/modifiers/xmas23_day3", LUA_MODIFIER_MOTION_NONE )
    LinkLuaModifier( "xmas23_day6", "plugin_system/plugins/xmas_2023/modifiers/xmas23_day6", LUA_MODIFIER_MOTION_NONE )
    --LinkLuaModifier( "xmas23_day5", "plugin_system/plugins/xmas_2023/modifiers/xmas23_day5", LUA_MODIFIER_MOTION_NONE )

    ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        XMax23Plugin:SpawnEvent(event)
    end,nil)
    if XMax23Plugin.settings.day5 then
        ListenToGameEvent("dota_glyph_used", function(event)

            local t = {
                modifier_rune_arcane = 50,
                modifier_rune_doubledamage = 45,
                modifier_rune_extradamage = 45,
                modifier_rune_flying_haste = 22,
                modifier_rune_haste = 22,
                modifier_rune_illusion = 0.1,
                modifier_rune_invis = 45,
                modifier_rune_regen = 30,
                modifier_rune_shield = 75,
                modifier_rune_super_arcane = 50,
                modifier_rune_super_invis = 45,
                modifier_rune_super_regen = 30,
            }

            local s = Toolbox:GetRandomKey(t)
            XMax23Plugin:AddNewModifierToTeam(event.teamnumber,s,{duration = t[s]})

        end,nil)
    end

end

function XMax23Plugin:GameInProgressEvent()
end

function XMax23Plugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit:IsDOTANPC() then return end

    if hUnit:IsRealHero() then
        if XMax23Plugin.settings.day1 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"xmas23_day1",{})
        end
        if XMax23Plugin.settings.day2 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"xmas23_day2",{})
        end
        if XMax23Plugin.settings.day3 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"xmas23_day3",{})
        end
        if XMax23Plugin.settings.day4 then
			Timers:CreateTimer( 0, function()
               hUnit:SetPrimaryAttribute(DOTA_ATTRIBUTE_ALL)
            end)
        end
        if XMax23Plugin.settings.day6 then
            local hModifier = hUnit:AddNewModifier(hUnit,nil,"xmas23_day6",{})
        end
    end
end

function XMax23Plugin:AddNewModifierToTeam(iTeam,sMod,tData)
    local iTeam = iTeam or -1
    local e = Entities:Next(nil)
    while e do
        if e.IsBaseNPC and e:IsBaseNPC() then
            if iTeam == -1 or (e.GetTeam and e:GetTeam() == iTeam) then
                local hModifier = e:AddNewModifier(e,nil,sMod,tData)
            end
        end
        e = Entities:Next(e)
    end
end