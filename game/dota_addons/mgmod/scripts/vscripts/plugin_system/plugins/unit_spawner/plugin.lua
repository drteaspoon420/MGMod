UnitSpawnerPlugin = class({})
_G.UnitSpawnerPlugin = UnitSpawnerPlugin
UnitSpawnerPlugin.npc_units = {}
UnitSpawnerPlugin.npc_units_custom = {}

UnitSpawnerPlugin.available_units = {
    basic = {},
}


function UnitSpawnerPlugin:Init()
    print("[UnitSpawnerPlugin] found")
end

function UnitSpawnerPlugin:PreGameStuff()
    local bBuiltin = PluginSystem:GetSetting("unit_spawner","dota_units") or 0
    local bCustom = PluginSystem:GetSetting("unit_spawner","custom_units") or 0

	local file = LoadKeyValues('scripts/npc/npc_units.txt')
    if not (file == nil or not next(file)) then
        UnitSpawnerPlugin.npc_units = file
    end
	local file_custom = LoadKeyValues('scripts/npc/npc_units_custom.txt')
    if not (file_custom == nil or not next(file_custom)) then
        UnitSpawnerPlugin.npc_units_custom = file_custom
    end
    if bBuiltin == 1 then
        for k,v in pairs(UnitSpawnerPlugin.npc_units) do
            if v ~= nil and type(v) == 'table' then
                UnitSpawnerPlugin:AddBasic(k,v)
            end 
        end
    end
    if bCustom == 1 then
        for k,v in pairs(UnitSpawnerPlugin.npc_units_custom) do
            if v ~= nil and type(v) == 'table' then
                if UnitSpawnerPlugin.npc_units[k] == nil then
                    UnitSpawnerPlugin:AddBasic(k,v)
                end
            end 
        end
    end
    UnitSpawnerPlugin:AllDonePreping()
end

function UnitSpawnerPlugin:AddBasic(sAbility,data)
    table.insert(UnitSpawnerPlugin.available_units.basic,sAbility)
end

function UnitSpawnerPlugin:AllDonePreping()
    CustomGameEventManager:RegisterListener("add_basic_unit",UnitSpawnerPlugin.GiveUnitUnit)
    UnitSpawnerPlugin:PaginateSend(UnitSpawnerPlugin.available_units.basic,"add_basic_unit")
end

function UnitSpawnerPlugin:PaginateSend(t,event_name)
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
                unit = current_page,
                event = event_name,
            }
            CustomNetTables:SetTableValue("unit_registery",event_name .. "_" .. current_page_index,rt)
            current_page = {}
        end
    end
    if #current_page > 0 then
        current_page_index = current_page_index + 1
        local rt = {
            target = "entindex",
            unit = current_page,
            event = event_name,
        }
        CustomNetTables:SetTableValue("unit_registery",event_name .. "_" .. current_page_index,rt)
    end
end


function UnitSpawnerPlugin:GiveUnitUnit(tEvent)
    local iPlayer = tEvent.PlayerID
    local hUnit = EntIndexToHScript(tEvent.target)
    local sUnit = tEvent.unit

    local bLimited = PluginSystem:GetSetting("unit_spawner","limited_mode")
    if bLimited and bLimited == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        if hUnit:GetTeam() ~= iTeam then return end
        local iController = hUnit:GetMainControllingPlayer()
        if not (iController == -1 or iController == iPlayer) then return end
    end

    local vPos = hUnit:GetAbsOrigin()
    local iTeam = hUnit:GetTeam()
    local iOwner = hUnit:GetPlayerOwnerID()
    local hPlayer
    if iOwner > -1 then
        hPlayer = PlayerResource:GetPlayer(iOwner)
    end
    local iController = hUnit:GetMainControllingPlayer()
    CreateUnitByNameAsync(sUnit,vPos, false, hUnit, hUnit, iTeam,
    function (hNewUnit)
        if hNewUnit == nil then
            UnitSpawnerPlugin:SendMessage(iPlayer,"invalid unit",sUnit)
            return
        end
        if iController > -1 then
		    hNewUnit:SetControllableByPlayer(iController, true)
        end
        if hPlayer ~= nil then
            local hOwnerHero = hPlayer:GetAssignedHero()
            if hOwnerHero ~= nil then
		        hNewUnit:SetOwner(hOwnerHero)
            end
        end
        if hNewUnit:IsBuilding() then
            FindClearSpaceForUnit(hUnit,vPos,true)
        else
            FindClearSpaceForUnit(hNewUnit,vPos,true)
        end
    end)
end

function UnitSpawnerPlugin:SendMessage(iPlayer,sMessage,sSubject)
    --ShowCustomHeaderMessage(sMessage .. " " .. sSubject,iPlayer,0,2.0)
    --DebugScreenTextPretty( 140, 640, 0,  sMessage .. " " .. sSubject, 255, 0, 0, 255, 5.0, "arial", 30, false )
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer ~= nil then
        CustomGameEventManager:Send_ServerToPlayer(hPlayer,"unit_spawner_error",{unit = sSubject})
    end
end
