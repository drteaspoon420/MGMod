AbilityPlusPlugin = class({})
_G.AbilityPlusPlugin = AbilityPlusPlugin
AbilityPlusPlugin.settings = {}
AbilityPlusPlugin.unit_cache = {}
AbilityPlusPlugin.core_abilities = {}

function AbilityPlusPlugin:Init()
    --print("[AbilityPlusPlugin] found")
end

function AbilityPlusPlugin:ApplySettings()
    AbilityPlusPlugin.settings = PluginSystem:GetAllSetting("ability_plus")
    LinkLuaModifier( "modifier_ability_link", "plugin_system/plugins/ability_plus/modifier_ability_link", LUA_MODIFIER_MOTION_NONE )
    AbilityPlusPlugin:load_abilities()
    ListenToGameEvent("dota_player_gained_level", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        AbilityPlusPlugin:Debug(event)
    end,nil)
    for i=0,24 do
        Toolbox:SpawnTestDummy(i)
    end
end

function AbilityPlusPlugin:GenerateOffers(tCompare)
    local tPossible = {}
    for sAbility,tBehav in pairs(AbilityPlusPlugin.core_abilities) do
        for i,n in pairs(tCompare) do
            if n ~= 0 then
                if Toolbox:table_contains(tBehav,n) then
                    table.insert(tPossible,sAbility)
                    break
                end
            end
        end
    end
    return tPossible
end

function AbilityPlusPlugin:Debug(event)
    local hUnit = EntIndexToHScript(event.hero_entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        if hUnit:GetAbilityPoints() < 1 then
            return
        end
        for i=0,5 do
            local hAbility = hUnit:GetAbilityByIndex(i)
            if hAbility ~= nil and not hAbility:IsHidden() and hAbility:GetLevel() < 1 and hAbility:CanAbilityBeUpgraded() and hAbility:GetHeroLevelRequiredToUpgrade() <= hUnit:GetLevel() then
                hAbility:SetLevel(1)
                hUnit:SetAbilityPoints(hUnit:GetAbilityPoints()-1)
                AbilityPlusPlugin:DotheDebug(hAbility)
                return
            end
        end
    end
end

function AbilityPlusPlugin:DotheDebug(hAbility)
    local sName = hAbility:GetAbilityName()
    local tBehav = AbilityPlusPlugin.core_abilities[sName]
    if tBehav ~= nil then
        local tOffers = AbilityPlusPlugin:GenerateOffers(tBehav)
        local sAbility = Toolbox:GetRandomValue(tOffers)
        local iPlayer = hAbility:GetCaster():GetPlayerOwnerID();
        if not Toolbox:TestDummy(sAbility,iPlayer) then
            AbilityPlusPlugin:DotheDebug(hAbility)
            return
        end
        if not AbilityPlusPlugin:AddAbility(hAbility,sAbility) then
            AbilityPlusPlugin:DotheDebug(hAbility)
            return
        end
        --print("ability linking")
        --print(sName)
        --print(sAbility)
    end
end

function AbilityPlusPlugin:AddAbility(hHostAbility,sNewAbility)
    local hParent = hHostAbility:GetCaster()
    local hNewAbility = hParent:AddAbility(sNewAbility)
    if hNewAbility == nil then return false end
    hNewAbility:SetHidden(true)
    local hMod = hParent:AddNewModifier(hParent,hHostAbility,"modifier_ability_link",{})
    hMod:SetLink(hNewAbility)
    return true
end

function AbilityPlusPlugin:BehaviourExtract(sBehav)
    local t = Toolbox:split(sBehav," | ")
    local l = {}
    for i=1,#t do
        if _G[t[i]] ~= nil then
            table.insert(l,_G[t[i]])
        end
    end
    return l
end
    
function AbilityPlusPlugin:load_kv_file_headers(file)
    local t = {}
    for k,v in pairs(file) do
        if type(v) == "table" then
            if v.AbilityBehavior ~= nil then
                if string.find("special_",k) == nil then
                    t[k] = AbilityPlusPlugin:BehaviourExtract(v.AbilityBehavior)
                end
            end
        end
    end
    return t
end

function AbilityPlusPlugin:load_kv_file_headers_custom(file)
    local t = {}
    for k,v in pairs(file) do
        if type(v) == "table" then
            if v.CustomList ~= nil then --some 
                if v.AbilityBehavior ~= nil then
                    if string.find("special_",k) == nil then
                        t[k] = AbilityPlusPlugin:BehaviourExtract(v.AbilityBehavior)
                    end
                end
            end
        end
    end
    return t
end


function AbilityPlusPlugin:load_abilities()
    AbilityPlusPlugin.core_abilities = {}
--[[ 	local file = LoadKeyValues('scripts/npc/npc_abilities.txt')
    if not (file == nil or not next(file)) then
        AbilityPlusPlugin.core_abilities = Toolbox:PatchTable(AbilityPlusPlugin.core_abilities,AbilityPlusPlugin:load_kv_file_headers(file))
    end ]]
	local heroes_enabled = LoadKeyValues('scripts/npc/activelist.txt')
    if not (heroes_enabled == nil or not next(heroes_enabled)) then
        for k,v in pairs(heroes_enabled) do
            local file = LoadKeyValues('scripts/npc/heroes/' .. k .. '.txt')
            if not (file == nil or not next(file)) then
                AbilityPlusPlugin.core_abilities = Toolbox:PatchTable(AbilityPlusPlugin.core_abilities,AbilityPlusPlugin:load_kv_file_headers(file))
            end
        end
    end
    
--[[ 	local file_custom = LoadKeyValues('scripts/npc/npc_abilities_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        AbilityPlusPlugin.core_abilities = Toolbox:PatchTable(AbilityPlusPlugin.core_abilities,AbilityPlusPlugin:load_kv_file_headers_custom(file_custom))
    end ]]
end
