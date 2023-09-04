DevStuffPlugin = class({})
_G.DevStuffPlugin = DevStuffPlugin
DevStuffPlugin.settings = {}
DevStuffPlugin.unit_cache = {}

function DevStuffPlugin:Init()
    print("[DevStuffPlugin] found")
end

function DevStuffPlugin:ApplySettings()
    DevStuffPlugin.settings = PluginSystem:GetAllSetting("devstuff")
    GameRules:SetRiverPaint(2,999)
    
    CustomGameEventManager:RegisterListener("debug_unit",function(i,tEvent) DevStuffPlugin:debug_unit(tEvent) end)
    print("dev stuff!")
--[[     ListenToGameEvent("npc_spawned", function(event)
        if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then return end
        DevStuffPlugin:SpawnEvent(event)
end,nil) ]]
end


function DevStuffPlugin:debug_unit(tEvent)
    print("someone wants to debug unit")
    local hUnit = EntIndexToHScript(tEvent.target)
    print(tEvent.target)
    if not hUnit:IsDOTANPC() then return end
    local data = {}
    data.AttackReady = hUnit:AttackReady()
    data.BoundingRadius2D = hUnit:BoundingRadius2D()
    data.CanBeSeenByAnyOpposingTeam = hUnit:CanBeSeenByAnyOpposingTeam()
    data.CanSellItems = hUnit:CanSellItems()
    data.FindAllModifiers = hUnit:FindAllModifiers()
    for i=1,#data.FindAllModifiers do
        local hMod = data.FindAllModifiers[i]
        local mod = {}
        mod.GetName = hMod:GetName()
        mod.GetStackCount = hMod:GetStackCount()
        data.FindAllModifiers[i] = mod
    end
    data.GetAbilityCount = hUnit:GetAbilityCount()
    data.GetAcquisitionRange = hUnit:GetAcquisitionRange()
    data.GetAdditionalBattleMusicWeight = hUnit:GetAdditionalBattleMusicWeight()
    data.GetAggroTarget = hUnit:GetAggroTarget()
    data.GetAttackAnimationPoint = hUnit:GetAttackAnimationPoint()
    data.GetAttackCapability = hUnit:GetAttackCapability()
    data.GetAttackDamage = hUnit:GetAttackDamage()
    data.GetAttackRangeBuffer = hUnit:GetAttackRangeBuffer()
    data.GetAttackSpeed = hUnit:GetAttackSpeed()
    data.GetAttacksPerSecond = hUnit:GetAttacksPerSecond()
    data.GetAttackTarget = hUnit:GetAttackTarget()
    data.GetBaseAttackRange = hUnit:GetBaseAttackRange()
    data.GetBaseAttackTime = hUnit:GetBaseAttackTime()
    data.GetBaseDamageMax = hUnit:GetBaseDamageMax()
    data.GetBaseDamageMin = hUnit:GetBaseDamageMin()
    data.GetBaseDayTimeVisionRange = hUnit:GetBaseDayTimeVisionRange()
    data.GetBaseHealthBarOffset = hUnit:GetBaseHealthBarOffset()
    data.GetBaseHealthRegen = hUnit:GetBaseHealthRegen()
    data.GetBaseMagicalResistanceValue = hUnit:GetBaseMagicalResistanceValue()
    data.GetBaseMaxHealth = hUnit:GetBaseMaxHealth()
    data.GetBaseMoveSpeed = hUnit:GetBaseMoveSpeed()
    data.GetBaseNightTimeVisionRange = hUnit:GetBaseNightTimeVisionRange()
    data.GetBonusManaRegen = hUnit:GetBonusManaRegen()
    data.GetCastPoint = hUnit:GetCastPoint(true)
    data.GetCastPoint = hUnit:GetCastPoint(false)
    data.GetCastRangeBonus = hUnit:GetCastRangeBonus()
    data.GetCloneSource = hUnit:GetCloneSource()
    data.GetCollisionPadding = hUnit:GetCollisionPadding()
    data.GetCooldownReduction = hUnit:GetCooldownReduction()
    data.GetCreationTime = hUnit:GetCreationTime()
    data.GetCurrentActiveAbility = hUnit:GetCurrentActiveAbility()
    data.GetCurrentVisionRange = hUnit:GetCurrentVisionRange()
    data.GetCursorCastTarget = hUnit:GetCursorCastTarget()
    data.GetCursorPosition = hUnit:GetCursorPosition()
    data.GetCursorTargetingNothing = hUnit:GetCursorTargetingNothing()
    data.GetDamageMax = hUnit:GetDamageMax()
    data.GetDamageMin = hUnit:GetDamageMin()
    data.GetDayTimeVisionRange = hUnit:GetDayTimeVisionRange()
    data.GetDeathXP = hUnit:GetDeathXP()
    data.GetDisplayAttackSpeed = hUnit:GetDisplayAttackSpeed()
    data.GetEvasion = hUnit:GetEvasion()
    data.GetForceAttackTarget = hUnit:GetForceAttackTarget()
    data.GetGoldBounty = hUnit:GetGoldBounty()
    data.GetHasteFactor = hUnit:GetHasteFactor()
    data.GetHealthDeficit = hUnit:GetHealthDeficit()
    data.GetHealthPercent = hUnit:GetHealthPercent()
    data.GetHealthRegen = hUnit:GetHealthRegen()
    data.GetHullRadius = hUnit:GetHullRadius()
    data.GetIdealSpeed = hUnit:GetIdealSpeed()
    data.GetIdealSpeedNoSlows = hUnit:GetIdealSpeedNoSlows()
    data.GetIncreasedAttackSpeed = hUnit:GetIncreasedAttackSpeed()
    data.GetInitialGoalEntity = hUnit:GetInitialGoalEntity()
    data.GetInitialGoalPosition = hUnit:GetInitialGoalPosition()
    data.GetLastAttackTime = hUnit:GetLastAttackTime()
    data.GetLastDamageTime = hUnit:GetLastDamageTime()
    data.GetLastIdleChangeTime = hUnit:GetLastIdleChangeTime()
    data.GetLevel = hUnit:GetLevel()
    data.GetMainControllingPlayer = hUnit:GetMainControllingPlayer()
    data.GetMana = hUnit:GetMana()
    data.GetManaPercent = hUnit:GetManaPercent()
    data.GetManaRegen = hUnit:GetManaRegen()
    data.GetMaximumGoldBounty = hUnit:GetMaximumGoldBounty()
    data.GetMaxMana = hUnit:GetMaxMana()
    data.GetMinimumGoldBounty = hUnit:GetMinimumGoldBounty()
    data.GetModelRadius = hUnit:GetModelRadius()
    data.GetModifierCount = hUnit:GetModifierCount()
    data.GetMustReachEachGoalEntity = hUnit:GetMustReachEachGoalEntity()
    data.GetNeutralSpawnerName = hUnit:GetNeutralSpawnerName()
    data.GetNeverMoveToClearSpace = hUnit:GetNeverMoveToClearSpace()
    data.GetNightTimeVisionRange = hUnit:GetNightTimeVisionRange()
    data.GetOpposingTeamNumber = hUnit:GetOpposingTeamNumber()
    data.GetPaddedCollisionRadius = hUnit:GetPaddedCollisionRadius()
    data.GetPhysicalArmorBaseValue = hUnit:GetPhysicalArmorBaseValue()
    data.GetPhysicalArmorValue = hUnit:GetPhysicalArmorValue(false)
    data.GetPlayerOwnerID = hUnit:GetPlayerOwnerID()
    data.GetProjectileSpeed = hUnit:GetProjectileSpeed()
    data.GetRangedProjectileName = hUnit:GetRangedProjectileName()
    data.GetRemainingPathLength = hUnit:GetRemainingPathLength()
    data.GetSecondsPerAttack = hUnit:GetSecondsPerAttack()
    data.GetSpellAmplification = hUnit:GetSpellAmplification(false)
    data.GetStatusResistance = hUnit:GetStatusResistance()
    data.GetTotalPurchasedUpgradeGoldCost = hUnit:GetTotalPurchasedUpgradeGoldCost()
    data.GetUnitLabel = hUnit:GetUnitLabel()
    data.GetUnitName = hUnit:GetUnitName()
    data.HasAnyActiveAbilities = hUnit:HasAnyActiveAbilities()
    data.HasAttackCapability = hUnit:HasAttackCapability()
    data.HasFlyingVision = hUnit:HasFlyingVision()
    data.HasFlyMovementCapability = hUnit:HasFlyMovementCapability()
    data.HasGroundMovementCapability = hUnit:HasGroundMovementCapability()
    data.HasInventory = hUnit:HasInventory()
    data.HasMovementCapability = hUnit:HasMovementCapability()
    data.HasScepter = hUnit:HasScepter()
    data.IsAlive = hUnit:IsAlive()
    data.IsAncient = hUnit:IsAncient()
    data.IsAttackImmune = hUnit:IsAttackImmune()
    data.IsAttacking = hUnit:IsAttacking()
    data.IsBarracks = hUnit:IsBarracks()
    data.IsBlind = hUnit:IsBlind()
    data.IsBlockDisabled = hUnit:IsBlockDisabled()
    data.IsBoss = hUnit:IsBoss()
    data.IsBossCreature = hUnit:IsBossCreature()
    data.IsBuilding = hUnit:IsBuilding()
    data.IsChanneling = hUnit:IsChanneling()
    data.IsClone = hUnit:IsClone()
    data.IsCommandRestricted = hUnit:IsCommandRestricted()
    data.IsConsideredHero = hUnit:IsConsideredHero()
    data.IsControllableByAnyPlayer = hUnit:IsControllableByAnyPlayer()
    data.IsCourier = hUnit:IsCourier()
    data.IsCreature = hUnit:IsCreature()
    data.IsCreep = hUnit:IsCreep()
    data.IsCreepHero = hUnit:IsCreepHero()
    data.IsCurrentlyHorizontalMotionControlled = hUnit:IsCurrentlyHorizontalMotionControlled()
    data.IsCurrentlyVerticalMotionControlled = hUnit:IsCurrentlyVerticalMotionControlled()
    data.IsDebuffImmune = hUnit:IsDebuffImmune()
    data.IsDisarmed = hUnit:IsDisarmed()
    data.IsDominated = hUnit:IsDominated()
    data.IsEvadeDisabled = hUnit:IsEvadeDisabled()
    data.IsFeared = hUnit:IsFeared()
    data.IsFort = hUnit:IsFort()
    data.IsFrozen = hUnit:IsFrozen()
    data.IsHero = hUnit:IsHero()
    data.IsHeroWard = hUnit:IsHeroWard()
    data.IsHexed = hUnit:IsHexed()
    data.IsIdle = hUnit:IsIdle()
    data.IsIllusion = hUnit:IsIllusion()
    data.IsInvisible = hUnit:IsInvisible()
    data.IsInvulnerable = hUnit:IsInvulnerable()
    data.IsLowAttackPriority = hUnit:IsLowAttackPriority()
    data.IsMagicImmune = hUnit:IsMagicImmune()
    data.IsMovementImpaired = hUnit:IsMovementImpaired()
    data.IsMoving = hUnit:IsMoving()
    data.IsMuted = hUnit:IsMuted()
    data.IsNeutralUnitType = hUnit:IsNeutralUnitType()
    data.IsNightmared = hUnit:IsNightmared()
    data.IsOther = hUnit:IsOther()
    data.IsOutOfGame = hUnit:IsOutOfGame()
    data.IsOwnedByAnyPlayer = hUnit:IsOwnedByAnyPlayer()
    data.IsPhantom = hUnit:IsPhantom()
    data.IsPhantomBlocker = hUnit:IsPhantomBlocker()
    data.IsPhased = hUnit:IsPhased()
    data.IsRangedAttacker = hUnit:IsRangedAttacker()
    data.IsRealHero = hUnit:IsRealHero()
    data.IsReincarnating = hUnit:IsReincarnating()
    data.IsRooted = hUnit:IsRooted()
    data.IsShrine = hUnit:IsShrine()
    data.IsSilenced = hUnit:IsSilenced()
    data.IsSpeciallyDeniable = hUnit:IsSpeciallyDeniable()
    data.IsSpeciallyUndeniable = hUnit:IsSpeciallyUndeniable()
    data.IsStrongIllusion = hUnit:IsStrongIllusion()
    data.IsStunned = hUnit:IsStunned()
    data.IsSummoned = hUnit:IsSummoned()
    data.IsTaunted = hUnit:IsTaunted()
    data.IsTempestDouble = hUnit:IsTempestDouble()
    data.IsTower = hUnit:IsTower()
    data.IsUnableToMiss = hUnit:IsUnableToMiss()
    data.IsUnselectable = hUnit:IsUnselectable()
    data.IsWard = hUnit:IsWard()
    data.IsZombie = hUnit:IsZombie()
    data.NoHealthBar = hUnit:NoHealthBar()
    data.NoTeamMoveTo = hUnit:NoTeamMoveTo()
    data.NoTeamSelect = hUnit:NoTeamSelect()
    data.NotOnMinimap = hUnit:NotOnMinimap()
    data.NotOnMinimapForEnemies = hUnit:NotOnMinimapForEnemies()
    data.NoUnitCollision = hUnit:NoUnitCollision()
    data.PassivesDisabled = hUnit:PassivesDisabled()
    data.Script_IsDeniable = hUnit:Script_IsDeniable()
    
    data.GetItemInSlot = {}
    if hUnit:HasInventory() then
        for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_TRANSIENT_CAST_ITEM do
            local hItem = hUnit:GetItemInSlot(i);
            if hItem ~= nil then
                data.GetItemInSlot[i] = {
                    GetAbilityName = hItem:GetAbilityName(),
                    GetLevel = hItem:GetLevel(),
                }
            end
        end
    end
    
    data.GetAbilityByIndex = {}
    local c = hUnit:GetAbilityCount()
    for i=1,c do
        local hAbility = hUnit:GetAbilityByIndex(i-1)
        if hAbility ~= nil then
            data.GetAbilityByIndex[i] = {
                GetAbilityName = hAbility:GetAbilityName(),
                GetLevel = hAbility:GetLevel(),
            }
        end
    end

    print("sending data!")
    
    CustomNetTables:SetTableValue("debug_data", "unit_debug", data)    
