SmithingPlugin = class({})
_G.SmithingPlugin = SmithingPlugin
SmithingPlugin.settings = {}

function SmithingPlugin:Init()
    print("[SmithingPlugin] found")
end

function SmithingPlugin:ApplySettings()
    SmithingPlugin.settings = PluginSystem:GetAllSetting("smithing")

    LinkLuaModifier( "modifier_smitten", "plugin_system/plugins/smithing/modifier_smitten", LUA_MODIFIER_MOTION_NONE )

    


    --Currency thing
    local tOption = {
        plugin = SmithingPlugin,
        plugin_name = "smithing",
        cost = SmithingPlugin.settings.cost,
        call_fn = "buy_smith",
        option_name = "smith",
		autobuy = false,
    }
    print(SmithingPlugin.settings.currency)
    print(SmithingPlugin.settings.cost)
    CurrenciesPlugin:RegisterSpendOption(SmithingPlugin.settings.currency,tOption)
end

SmithingPlugin.bans = {
	item_ward_observer = true,
	item_ward_sentry = true,
	item_ward_dispenser = true,
}

function SmithingPlugin:buy_smith(tEvent,tExtra)
	local iPlayer = tEvent.iPlayer
	if not PlayerResource:IsValidPlayer(iPlayer) then return end
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
	if hPlayer == nil then return end
    local hHero = hPlayer:GetAssignedHero()
	if hHero == nil then return end
	if not hHero:HasInventory() then return end
	if not hHero:HasModifier("modifier_smitten") then
		hModifier = hHero:AddNewModifier(hHero, nil, "modifier_smitten", {})
	end

	for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		local hItem = hHero:GetItemInSlot(i)
		SmithingPlugin:UpgradeItem(hItem,hHero)
	end
	local hItem = hHero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT);
	SmithingPlugin:UpgradeItem(hItem,hHero)
    CustomGameEventManager:Send_ServerToPlayer(hPlayer,"smithing_update",{})
end

function SmithingPlugin:UpgradeItem(hItem,hHero)
    if hItem ~= nil then
        local item_name = hItem:GetAbilityName()
        if SmithingPlugin.bans[item_name] ~= nil then return 0 end
        local level = hItem:GetSecondaryCharges()
        local chance = SmithingPlugin.settings.base_chance - (level*SmithingPlugin.settings.chance_reduction)
        if (RandomInt(0,100) < chance) then
            hItem:SetSecondaryCharges(hItem:GetSecondaryCharges() + 1)
            local iIndex = hItem:entindex()
            hItem:OnUnequip()
            Timers:CreateTimer( 0, function()
                hItem:OnEquip()
            end)
            local particle = ParticleManager:CreateParticle("particles/items3_fx/iron_talon_active.vpcf", PATTACH_ABSORIGIN, hHero)
            ParticleManager:ReleaseParticleIndex(particle)
            hHero:EmitSound("DOTA_Item.IronTalon.Activate")
            return 1
        else
            local particle = ParticleManager:CreateParticle("particles/items3_fx/black_powder_bag.vpcf", PATTACH_ABSORIGIN, hHero)
            ParticleManager:ReleaseParticleIndex(particle)
            hHero:EmitSound("Item.BlackPowder")
            hHero:RemoveItem(hItem)
            return 2
        end
    end
    return 0
end
