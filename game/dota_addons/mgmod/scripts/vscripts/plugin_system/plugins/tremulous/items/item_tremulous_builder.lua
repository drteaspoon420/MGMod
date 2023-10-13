
item_tremulous_builder = class({})

function item_tremulous_builder:OnSpellStart()
    if not IsServer() then return end
    self.vPos = self:GetCursorPosition()
    --show build UI
    local iPlayer = self:GetCaster():GetPlayerID()
    if iPlayer ~= nil and iPlayer > -1 then
        CustomUI:DynamicHud_Create(iPlayer,"tremulous_build_ui","file://{resources}/layout/custom_game/tremulous_build_ui.xml",nil)
    end
end

function item_tremulous_builder:GetAOERadius()
    return 90
end

function item_tremulous_builder:TryBuild(sUnit,iCost)
    if not IsServer() then return end
    local vPos = self.vPos
    local vOrigin = self:GetCaster():GetAbsOrigin()
	local vDiff = vPos - vOrigin
	if vDiff:Length2D() > self:GetCastRange(vPos,nil) then
        EmitSoundOnClient("General.Dead",self:GetCaster():GetPlayerOwner())
		return false
	end
    if TremulousPlugin == nil then 
        EmitSoundOnClient("General.Dead",self:GetCaster():GetPlayerOwner())
        return false
    end
    if TremulousPlugin.settings == nil then 
        EmitSoundOnClient("General.Dead",self:GetCaster():GetPlayerOwner())
        return false
    end
    if TremulousPlugin.settings.currency == nil then 
        EmitSoundOnClient("General.Dead",self:GetCaster():GetPlayerOwner())
        return false
    end
    local iPlayer = self:GetCaster():GetPlayerOwnerID()
    if iPlayer == nil or iPlayer < 0 then
        EmitSoundOnClient("General.Dead",self:GetCaster():GetPlayerOwner())
        return false
    end
    if not CurrenciesPlugin:SpendCurrency(TremulousPlugin.settings.currency,iPlayer,iCost) then
        EmitSoundOnClient("General.Dead",self:GetCaster():GetPlayerOwner())
        return false
    else
        local iTeam = self:GetCaster():GetTeam()
        CreateUnitByNameAsync(sUnit,vPos,true,nil,nil,iTeam,
            function(hNpc)
            hNpc:AddNewModifier(self:GetCaster(), nil, "modifier_sunk_cost", {cost = iCost})
            hNpc:AddNewModifier(self:GetCaster(),nil,"modifier_building_inprogress", {duration = 20})
            for i=0,hNpc:GetAbilityCount() do
                local hAbility = hNpc:GetAbilityByIndex(i)
                if hAbility ~= nil then
                    hAbility:SetLevel(1)
                end
            end
            FindClearSpaceForUnit(hNpc,vPos,true)
        end)
        EmitSoundOnClient("General.Buy",self:GetCaster():GetPlayerOwner())
    end
end

LinkLuaModifier( "modifier_sunk_cost", "plugin_system/plugins/tremulous/items/item_tremulous_builder", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier( "modifier_building_inprogress", "plugin_system/plugins/tremulous/items/item_tremulous_builder", LUA_MODIFIER_MOTION_NONE )



modifier_sunk_cost = class({})
function modifier_sunk_cost:OnCreated(event)
	if not IsServer() then return end
	self:SetStackCount(event.cost)
end
function modifier_sunk_cost:OnDestroy(event)
	if not IsServer() then return end
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
    if TremulousPlugin.settings.currency == "gold" then
        return
    end
    local iLeader = Toolbox:GetTeamLeader(self:GetParent():GetTeam())
    CurrenciesPlugin:AlterCurrency(TremulousPlugin.settings.currency,iLeader,self:GetStackCount())
end
function modifier_sunk_cost:IsHidden() return true end


modifier_building_inprogress = class({})
function modifier_building_inprogress:IsHidden() return false end


function modifier_building_inprogress:OnCreated( kv )
	if IsServer() then
		local hParent = self:GetParent()
		if hParent then 
	        local nFXIndex = ParticleManager:CreateParticle( "particles/items5_fx/repair_kit.vpcf", PATTACH_ABSORIGIN_FOLLOW, hParent );
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hParent, PATTACH_POINT_FOLLOW, "attach_hitloc", hParent:GetOrigin(), true )
			ParticleManager:SetParticleControlEnt( nFXIndex, 1, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, hParent:GetOrigin(), true  )
			EmitSoundOn( "DOTA_Item.RepairKit.Target", hParent )
	        self:AddParticle( nFXIndex, false, false, -1, false, false )
			self.m_nFXIndex = nFXIndex
            self.f_frac = hParent:GetMaxHealth() / (self:GetDuration() * 10)
			hParent:SetHealth( 1 )
			self:StartIntervalThink( 0.1 )
		end
	end
end

function modifier_building_inprogress:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle( self.m_nFXIndex, false )

		if self.nFXTimer ~= nil then
			ParticleManager:DestroyParticle( self.nFXTimer, true )
		end
	end
end


function modifier_building_inprogress:OnIntervalThink()
	if IsServer() then
		local hParent = self:GetParent()
		if hParent then 
			hParent:Heal( self.f_frac, nil )
		end
	end
end

function modifier_building_inprogress:IsPurgable()
	return false
end
