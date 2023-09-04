HeroScreenReworkPlugin = class({})
_G.HeroScreenReworkPlugin = HeroScreenReworkPlugin
HeroScreenReworkPlugin.settings = {}

HeroScreenReworkPlugin.heroes = {}
function HeroScreenReworkPlugin:Init()
    print("[HeroScreenReworkPlugin] found")
end

function HeroScreenReworkPlugin:ApplySettings()
    HeroScreenReworkPlugin.settings = PluginSystem:GetAllSetting("heroscreen_rework")
    HeroScreenReworkPlugin:LoadHeroes()
end

function HeroScreenReworkPlugin:LoadHeroes()
    HeroScreenReworkPlugin.heroes = {
        {},		-- strength_heroes
        {},		-- agility_heroes
        {},		-- intelligence_heroes
        {}		-- universal
    }
    local hero_definitions = LoadKeyValues('scripts/npc/npc_heroes.txt')
    local process_hero = function(hero_data,hero_name)
        if hero_data.Enabled ~= 1 then return end
        local hero_attribute = _G[hero_data.AttributePrimary]
        local attribute = hero_attribute + 1
        local tHero = {
            name = hero_name,
            banned = false,
            id = hero_data.HeroID,
        }
        table.insert(HeroScreenReworkPlugin.heroes[attribute], tHero)
    end
    for hero_name,_ in pairs(hero_definitions) do
        if (type(hero_definitions[hero_name]) == "table") then
            if hero_definitions[hero_name].HeroID ~= nil then
                process_hero(hero_definitions[hero_name],hero_name)
            end
        end
    end
    
    
    CustomNetTables:SetTableValue("heroselection_rework", "hero_pools", HeroScreenReworkPlugin.heroes)
end