end

function DevStuffPlugin:SpawnEvent(event)
    local hUnit = EntIndexToHScript(event.entindex)
    if not hUnit.IsRealHero then return end
    if hUnit:IsRealHero() then
        if DevStuffPlugin.unit_cache[event.entindex] ~= nil then return end
        DevStuffPlugin.unit_cache[event.entindex] = true
        DevStuffPlugin:DoHeroes(hUnit)
    end
end

function DevStuffPlugin:DoHeroes(hUnit)
    --local hAttachment = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/attach_patch.vmdl", targetname=DoUniqueString("prop_dynamic")})

    if true then
        hUnit:SetModel("models/attach_patch.vmdl")
        hUnit:SetMaterialGroup("material")
    else
        print("[DevStuffPlugin] attach thing")
        CreateUnitByNameAsync("npc_dota_thinker",Vector(0,0,0),false,nil,nil,0,
        function(hAttachment)
            print("Spawned npc_dota_thinker")
            if hAttachment ~= nil then
                hAttachment:SetModel("models/attach_patch.vmdl")
                hAttachment:FollowEntity(hUnit,true)
                hAttachment:FollowEntityMerge(hUnit,"attach_hitloc")
                hAttachment:SetParent(hUnit,"attach_hitloc")
                
            else
                print("failed to create info_attach_dev")
            end

            print("attach_hitloc",hUnit:ScriptLookupAttachment("attach_hitloc"))
            print("attach_orb1",hUnit:ScriptLookupAttachment("attach_orb1"))
            print("attach_orb2",hUnit:ScriptLookupAttachment("attach_orb2"))
            print("attach_orb3",hUnit:ScriptLookupAttachment("attach_orb3"))
            print("attach_weapon_core_fx",hUnit:ScriptLookupAttachment("attach_weapon_core_fx"))
            print("attach_orb1 on new",hAttachment:ScriptLookupAttachment("attach_orb1"))
            print("attach_orb2 on new",hAttachment:ScriptLookupAttachment("attach_orb2"))
            print("attach_orb3 on new",hAttachment:ScriptLookupAttachment("attach_orb3"))
            print("attach_weapon_core_fx on new",hAttachment:ScriptLookupAttachment("attach_weapon_core_fx"))

            Timers:CreateTimer(2,function()
                print("with delay")
                print("attach_hitloc",hUnit:ScriptLookupAttachment("attach_hitloc"))
                print("attach_orb1",hUnit:ScriptLookupAttachment("attach_orb1"))
                print("attach_orb2",hUnit:ScriptLookupAttachment("attach_orb2"))
                print("attach_orb3",hUnit:ScriptLookupAttachment("attach_orb3"))
                print("attach_weapon_core_fx",hUnit:ScriptLookupAttachment("attach_weapon_core_fx"))
                print("attach_orb1 on new",hAttachment:ScriptLookupAttachment("attach_orb1"))
                print("attach_orb2 on new",hAttachment:ScriptLookupAttachment("attach_orb2"))
                print("attach_orb3 on new",hAttachment:ScriptLookupAttachment("attach_orb3"))
                print("attach_weapon_core_fx on new",hAttachment:ScriptLookupAttachment("attach_weapon_core_fx"))
            end)
        end)
    end
