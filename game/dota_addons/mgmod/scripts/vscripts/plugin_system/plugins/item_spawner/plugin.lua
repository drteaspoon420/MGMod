ItemSpawnerPlugin = class({})
_G.ItemSpawnerPlugin = ItemSpawnerPlugin
ItemSpawnerPlugin.npc_items = {}
ItemSpawnerPlugin.npc_items_custom = {}

ItemSpawnerPlugin.player_build = {}
ItemSpawnerPlugin.cache = {}

ItemSpawnerPlugin.available_items = {
    basic = {},
}


function ItemSpawnerPlugin:Init()
    --print("[ItemSpawnerPlugin] found")
end

function ItemSpawnerPlugin:PreGameStuff()
    local bBuiltin = PluginSystem:GetSetting("item_spawner","dota_items") or 0
    local bCustom = PluginSystem:GetSetting("item_spawner","custom_items") or 0

	local file = LoadKeyValues('scripts/npc/items.txt')
    if not (file == nil or not next(file)) then
        ItemSpawnerPlugin.npc_items = file
    end
	local file_custom = LoadKeyValues('scripts/npc/npc_items_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        ItemSpawnerPlugin.npc_items_custom = file_custom
    end
    if bBuiltin == 1 then
        for k,v in pairs(ItemSpawnerPlugin.npc_items) do
            if v ~= nil and type(v) == 'table' then
                ItemSpawnerPlugin:AddBasic(k,v)
            end 
        end
    end
    if bCustom == 1 then
        for k,v in pairs(ItemSpawnerPlugin.npc_items_custom) do
            if v ~= nil and type(v) == 'table' then
                if ItemSpawnerPlugin.npc_items[k] == nil then
                    ItemSpawnerPlugin:AddBasic(k,v)
                end
            end 
        end
    end
    ItemSpawnerPlugin:AllDonePreping()
end

function ItemSpawnerPlugin:AddBasic(sAbility,data)
    table.insert(ItemSpawnerPlugin.available_items.basic,sAbility)
end

function ItemSpawnerPlugin:AllDonePreping()
    CustomGameEventManager:RegisterListener("add_basic_item",ItemSpawnerPlugin.GiveUnitItem)
    ItemSpawnerPlugin:PaginateSend(ItemSpawnerPlugin.available_items.basic,"add_basic_item")
end

function ItemSpawnerPlugin:PaginateSend(t,event_name)
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
                item = current_page,
                event = event_name,
            }
            CustomNetTables:SetTableValue("item_registery",event_name .. "_" .. current_page_index,rt)
            current_page = {}
        end
    end
    if #current_page > 0 then
        current_page_index = current_page_index + 1
        local rt = {
            target = "entindex",
            item = current_page,
            event = event_name,
        }
        CustomNetTables:SetTableValue("item_registery",event_name .. "_" .. current_page_index,rt)
    end
end


function ItemSpawnerPlugin:GiveUnitItem(tEvent)
    local iPlayer = tEvent.PlayerID
    local hUnit = EntIndexToHScript(tEvent.target)
    local sItem = tEvent.item

    local bLimited = PluginSystem:GetSetting("item_spawner","limited_mode")
    if bLimited and bLimited == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        if hUnit:GetTeam() ~= iTeam then return end
        local iController = hUnit:GetMainControllingPlayer()
        if not (iController == -1 or iController == iPlayer) then return end
    end

    local ok = ItemSpawnerPlugin:AddItem(hUnit,sItem)
    if not ok then
        ItemSpawnerPlugin:SendMessage(iPlayer,"invalid item",sItem)
        return
    end
end

function ItemSpawnerPlugin:SendMessage(iPlayer,sMessage,sSubject)
    --ShowCustomHeaderMessage(sMessage .. " " .. sSubject,iPlayer,0,2.0)
    --DebugScreenTextPretty( 140, 640, 0,  sMessage .. " " .. sSubject, 255, 0, 0, 255, 5.0, "arial", 30, false )
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer ~= nil then
        CustomGameEventManager:Send_ServerToPlayer(hPlayer,"item_spawner_error",{item = sSubject})
    end
end

function ItemSpawnerPlugin:AddItem(hUnit,sItem)
    local hItem = hUnit:AddItemByName(sItem)
    return hItem ~= nil
end