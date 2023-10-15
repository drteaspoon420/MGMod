if Toolbox == nil then
    print ( '[Toolbox] creating Toolbox' )
    Toolbox = {}
    Toolbox.__index = Toolbox
end

function Toolbox:new( o )
    o = o or {}
    setmetatable( o, Toolbox )
    return o
  end

function Toolbox:_xpcall (f, ...)
    print(f)
    print({...})
    PrintTable({...})
    local result = xpcall (function () return f(unpack(arg)) end,
        function (msg)
        -- build the error message
        return msg..'\n'..debug.traceback()..'\n'
        end)

    print(result)
    PrintTable(result)
    if not result[1] then
        -- throw an error
    end
    -- remove status code
    table.remove (result, 1)
    return unpack (result)
end

function Toolbox:Init()
    Toolbox = self
    self.data = {}
end

function Toolbox:split (inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

function Toolbox:string_starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end


function Toolbox:GetHostId()
	for p=0,DOTA_MAX_PLAYERS do
		local player = PlayerResource:GetPlayer(p)
		if player ~= nil then
			if GameRules:PlayerHasCustomGameHostPrivileges(player) then return p end
		end
	end
	return 0
end

function Toolbox:IsHost(iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if hPlayer == nil then return false end
    return GameRules:PlayerHasCustomGameHostPrivileges(hPlayer)
end

--returns false if ability failed to create a handle.
function Toolbox:ReplaceAbility(hUnit,sAbility,iLevel,iSlot,bForce,bRequirePoints)
	if hUnit then
		local bAdded = false
		local i = 0
        local hExistingAbility = hUnit:FindAbilityByName(sAbility)
        if hExistingAbility ~= nil then
            if hUnit.GetAbilityPoints ~= nil then
                if hUnit:GetAbilityPoints() > 0 then
                    iLevel = 1
                    hUnit:SetAbilityPoints(hUnit:GetAbilityPoints()-1)
                end
            else
                if iLevel == 0
                    then iLevel = 1
                end
            end
            if iLevel > 0 then
                if hExistingAbility:GetLevel() + iLevel > hExistingAbility:GetMaxLevel() then
                    if hExistingAbility:GetLevel() ~= hExistingAbility:GetMaxLevel() then
                        hExistingAbility:SetLevel(hExistingAbility:GetMaxLevel())
                    end
                else
                    hExistingAbility:SetLevel(hExistingAbility:GetLevel()+iLevel)
                end
            end
            if bForce then
                hExistingAbility:SetActivated(true)
                hExistingAbility:SetHidden(false)
            end
            return true
        end
        local iSkip = -1
        while (iSkip == -1 and i < DOTA_MAX_ABILITIES) do
            local hAbility = hUnit:GetAbilityByIndex(i)
            local sOldAbility = hAbility:GetAbilityName()
            if not Toolbox:string_starts(sOldAbility,"special_bonus_") then
                iSkip = i
            end
            i = i + 1
        end
        local hOldAbility = hUnit:GetAbilityByIndex(iSkip+iSlot)
        local sOldAbility
        local iOldAbility
        if hOldAbility ~= nil then 
            sOldAbility = hOldAbility:GetAbilityName()
            iOldAbility = hOldAbility:GetLevel()

            if hOldAbility then
                if iOldAbility > 0 then
                    if hUnit:IsRealHero() then
                        hUnit:SetAbilityPoints(hUnit:GetAbilityPoints()+iOldAbility)
                    end
                end
                hUnit:RemoveAbilityByHandle(hOldAbility)
            end
        end
        local hAbility = hUnit:AddAbility(sAbility)
        if hAbility ~= nil then
            hAbility:SetLevel(iLevel)
            if bForce then
                hAbility:SetActivated(true)
                hAbility:SetHidden(false)
            end
        else
            --return old ability
            if sOldAbility ~= nil then
                hAbility = hUnit:AddAbility(sOldAbility)
                if hAbility ~= nil then
                    hAbility:SetLevel(iOldAbility)
                end
            end
            return false
        end
	end
    return true
end

function Toolbox:SRandomInt(seed,min,max)
    return math.floor((Toolbox:Rng(seed)*(max-min))+min+0.5)
end

function Toolbox:SRandomFloat(seed,min,max)
    return (Toolbox:Rng(seed)*(max-min))+min
end

function Toolbox:GetSRandomKey(seed,t)
    local ti = {}
    for k,v in pairs(t) do
		if v ~= nil then
            table.insert(ti,k)
        end
    end
    if #ti == 0 then return nil end
    return ti[Toolbox:SRandomInt(seed,1, #ti)]
end

function Toolbox:GetRandomKey(t)
    local ti = {}
    for k,v in pairs(t) do
		if v ~= nil then
            table.insert(ti,k)
        end
    end
    if #ti == 0 then return nil end
    return ti[RandomInt(1, #ti)]
end

function Toolbox:GetRandomValue(t)
    return t[Toolbox:GetRandomKey(t)]
end


function Toolbox:FindUnit(sName,hUnit)
    local e = Entities:Next(hUnit)
    while e do
        if e.GetUnitName then
            local sUnitName = e:GetUnitName()
            if sUnitName == sName then
                return e
            end
        end
        e = Entities:Next(e)
    end
end
function Toolbox:table_contains(table, element)
    for _, value in pairs(table) do
        if value == element then
        return true
        end
    end
    return false
end


function Toolbox:IsEmpty(t)
    if not next(t) then
        return true
    end
    return false
end


function Toolbox:GetTeamLeader(iTeam)
	for p=0,DOTA_MAX_PLAYERS do
		local player = PlayerResource:GetPlayer(p)
		if player ~= nil then
            if player:GetTeamNumber() == iTeam then return p end
		end
	end
	return -1
end

local buildings = {
	"npc_dota_tower",
	"ent_dota_fountain",
	"npc_dota_barracks",
	"npc_dota_fort",
	"npc_dota_filler",
}

function Toolbox:AllBuildings()
	local buildings = {}
	for _,towerName in ipairs(buildings) do
		local tbuildings = Entities:FindAllByClassname(towerName)
		for __, building in pairs(tbuildings) do
			table.insert(buildings, building)
		end
	end

	return buildings
end

function Toolbox:AllTowers()
	local buildings = {}
    local tbuildings = Entities:FindAllByClassname("npc_dota_tower")
    for __, building in pairs(tbuildings) do
        table.insert(buildings, building)
    end
	return buildings
end

function Toolbox:ContainsValue(t,val)
    for k,v in pairs(t) do
		if v ~= nil and v == val then
            return true
        end
    end
    return false
end

function Toolbox:ContainsKey(t,key)
    for k,v in pairs(t) do
		if k ~= nil and k == key then
            return true
        end
    end
    return false
end


function Toolbox:ContainsSubValue(t,val,subkey)
    for k,v in pairs(t) do
		if v ~= nil and v[subkey] ~= nil and v[subkey] == val then
            return true
        end
    end
    return false
end
function Toolbox:GetSteamID(iPlayer)
    local steamid = tostring(PlayerResource:GetSteamID(iPlayer))
    if steamid == "0" then
        return iPlayer .. "_1234bot"
    end
    return steamid .. ""
end

function Toolbox:SeedToNumber(seed)
    local total = 0
    for i = 1, #seed do
        total = total + string.byte(string.sub(seed,i,i))
    end
    return total
end

local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
function rand(X1,X2)
    local U = X2*A2
    local V = (X1*A2 + X2*A1) % D20
    V = (V*D20 + U) % D40
    X1 = math.floor(V/D20)
    X2 = V - X1*D20
    return {X1,X2,V/D40}
end

--not for use with every frame, use sparingly
function Toolbox:Rng(seed)
    if Toolbox.rng_generators == nil then Toolbox.rng_generators = {} end
    if Toolbox.rng_generators[seed] == nil then
        local seed_i = Toolbox:SeedToNumber(seed)
        local _X1 = seed_i%D20
        if _X1 % 2 == 1 then _X1 = _X1 + 1 end
        local _X2 = seed_i%D40
        if _X2 % 2 == 0 then _X2 = _X2 + 1 end
        Toolbox.rng_generators[seed] = {
            X1 = _X1,
            X2 = _X2
        }
    end
    local m = rand(Toolbox.rng_generators[seed].X1,Toolbox.rng_generators[seed].X2)
    Toolbox.rng_generators[seed].X1 = m[1]
    Toolbox.rng_generators[seed].X2 = m[2]
    return m[3]
end

if not Toolbox.data then Toolbox:Init() end