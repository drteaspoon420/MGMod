
function build_at(hUnit,sUnit,iCost)
    if not check_gold(hUnit,sUnit,iCost,true) then return false end
    local vPos = hUnit:GetAbsOrigin()
    local iTeam = hUnit:GetTeam()
    CreateUnitByNameAsync(sUnit,vPos,true,nil,nil,iTeam,
        function(hNpc)
        FindClearSpaceForUnit(hUnit,vPos,true)
    end)
end

function check_gold(hUnit,sUnit,iCost,bSpend)
    if TremulousPlugin == nil then 
        print("no tremulous?")
        return false
    end
    if TremulousPlugin.settings == nil then 
        print("no tremulous settings?")
        return false
    end
    if TremulousPlugin.settings.currency == nil then 
        print("no tremulous currency?")
        return false
    end
    local iPlayer = hUnit:GetPlayerOwnerID()
    if iPlayer == nil or iPlayer < 0 then
        print("player id invalid")
        return false
    end
    if TremulousPlugin.settings.currency == "gold" then
        iCost = iCost
        local iGold = PlayerResource:GetGold(iPlayer)
        if iGold < iCost then
            print("player gold not enough", iCost,"/",iGold)
            return false
        end
        if (bSpend) then
            PlayerResource:SpendGold(iPlayer,iCost,DOTA_ModifyGold_Building)
        end
    else
        if (bSpend) then
            if not CurrenciesPlugin:SpendCurrency(TremulousPlugin.settings.currency,iPlayer,iCost) then
                print("player currency not enough", iCost,"/",iGold)
                return false
            end
        else
            if not CurrenciesPlugin:CheckCurrency(TremulousPlugin.settings.currency,iPlayer,iCost) then
                print("player currency not enough", iCost,"/",iGold)
                return false
            end
        end
    end
    return true
end

item_tremulous_builder = class({})

function item_tremulous_builder:OnSpellStart()
    if not IsServer() then return end
    if not self.selected then
        self.sUnit = nil
        self.iCost = nil
        --show build UI
        local iPlayer = self:GetCaster():GetPlayerID()
        if iPlayer ~= nil and iPlayer > -1 then
            CustomUI:DynamicHud_Create(iPlayer,"tremulous_build_ui","file://{resources}/layout/custom_game/tremulous_build_ui.xml",
            { TestVar = "test_666" })
        end
    else
        self.selected = false
        if (self.sUnit == nil or self.iCost == nil) then
            return
        end
        build_at(self:GetCaster(),self.sUnit,self.iCost)
        self.sUnit = nil
        self.iCost = nil
    end
end

function item_tremulous_builder:TryBuild(sUnit,iCost)
    if not IsServer() then return end
    if not check_gold(self:GetCaster(),sUnit,iCost,false) then
        EmitSoundOnClient("General.Dead",self:GetCaster():GetPlayerOwner())
        return
    end
    self.sUnit = sUnit
    self.iCost = iCost
    self.selected = true
    self:CastAbility()
end
