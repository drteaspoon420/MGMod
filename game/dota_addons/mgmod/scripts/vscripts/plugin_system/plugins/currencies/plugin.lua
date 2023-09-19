CurrenciesPlugin = class({})
_G.CurrenciesPlugin = CurrenciesPlugin
require("plugin_system/plugins/currencies/rewards")

local names = {
    "red",
    "green",
    "blue",
    "purple"
}
local c_states = {
    solo = 0,
    team = 1,
    all = 2,
    none = 3,
}
local c_colors = {
    red = Vector(255,30,30),
    green = Vector(30,255,30),
    blue = Vector(30,30,255),
    purple = Vector(200,200,30)
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
            CurrenciesPlugin:SecureOptions(c)
            local gold_buy = CurrenciesPlugin.settings[c .. "_gold_buy"]
            print(gold_buy,c,"goldbuy")
            if gold_buy > 0 then
                local gb = math.ceil(gold_buy)
                local j = 1
                print(gold_buy,gb,j)
                while(gb < 99999 and j < 1000000) do
                    CurrenciesPlugin:RegisterEarnOption(c,{
                        plugin = CurrenciesPlugin,
                        plugin_name = "currencies",
                        cost = gb,
                        earn = j,
                        option_name = "buy_" .. j,
                        call_fn = "Earn_" .. j,
                        extra = {cost = gb}
                    })
                    j = j * 10
                    gb = gb * 10
                end
            end
            if c_states[sts] == 0 then --solo
                for iPlayer = 0,DOTA_MAX_PLAYERS do
                    CurrenciesPlugin.currency_data[c].amount[iPlayer] = CurrenciesPlugin.settings[c .. "_start"]
                end
            elseif c_states[sts] == 1 then --team shared
                print(CurrenciesPlugin.settings[c .. "_start"])
                CurrenciesPlugin.currency_data[c].amount[DOTA_TEAM_GOODGUYS] = CurrenciesPlugin.settings[c .. "_start"]
                CurrenciesPlugin.currency_data[c].amount[DOTA_TEAM_BADGUYS] = CurrenciesPlugin.settings[c .. "_start"]
            elseif c_states[sts] == 2 then --global shared
                CurrenciesPlugin.currency_data[c].amount[0] = CurrenciesPlugin.settings[c .. "_start"]
            end
            CustomNetTables:SetTableValue("currencies",c,CurrenciesPlugin.currency_data[c])
        end
    end
    CustomGameEventManager:RegisterListener("currency_spend",CurrenciesPlugin.currency_spend)
    CustomGameEventManager:RegisterListener("currency_earn",CurrenciesPlugin.currency_earn)
    CurrenciesPlugin:RewardsInit()
end

function CurrenciesPlugin:AlterCurrency(sName,iPlayer,iCount)
    if CurrenciesPlugin.currency_data[sName] == nil then return end
    local t = CurrenciesPlugin.currency_data[sName]
    if t.share == 0 then
        if t.amount[iPlayer] == nil then return end
        t.amount[iPlayer] = t.amount[iPlayer] + iCount
    elseif t.share == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        if iTeam == nil or iTeam < 2 then return end
        if  t.amount[iTeam] == nil then
            t.amount[iTeam] = {}
        end
        t.amount[iTeam] = t.amount[iTeam] + iCount
    elseif t.share == 2 then
        t.amount[0] = t.amount[0] + iCount
    end
    CurrenciesPlugin.currency_data[sName] = t
    if not CurrenciesPlugin:CheckForSingleSpendOption(sName,iPlayer) then
        CustomNetTables:SetTableValue("currencies",sName,CurrenciesPlugin.currency_data[sName])
    end
end


function CurrenciesPlugin:CheckCurrency(sName,iPlayer,iCount)
    if CurrenciesPlugin.currency_data[sName] == nil then return false end
    local t = CurrenciesPlugin.currency_data[sName]
    if t.share == 0 then
        if t.amount[iPlayer] < iCount then
            return false
        else
            --CurrenciesPlugin:AlterCurrency(sName,iPlayer,-iCount)
            return true
        end
    elseif t.share == 1 then
        local iTeam = PlayerResource:GetTeam(iPlayer)
        print(iCount,t.amount[iTeam])
        print(type(iCount),type(t.amount[iTeam]))
        if t.amount[iTeam] < iCount then
            return false
        else
            --CurrenciesPlugin:AlterCurrency(sName,iPlayer,-iCount)
            return true
        end
    elseif t.share == 2 then
        if t.amount[0] < iCount then
            return false
        else
            --CurrenciesPlugin:AlterCurrency(sName,iPlayer,-iCount)
            return true
        end
    end
    return false
end

function CurrenciesPlugin:SpendCurrency(sName,iPlayer,iCount)
    print(sName,iPlayer,iCount)
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
        print(iTeam)
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

function CurrenciesPlugin:SecureOptions(sName)
    if CurrenciesPlugin.currency_data == nil then
        CurrenciesPlugin.currency_data = {}
    end
    if CurrenciesPlugin.currency_data[sName] == nil then
        CurrenciesPlugin.currency_data[sName] = {}
    end
    if CurrenciesPlugin.spend_options == nil then
        CurrenciesPlugin.spend_options = {}
    end
    if CurrenciesPlugin.spend_options[sName] == nil then
        CurrenciesPlugin.spend_options[sName] = {}
    end
    if CurrenciesPlugin.currency_data[sName].spend_options == nil then
        CurrenciesPlugin.currency_data[sName].spend_options = {}
    end
    if CurrenciesPlugin.earn_options == nil then
        CurrenciesPlugin.earn_options = {}
    end
    if CurrenciesPlugin.earn_options[sName] == nil then
        CurrenciesPlugin.earn_options[sName] = {}
    end
    if CurrenciesPlugin.currency_data[sName].earn_options == nil then
        CurrenciesPlugin.currency_data[sName].earn_options = {}
    end
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
    CurrenciesPlugin:SecureOptions(sName)
    CurrenciesPlugin.spend_options[sName][t.fn] = tOption
    table.insert(CurrenciesPlugin.currency_data[sName].spend_options,t)
    DeepPrintTable(CurrenciesPlugin.currency_data[sName])
    CustomNetTables:SetTableValue("currencies",sName,CurrenciesPlugin.currency_data[sName])
end

function CurrenciesPlugin:RegisterEarnOption(sName,tOption)
    print("registering",sName,"earn option")
    if tOption.plugin == nil then
        print("plugin not found")
        return
    end
    if tOption.plugin_name == nil then
        print("plugin_name not found")
        return
    end
    if tOption.cost == nil then
        print("cost not found")
        return
    end
    if tOption.earn == nil then
        print("earn not found")
        return
    end
    if tOption.call_fn == nil then
        print("call_fn not found")
        return
    end
    if tOption.option_name == nil then
        print("option_name not found")
        return
    end
    local t = {
        plugin_name = tOption.plugin_name,
        cost = tOption.cost,
        earn = tOption.earn,
        option_name = tOption.option_name,
        fn = tOption.plugin_name .. '|' .. tOption.option_name
    }
    CurrenciesPlugin:SecureOptions(sName)
    CurrenciesPlugin.earn_options[sName][t.fn] = tOption
    table.insert(CurrenciesPlugin.currency_data[sName].earn_options,t)
    DeepPrintTable(CurrenciesPlugin.currency_data[sName])
    CustomNetTables:SetTableValue("currencies",sName,CurrenciesPlugin.currency_data[sName])
end

function CurrenciesPlugin:currency_spend(tEvent)
    local iPlayer = tEvent.PlayerID
    local sName = tEvent.currency
    local fn = tEvent.option
    CurrenciesPlugin:UserSpendingOption(iPlayer,sName,fn)
end

function CurrenciesPlugin:currency_earn(tEvent)
    local iPlayer = tEvent.PlayerID
    local sName = tEvent.currency
    local fn = tEvent.option
    CurrenciesPlugin:UserEarningOption(iPlayer,sName,fn)
end

function CurrenciesPlugin:UserSpendingOption(iPlayer,sName,fn)
    local t = CurrenciesPlugin.spend_options[sName][fn]
    if t.plugin == nil then
        print("invalid plugin")
        return false
    end
    if t.plugin[t.call_fn] == nil then
        print("invalid plugin function",t.call_fn)
        return false
    end
    if CurrenciesPlugin:SpendCurrency(sName,iPlayer,t.cost) then
        local tEvent = {
            iPlayer = iPlayer,
            iShare = CurrenciesPlugin.currency_data[sName].share
        }
        local extra = t.extra or {}
        t.plugin[t.call_fn](t.plugin,tEvent,extra)
        return true
    end
    return false
end

function CurrenciesPlugin:UserEarningOption(iPlayer,sName,fn)
    local t = CurrenciesPlugin.earn_options[sName][fn]
    if t.plugin == nil then
        print("invalid plugin")
         return false 
    end
    if t.plugin[t.call_fn] == nil then
        print("invalid plugin function",t.call_fn)
         return false
    end
    local extra = t.extra or {}
    if t.plugin[t.call_fn](t.plugin,iPlayer,extra) then
        CurrenciesPlugin:AlterCurrency(sName,iPlayer,t.earn) 
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


function CurrenciesPlugin:EarnBase(iPlayer,iGold)
    if PlayerResource:GetGold(iPlayer) < iGold then return false end
    PlayerResource:SpendGold(iPlayer,iGold,DOTA_ModifyGold_PurchaseConsumable)
    return true
end

function CurrenciesPlugin:Earn_1(iPlayer,tExtra)
    return CurrenciesPlugin:EarnBase(iPlayer,tExtra.cost)
end
function CurrenciesPlugin:Earn_10(iPlayer,tExtra)
    return CurrenciesPlugin:EarnBase(iPlayer,tExtra.cost)
end
function CurrenciesPlugin:Earn_100(iPlayer,tExtra)
    return CurrenciesPlugin:EarnBase(iPlayer,tExtra.cost)
end
function CurrenciesPlugin:Earn_1000(iPlayer,tExtra)
    return CurrenciesPlugin:EarnBase(iPlayer,tExtra.cost)
end
function CurrenciesPlugin:Earn_10000(iPlayer,tExtra)
    return CurrenciesPlugin:EarnBase(iPlayer,tExtra.cost)
end
function CurrenciesPlugin:Earn_100000(iPlayer,tExtra)
    return CurrenciesPlugin:EarnBase(iPlayer,tExtra.cost)
end


function CurrenciesPlugin:ShowEarnParticle(iCount,hUnit,iTeam,sCurrency)
    if iCount < 1 then return end
    local iParticle = ParticleManager:CreateParticleForTeam("particles/tickets_gain.vpcf",PATTACH_OVERHEAD_FOLLOW ,hUnit,iTeam)
    local s = string.len(tostring(iCount))
    ParticleManager:SetParticleControl(iParticle,1,Vector(8,iCount,0))
    ParticleManager:SetParticleControl(iParticle,2,Vector(1,s+1,0))
    local c = c_colors[sCurrency]
    ParticleManager:SetParticleControl(iParticle,3,c)
    ParticleManager:ReleaseParticleIndex(iParticle)
end
