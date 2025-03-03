
function morph_to(hUnit,sUnit,iCost)
    if TremulousPlugin == nil then 
        --print("no tremulous?")
        return
    end
    if TremulousPlugin.settings == nil then 
        --print("no tremulous settings?")
        return
    end
    if TremulousPlugin.settings.currency == nil then 
        --print("no tremulous currency?")
        return
    end
    local iPlayer = hUnit:GetPlayerOwnerID()
    if iPlayer == nil or iPlayer < 0 then
        --print("player id invalid")
        return
    end
    if TremulousPlugin.settings.currency == "gold" then
        iCost = iCost * 1000
        local iGold = PlayerResource:GetGold(iPlayer)
        if iGold < iCost then
            --print("player gold not enough", iCost,"/",iGold)
            return
        end
        PlayerResource:SpendGold(iPlayer,iCost,DOTA_ModifyGold_Building)
    else
        if not CurrenciesPlugin:SpendCurrency(TremulousPlugin.settings.currency,iPlayer,iCost) then
            --print("player currency not enough", iCost,"/",iGold)
            return
        end
    end
    local vPos = hUnit:GetAbsOrigin()
    local iTeam = hUnit:GetTeam()
    hUnit:ForceKill(false)
    CreateUnitByNameAsync(sUnit,vPos,true,nil,nil,iTeam,
        function(hNpc)
    end)
end

tremulous_morph_ancient = class({})
tremulous_morph_spawn = class({})
tremulous_morph_tower = class({})
tremulous_morph_shrine = class({})
tremulous_morph_shop = class({})
tremulous_morph_barracks = class({})

function tremulous_morph_ancient:OnChannelFinish(bInterrupted)
    if bInterrupted then return end
    morph_to(self:GetCaster(),"npc_tremulous_ancient",self:GetSpecialValueFor("cost"))
end

function tremulous_morph_spawn:OnChannelFinish(bInterrupted)
    if bInterrupted then return end
    morph_to(self:GetCaster(),"npc_tremulous_spawn",self:GetSpecialValueFor("cost"))
end

function tremulous_morph_tower:OnChannelFinish(bInterrupted)
    if bInterrupted then return end
    morph_to(self:GetCaster(),"npc_tremulous_tower",self:GetSpecialValueFor("cost"))
end

function tremulous_morph_shrine:OnChannelFinish(bInterrupted)
    if bInterrupted then return end
    morph_to(self:GetCaster(),"npc_tremulous_shop",self:GetSpecialValueFor("cost"))
end

function tremulous_morph_shop:OnChannelFinish(bInterrupted)
    if bInterrupted then return end
    morph_to(self:GetCaster(),"npc_tremulous_shrine",self:GetSpecialValueFor("cost"))
end

function tremulous_morph_barracks:OnChannelFinish(bInterrupted)
    if bInterrupted then return end
    morph_to(self:GetCaster(),"npc_tremulous_barracks",self:GetSpecialValueFor("cost"))
end
