CurrenciesPlugin = class({})
_G.CurrenciesPlugin = CurrenciesPlugin

local names = {
    "red",
    "green",
    "blue",
    "purple"
}
local c_states = {
    solo = 0,
    team = 1,
    all = 2
}

function CurrenciesPlugin:Init()
    print("[CurrenciesPlugin] found")
end

function CurrenciesPlugin:ApplySettings()
    CurrenciesPlugin.settings = PluginSystem:GetAllSetting("currencies")

    CurrenciesPlugin.currency_data = {}
    for i=1,#names do
        local c = names[i]
        local sts = CurrenciesPlugin.settings[c .. "_state"]
        if c_states[sts] ~= nil then
            CurrenciesPlugin.currency_data[c] = {}
            CurrenciesPlugin.currency_data[c].amount = {}
            CurrenciesPlugin.currency_data[c].share = c_states[sts]
            CurrenciesPlugin.currency_data[c].spend_options = {}
            CurrenciesPlugin.spend_options[c] = {}
            CurrenciesPlugin.currency_data[c].earn_options = {}
            CurrenciesPlugin.earn_options[c] = {}
            if c_states[sts] == 0 then --solo
                for iPlayer = 0,DOTA_MAX_PLAYERS do
                    if PlayerResource:IsValidPlayer(iPlayer) then
                        CurrenciesPlugin.currency_data[c].amount[iPlayer] = 0
                    end
                end
            elseif c_states[sts] == 1 then --team shared
                CurrenciesPlugin.currency_data[c].amount[DOTA_TEAM_GOODGUYS] = 0
                CurrenciesPlugin.currency_data[c].amount[DOTA_TEAM_BADGUYS] = 0
            elseif c_states[sts] == 2 then --global shared
                CurrenciesPlugin.currency_data[c].amount[0] = 0
            end
            CustomNetTables:SetTableValue("currencies",c,CurrenciesPlugin.currency_data[c])
        end
    end
end

function CurrenciesPlugin:AlterCurrency(sName,iPlayer,iCount)
    if CurrenciesPlugin.currency_data[sName] == nil then return end
    local t = CurrenciesPlugin.currency_data[sName]
    if t.share == 0 then
        t.amount[iPlayer] = t.amount[iPlayer] + iCount
    elseif t.share == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        t.amount[iTeam] = t.amount[iTeam] + iCount
    elseif t.share == 2 then
        t.amount[0] = t.amount[0] + iCount
    end
    CurrenciesPlugin.currency_data[sName] = t
    if not CurrenciesPlugin:CheckForSingleSpendOption(sName,iPlayer) then
        CustomNetTables:SetTableValue("currencies",sName,CurrenciesPlugin.currency_data[sName])
    end
end

function CurrenciesPlugin:SpendCurrency(sName,iPlayer,iCount)
    if CurrenciesPlugin.currency_data[sName] == nil then return false end
    local t = CurrenciesPlugin.currency_data[sName]
    if t.share == 0 then
        if t.amount[iPlayer] < iCount then
            return false
        else
            CurrenciesPlugin:AlterCurrency(sName,iPlayer,-iCount)
            return true
        end
    elseif t.share == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        if t.amount[iTeam] < iCount then
            return false
        else
            CurrenciesPlugin:AlterCurrency(sName,iPlayer,-iCount)
            return true
        end
    elseif t.share == 2 then
        if t.amount[0] < iCount then
            return false
        else
            CurrenciesPlugin:AlterCurrency(sName,iPlayer,-iCount)
            return true
        end
    end
    return false
end

function CurrenciesPlugin:RegisterSpendOption(sName,tOption)
    if tOption.plugin == nil then return end
    if tOption.plugin_name == nil then return end
    if tOption.cost == nil then return end
    if tOption.call_fn == nil then return end
    if tOption.option_name == nil then return end
    local t = {
        plugin_name = tOption.plugin_name,
        cost = tOption.cost,
        option_name = tOption.option_name,
        fn = tOption.plugin_name .. '|' .. tOption.option_name
    }
    CurrenciesPlugin.spend_options[sName][fn] = tOption
    table.insert(CurrenciesPlugin.currency_data[sName].spend_options,t)
end

function CurrenciesPlugin:RegisterEarnOption(sName,tOption)
    if tOption.plugin == nil then return end
    if tOption.plugin_name == nil then return end
    if tOption.cost == nil then return end
    if tOption.call_fn == nil then return end
    if tOption.option_name == nil then return end
    local t = {
        plugin_name = tOption.plugin_name,
        cost = tOption.cost,
        option_name = tOption.option_name,
        fn = tOption.plugin_name .. '|' .. tOption.option_name
    }
    CurrenciesPlugin.earn_options[sName][fn] = tOption
    table.insert(CurrenciesPlugin.currency_data[sName].earn_options,t)
end

function CurrenciesPlugin:UserSpendingOption(iPlayer,sName,fn)
    local t = CurrenciesPlugin.spend_options[sName][fn]
    if t.plugin == nil then return false end
    if t.plugin[call_fn] == nil then return false end
    if CurrenciesPlugin:SpendCurrency(sName,iPlayer,t.cost) then
        t.plugin[call_fn](iPlayer)
        return true
    end
    return false
end

function CurrenciesPlugin:UserEarningOption(iPlayer,sName,fn)
    local t = CurrenciesPlugin.earn_options[sName][fn]
    if t.plugin == nil then return false end
    if t.plugin[call_fn] == nil then return false end
    if t.plugin[call_fn](iPlayer) then
        CurrenciesPlugin:AlterCurrency(sName,iPlayer,t.cost) 
        return true
    end
    return false
end

function CurrenciesPlugin:CheckForSingleSpendOption(sName,iPlayer)
    local c = 0
    local fn
    for k,_ in pairs(CurrenciesPlugin.spend_options[sName]) do
        fn = k
        c = c + 1
    end
    if c == 1 then
        if CurrenciesPlugin:UserSpendingOption(iPlayer,sName,fn) then
            return true
        end
    end
    return false
end