end


function DevStuffPlugin:ShortCutMods(tArgs,bTeam,iPlayer)
	local hUnit = Entities:GetLocalPlayerController() and Entities:GetLocalPlayerController():GetQueryUnit()
    if (hUnit) then
        for m,mod in pairs(hUnit:FindAllModifiers()) do
            local hAbility = mod:GetAbility()
            if hAbility ~= nil then
                print("Modifier:",mod:GetName()," of ", hAbility:GetAbilityName())
            else
                print("Modifier:",mod:GetName()," without ability parent")
            end
        end
    end
end

function DevStuffPlugin:ShortCutResetDefeated(tArgs,bTeam,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if not GameRules:PlayerHasCustomGameHostPrivileges(hPlayer) then return end
    GameRules:ResetDefeated()
end
function DevStuffPlugin:ShortCutResetToCustomGameSetup(tArgs,bTeam,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if not GameRules:PlayerHasCustomGameHostPrivileges(hPlayer) then return end
    GameRules:ResetToCustomGameSetup()
end
function DevStuffPlugin:ShortCutResetToHeroSelection(tArgs,bTeam,iPlayer)
    local hPlayer = PlayerResource:GetPlayer(iPlayer)
    if not GameRules:PlayerHasCustomGameHostPrivileges(hPlayer) then return end
    GameRules:ResetToHeroSelection()
end