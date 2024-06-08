ModifierSpawnerPlugin = class({})
_G.ModifierSpawnerPlugin = ModifierSpawnerPlugin
ModifierSpawnerPlugin.npc_modifiers = {}
ModifierSpawnerPlugin.npc_modifiers_custom = {}


ModifierSpawnerPlugin.available_modifiers = {
    basic = {},
}

function ModifierSpawnerPlugin:Init()
    print("[ModifierSpawnerPlugin] found")
end

function ModifierSpawnerPlugin:PreGameStuff()
    local bBuiltin = PluginSystem:GetSetting("modifier_spawner","dota_modifiers") or 0
    local bCustom = PluginSystem:GetSetting("modifier_spawner","custom_modifiers") or 0
    
	local file = LoadKeyValues('scripts/vscripts/plugin_system/plugins/modifier_spawner/modifiers_22052024  .txt')
    if not (file == nil or not next(file)) then
        ModifierSpawnerPlugin.npc_modifiers = file
    end
	local file_custom = LoadKeyValues('scripts/vscripts/plugin_system/plugins/modifier_spawner/modifiers_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        ModifierSpawnerPlugin.npc_modifiers_custom = file_custom
    end

    if bBuiltin == 1 then
        for k,v in pairs(ModifierSpawnerPlugin.npc_modifiers) do
            if v ~= nil then
                if type(v) == 'table' then
                    ModifierSpawnerPlugin:AddBasic(k,v)
                else
                    ModifierSpawnerPlugin:AddBasic(k,{})
                end
            end 
        end
    end

    if bCustom == 1 then
        for k,v in pairs(ModifierSpawnerPlugin.npc_modifiers_custom) do
            if v ~= nil then
                if type(v) == 'table' then
                    ModifierSpawnerPlugin:AddBasic(k,v)
                else
                    ModifierSpawnerPlugin:AddBasic(k,{})
                end
            end 
        end
    end
    ModifierSpawnerPlugin:AllDonePreping()
end

function ModifierSpawnerPlugin:AddBasic(sAbility,data)
    if data.file ~= nil then
        local modtype = data.modtype or LUA_MODIFIER_MOTION_NONE
        LinkLuaModifier(sAbility,data.file,modtype)
    end
    table.insert(ModifierSpawnerPlugin.available_modifiers.basic,sAbility)
end

function ModifierSpawnerPlugin:AllDonePreping()
    CustomGameEventManager:RegisterListener("add_basic_modifier",ModifierSpawnerPlugin.GiveUnitModifier)
    ModifierSpawnerPlugin:PaginateSend(ModifierSpawnerPlugin.available_modifiers.basic,"add_basic_modifier")
end

function ModifierSpawnerPlugin:PaginateSend(t,event_name)
    table.sort(t)
    local page_size = 20
    local current_page = {}
    local current_page_index = 0;
    local current_size = 0
    for k,v in pairs(t) do
        table.insert(current_page,v)
        current_size = current_size + 1
        if current_size > page_size then
            current_page_index = current_page_index + 1
            current_size = 0
            local rt = {
                target = "entindex",
                modifier = current_page,
                event = event_name,
            }
            CustomNetTables:SetTableValue("modifier_registery",event_name .. "_" .. current_page_index,rt)
            current_page = {}
        end
    end
    if #current_page > 0 then
        current_page_index = current_page_index + 1
        local rt = {
            target = "entindex",
            modifier = current_page,
            event = event_name,
        }
        CustomNetTables:SetTableValue("modifier_registery",event_name .. "_" .. current_page_index,rt)
    end
end


function ModifierSpawnerPlugin:GiveUnitModifier(tEvent)
    local iPlayer = tEvent.PlayerID
    local hUnit = EntIndexToHScript(tEvent.target)
    local sModifier = tEvent.modifier
    local sData = tEvent.data

    local bLimited = PluginSystem:GetSetting("modifier_spawner","limited_mode")
    if bLimited and bLimited == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        if hUnit:GetTeam() ~= iTeam then return end
        local iController = hUnit:GetMainControllingPlayer()
        if not (iController == -1 or iController == iPlayer) then return end
    end

    local ok = ModifierSpawnerPlugin:AddModifier(hUnit,sModifier,sData,iPlayer)
    if not ok then
        ModifierSpawnerPlugin:SendMessage(iPlayer,"invalid modifier",sModifier)
        return
    end
end

function ModifierSpawnerPlugin:SendMessage(iPlayer,sMessage,sSubject)
    --ShowCustomHeaderMessage(sMessage .. " " .. sSubject,iPlayer,0,2.0)
    --DebugScreenTextPretty( 140, 640, 0,  sMessage .. " " .. sSubject, 255, 0, 0, 255, 5.0, "arial", 30, false )
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer ~= nil then
        CustomGameEventManager:Send_ServerToPlayer(hPlayer,"modifier_spawner_error",{modifier = sSubject})
    end
end

function ModifierSpawnerPlugin:AddModifier(hUnit,sModifier,sData,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then
        print("hPlayer nil?",iPlayer)
        return true
    end
    local hHero = hPlayer:GetAssignedHero()
    if hHero == nil then
        print("hHero nil?",iPlayer)
        return true
    end
    local hAbility
    local i = 0
    local bFound = false
    while (not bFound and i < DOTA_MAX_ABILITIES) do
        hAbility = hHero:GetAbilityByIndex(i)
        if hAbility then
            bFound = true
        end
        i = i + 1
    end
    if hAbility == nil then
        print("hAbility nil?",iPlayer)
        return true
    end

    local kv = Toolbox:split(sData,",")
    local data = {}
    for k,v in pairs(kv) do
        local o = Toolbox:split(v,"=")
        if #o == 2 then
            o[1] = string.gsub(o[1], "%s+", "")
            o[2] = string.gsub(o[2], "%s+", "")
            if tonumber(o[2]) == nil then
                data[o[1]] = o[2]
            else
                data[o[1]] = tonumber(o[2])
            end
        end
    end
    local hModifier = hUnit:AddNewModifier(hHero,hAbility,sModifier,data)
    return hModifier ~= nil
end