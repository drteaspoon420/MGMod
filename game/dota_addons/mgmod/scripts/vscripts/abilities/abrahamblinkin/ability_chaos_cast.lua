LinkLuaModifier( "modifier_chaos_cast", "abilities/abrahamblinkin/ability_chaos_cast", LUA_MODIFIER_MOTION_NONE )

local ALL_ABILITY_EXCEPTIONS = LoadKeyValues('scripts/vscripts/plugin_system/plugins/twisted_spells/ability_exceptions.txt')

ability_chaos_cast = class ({})

function ability_chaos_cast:GetIntrinsicModifierName()
  return "modifier_chaos_cast"
end

function ability_chaos_cast:OnSpellStart()
  if self:GetCurrentAbilityCharges() > 0 then
    self:SetCurrentAbilityCharges( self:GetCurrentAbilityCharges() - 1 )
  end
end


-- MODIFIER
-------------------------------------
modifier_chaos_cast = modifier_chaos_cast or class({})

function modifier_chaos_cast:GetTexture() return "chaos_knight_chaos_strike" end

function modifier_chaos_cast:IsPermanent() return true end
function modifier_chaos_cast:RemoveOnDeath() return true end
function modifier_chaos_cast:IsDebuff() return true end
function modifier_chaos_cast:IsPurgable() return false end
function modifier_chaos_cast:IsHidden() return true end

function modifier_chaos_cast:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
	}
	return funcs
end

function modifier_chaos_cast:OnAbilityFullyCast( event )
  if not IsServer() then return end
  local caster = event.ability:GetCaster()
  if caster~=self:GetParent() then return end

  local ability = event.ability
  if ability:IsItem() then return end

  local abilityBehavior = GetCastTypeString( ability )
  local cast_type = nil

  if string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_POINT") then
    cast_type = DOTA_UNIT_ORDER_CAST_POSITION
  elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET") then
    cast_type = DOTA_UNIT_ORDER_CAST_NO_TARGET
  elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET") then
    cast_type = DOTA_UNIT_ORDER_CAST_TARGET
  end

  if cast_type==nil then return end
  
  if ability then
    if cast_type==DOTA_UNIT_ORDER_CAST_POSITION or cast_type==DOTA_UNIT_ORDER_CAST_NO_TARGET then
    
      local ability_exceptions = ALL_ABILITY_EXCEPTIONS[ability:GetName()]
      local pos = ability:GetCursorPosition()

      if RandomInt( 1, 10 ) > 7 then pos = caster:GetAbsOrigin() end-- 70% chance to use target position instead of caster position

      local has_charges = self:GetAbility():GetCurrentAbilityCharges() >= 1
      local needs_charges_bstr = nil

      if ability_exceptions~=nil then
        needs_charges_bstr = ability_exceptions.spend -- returns a bool but it is unfortunately a string
      end
    
      if needs_charges_bstr=="false" or has_charges then
        
        local should_chaos_cast = ability_exceptions==nil or ability_exceptions.cast=="true"
        local should_spend_charge = ability_exceptions==nil or ability_exceptions.spend=="true"

        if should_chaos_cast then
          self:GetAbility():ChaosCastPointSpell( ability, pos ) -- Chaos-cast and also check whether there is secondary ability that should re-use the same units
        end

        if should_spend_charge then
          self:GetAbility():OnSpellStart()
        end
      -- else the ability costs charges and chaos_cast doesn't have charges, so do nothing
      end

    end

  end

end

-------------------
---- Ability Extra Logic
-------------------

function BeginCastStormRadial( caster, chaos_ability, ability_name, origin, cast_qty, delay, min_dist, max_dist, min_radius, max_radius )

  if IsClient() then return end

  chaos_ability.last_casters = {}

  local hero = caster
  local subcasters = GetIdleSubcasters( hero )

  chaos_ability.pos = {}

  for i=1,cast_qty do
    chaos_ability.pos[i] = GetRandomPointInRadius( origin, min_dist, max_dist )
    local unit = subcasters[i]

    if unit~=nil then  
      local weak_abil = unit:FindAbilityByName( "weak_creature" )
      if weak_abil == nil then
        weak_abil = unit:AddAbility( "weak_creature" )
      end
      weak_abil.radius = RandomInt( 10*min_radius, 10*max_radius ) / 10
      local ability = unit:FindAbilityByName( ability_name )
      if ability == nil then
        ability = unit:AddAbility(ability_name)
      end

      ability:SetLevel( chaos_ability:GetLevel() )
      ability:EndCooldown()

      local abilityBehavior = GetCastTypeString( ability )
      local cast_type = nil
      
      if string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_POINT") then
        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_NO_TARGET
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_TARGET
      end

      ability:SetLevel( chaos_ability:GetLevel() )
      if cast_type ~= DOTA_UNIT_ORDER_CAST_NO_TARGET then
        local caster_new_pos = chaos_ability:GetCaster():GetAbsOrigin()
        unit:SetAbsOrigin(caster_new_pos)
      end

      local order_params = {
        UnitIndex = unit:GetEntityIndex(),
        OrderType = cast_type,
        AbilityIndex = ability:GetEntityIndex(),
        TargetIndex = ability:GetEntityIndex(),
        Position = chaos_ability.pos[i],
        Queue = false
      }

      DelayCastWithOrders( unit, order_params, delay*i )
      table.insert( chaos_ability.last_casters, unit )

      Timers:CreateTimer( delay + 1, function()
        ability:EndCooldown()
        return nil
      end)
    end

  end
end

function SplitSubcast( caster, chaos_ability, ability_name, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, vector_cast_rotation )

  if IsClient() then return end

  local hero = caster
  local subcasters = GetIdleSubcasters( hero )
  
  --------------
  -- Start logic for secondary abilities
  --------------

  local original_ability = hero:FindAbilityByName(ability_name)
  local has_secondary = false
  local is_secondary = false

  if original_ability~=nil then
    has_secondary = GetReturnReleaseOrEndAbilityName( original_ability:GetName() )~=nil
    is_secondary = IsReturnReleaseOrEndAbilityName( original_ability:GetName() )
  end

  if has_secondary then
    local secondary_ability_name = GetReturnReleaseOrEndAbilityName( original_ability:GetName() )
    local secondary_ability = hero:FindAbilityByName( secondary_ability_name )

    local current_prepped = secondary_ability.prepped_casters
    
    if secondary_ability.prepped_casters==nil then
      secondary_ability.prepped_casters = subcasters
    else
      for i=1,cast_qty do
        local num_in_prepped = #current_prepped
        secondary_ability.prepped_casters[ num_in_prepped + i ] = subcasters[i]
      end
    end
  end

  if is_secondary and original_ability~=nil and original_ability.prepped_casters~=nil then -- if the original ability is a secondary ability and has prepared casters, then use those casters

    local previous_casters = original_ability.prepped_casters

    for i=1,#previous_casters do
      subcasters[i] = original_ability.prepped_casters[i]
    end

    cast_qty = #previous_casters
    origin = hero:GetAbsOrigin()
    -- original_ability.prepped_casters = {}
  end

  --------------
  -- End Secondary Ability Logic
  --------------

  for i=1,cast_qty do
    local unit = subcasters[i]

    -- if unit==nil then return end
    if unit ~= nil then
      unit:SetAbsOrigin( origin )
      -- unit.busy = true
      local angle_mult = i - 1 -- times to increment the angle, starting at 0 for the first iteration
      
      local y_degrees = offset_angle_degrees + ( angle_increment_degrees * angle_mult )
      local rotation = QAngle( 0, y_degrees, 0 )

      local random_degrees = vector_cast_rotation + ( angle_increment_degrees * angle_mult )
      local random_vector_rotation = QAngle( 0, random_degrees, 0 )
      -- local rand_rot_pos = unit:GetAbsOrigin() + ( unit:GetForwardVector() * ( dist_from_origin + dist_increment * i ) )

      local cast_type = nil
      local isVTarget_b = false

      local new_forward = RotateOrientation( rotation, original_angles )
      local rand_vector_forward = RotateOrientation( random_vector_rotation, original_angles )

      local weak_abil = unit:FindAbilityByName( "weak_creature" )
      if weak_abil == nil then
        weak_abil = unit:AddAbility( "weak_creature" )
      end
      weak_abil.damage = damage_fl
      weak_abil.radius = radius_fl

      -- print(unit)
      local ability = unit:FindAbilityByName( ability_name )
      if ability == nil then
        ability = unit:AddAbility(ability_name)
      else
        ability:EndCooldown()
      end

      ability:SetHidden(false)
      local abilityBehavior = GetCastTypeString( ability )

      ability:SetLevel( chaos_ability:GetLevel() )
      -- ability:EndCooldown()

      unit:SetAbsAngles( 0, new_forward.y, 0 )
      local pos_1 = origin + ( unit:GetForwardVector() * ( dist_from_origin + ( dist_increment * i ) ) ) -- get incremented distance from origin at designated angle
      local pos_1_cast = pos_1 + ( unit:GetForwardVector() * dist_from_subcaster ) -- get point at dist_from_subcaster ahead of pos_1, to cast at

      unit:SetAbsAngles( 0, rand_vector_forward.y, 0 )
      local pos_2 = pos_1_cast
      local pos_2_cast = pos_1 + ( unit:GetForwardVector() * dist_from_subcaster ) -- get point at dist_from_subcaster ahead of pos_1, to cast at
      -- local radius = ability:GetSpecialValueFor("radius")
      
      if string.match( abilityBehavior, "DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING") then

        local order_params = {
          UnitIndex = unit:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,
          AbilityIndex = ability:GetEntityIndex(),
          TargetIndex = unit:GetEntityIndex(),
          Position = pos_1_cast,
          Queue = false
        }
        DelayCastWithOrders( unit, order_params, 0 )

        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
        isVTarget_b = true

      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_POINT") then
        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
        unit:SetAbsOrigin( origin )
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_NO_TARGET
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_TARGET
      end

      -- local subcaster_origin_spun = unit:GetAbsOrigin() + ( unit:GetForwardVector() * ( dist_from_origin + dist_increment * i ) )

      unit:SetAbsAngles( 0, new_forward.y, 0 )
      -- local subcaster_origin = unit:GetAbsOrigin() + ( unit:GetForwardVector() * ( dist_from_origin + dist_increment * i ) )
      -- local cast_pos = unit:GetAbsOrigin() + ( unit:GetForwardVector() * dist_from_subcaster )

      local cast_pos = nil
      -- if isVTarget_b then
      if vector_cast_rotation~=nil and vector_cast_rotation~=0 then -- should cast from pos_2, targeting pos_2_cast
        unit:SetAbsOrigin( pos_2 )
        cast_pos = pos_2_cast
      else
        unit:SetAbsOrigin( pos_1 )
        cast_pos = pos_1_cast
      end
      -- end

      local order_params = {
        UnitIndex = unit:GetEntityIndex(),
        OrderType = cast_type,
        AbilityIndex = ability:GetEntityIndex(),
        TargetIndex = unit:GetEntityIndex(),
        Position = cast_pos,
        Queue = false
      }

      DelayCastWithOrders( unit, order_params, delay*i )
      unit.busy = true

      Timers:CreateTimer( delay+4, function()
        ability:EndCooldown()
        unit.busy = false
        return nil
      end)
    end
  end
end

function ability_chaos_cast:GetAllAbilitySpecials()
  local specialsArray = {}

  local abilityKeys = ability:GetAbilityKeyValues()
  local abilitySpecials = abilityKeys["AbilitySpecial"]
  local isTalent = string.match( self:GetName(), "special_bonus")

  if abilitySpecials and not isTalent then

    for k,v in pairs( abilitySpecials ) do
      for x,y in pairs(v) do

        local isVarType = string.match( x, "var_type")
        local isScepterCheck = string.match( x, "scepter")
        local isTooltipCal = string.match( x, "Calculate")
        local isTalentStuff = string.match( x, "LinkedSpecialBonus")

        if isVarType or isScepterCheck or isTooltipCal or isTalentStuff then
          -- print("key is not useful")
        else
          -- print("key", x, "is useful. Inserting into table")
          table.insert(specialsArray,x)
        end

      end
    end
  end
  return specialsArray
end

function GetCastTypeString( ability )
  local abilityKeys = ability:GetAbilityKeyValues()
  local abilityBehavior = abilityKeys["AbilityBehavior"]
  return abilityBehavior
end

--SplitSubcast( caster, ability_name, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, vector_cast_rotation)

function ability_chaos_cast:ChaosCastPointSpell( ability, pos ) -- pos is an optional parameter that chooses an origin other than the caster's location

  local origin = ability:GetCaster():GetOrigin()

  if pos~=nil and pos~=Vector(0,0,0) then
    origin = pos
  end

  local original_angles = ability:GetCaster():GetLocalAngles()
  local spellName = ability:GetName()
  local pattern = RandomInt(1,10)
  local posNegTable = { 1, -1 }
  local posNeg = posNegTable[ RandomInt(1,2) ]
  local posNeg2 = posNegTable[ RandomInt(1,2) ]
  local vector_rotation = RandomInt( -180, 180 )
  local caster = ability:GetCaster()
  local forced_pattern = TwistedSpellsPlugin.settings.force_pattern

  if forced_pattern > 0 and forced_pattern < 11 then
    pattern = forced_pattern
  end

  local subs = GetSubcasters( caster )
  if subs==nil then
    CreateSubcasters( caster, 21 )
  end

  --SplitSubcast( caster, ability_name, spellname, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, random_rotation )`

  if ALL_ABILITY_EXCEPTIONS[spellName] and ALL_ABILITY_EXCEPTIONS[spellName].should_nerf=="true" then

    local rand_qty = RandomInt(4,5) -- cast op spells ins a ring
    SplitSubcast( caster, ability, spellName, origin, original_angles, rand_qty, 0, 360/rand_qty, 0, 1, 300+(rand_qty*50), 0, 2/rand_qty, 2/rand_qty, vector_rotation ) -- cast on four sides

  elseif pattern==1 then -- casts your spell in 3-5 rows, 3-4 casts long. Usually curved 
    local dist_increment = RandomInt( 80, 150 ) -- distance between each cast on each row
    local angle_increment_degrees = RandomInt(-30,30) -- curve of the four rows on your spell
    local rows = RandomInt(3,5)
    local instances = RandomInt(3,4)
    for i=1,instances do
      Timers:CreateTimer( 0.4*i, function()
        SplitSubcast( caster, ability, spellName, origin, original_angles, rows, 0, 360/rows, 0, 1, dist_increment*i, 0, 0.6*i, 1, vector_rotation + (angle_increment_degrees*i) ) -- cast on four sides
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern==2 then -- casts your spell in x number of rows leading away from you (4 rows would make an 'x' around you). These spells cast instantly and are never curved.    
    for i=1,4 do
      SplitSubcast( caster, ability, spellName, origin, original_angles, 4, 0, 90, 0, 1, 100*i, 0, 0.6*i, 1, vector_rotation ) -- cast on four sides
    end

  elseif pattern==3 then -- cast your ability in a wave in front of you
    local spread = 45
    for i=1,4 do
      Timers:CreateTimer( 0.4*i, function()
        SplitSubcast( caster, ability, spellName, origin, original_angles, 1+i, 0, spread/i, -spread/2, 200*i, 100*i, 0, 1+(0.5*i), 1, 0 )
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern==4 then -- instantly cast your ability in a single ring around you
    local magnitude = RandomInt( 5, 10 )
    SplitSubcast( caster, ability, spellName, origin, original_angles, magnitude, 0, 360/magnitude, 0, 0, magnitude*40*posNeg, 0, 5/magnitude, 5/magnitude, vector_rotation*posNeg )
    
  elseif pattern==5 then -- spiral
    for i=1,20 do
      Timers:CreateTimer( 0.1*i, function()
        local progression = 180 + (600/(10+i/2)*i)*posNeg
        SplitSubcast( caster, ability, spellName, origin, original_angles, 1, 0, 0, progression, 45*i, 100, 0, 0.2*i, 1, progression + vector_rotation ) -- progressive spiral
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern==6 then -- cast a totally random 'storm' of your spell in an area around you
    BeginCastStormRadial( caster, ability, spellName, origin, 10, 0.25, 100, 600, 0.5, 2 )

  elseif pattern==7 then -- Cast multiple times, crawling forward each cast, with growing radius and damage
    local rand = RandomInt(5,8)
    for i=1,rand do
      Timers:CreateTimer( 0.2*i, function()
        SplitSubcast( caster, ability, spellName, ability:GetCaster():GetAbsOrigin(), original_angles, 1, 0, 0, 0, 0, 75, 200*i, 3*i/rand, 3*i/rand, 0 ) -- progressive spiral
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern==8 then -- repeatedly cast your ability in a growing ring around you

    SplitSubcast( caster, ability, spellName, origin, original_angles, 7, 0, 360/7, 0, 200, 0, 0, 1, 1, vector_rotation*posNeg )

      Timers:CreateTimer( 0.4, function()
        SplitSubcast( caster, ability, spellName, origin, original_angles, 7, 0, 360/7, 25.7, 350, 0, 0, 1.7, 1, vector_rotation*posNeg2 )

        Timers:CreateTimer( 0.4, function()
          SplitSubcast( caster, ability, spellName, origin, original_angles, 7, 0, 360/7, 0, 500, 0, 0, 2.4, 1, vector_rotation*posNeg )
          self.RemoveSelf = true
          return nil
        end)

        self.RemoveSelf = true
        return nil
      end)

  elseif pattern==9 then
    for i=1,4 do
      Timers:CreateTimer( 0.4*i, function()
        SplitSubcast( caster, ability, spellName, ability:GetCaster():GetOrigin(), original_angles, 1, 0, 0, 0, i*150, 200, 0, 1.5, 1, vector_rotation )
        SplitSubcast( caster, ability, spellName, ability:GetCaster():GetOrigin(), original_angles, 1, 0, 0, 0, i*150, 200, 0, 1.5, 1, -vector_rotation )
        self.RemoveSelf = true
        return nil
      end)
    end
    
  elseif pattern==10 then -- instantly cast your ability in a single ring around you
    local star_points = RandomInt( 5, 8 )
    SplitSubcast( caster, ability, spellName, origin, original_angles, star_points, 0, 360/star_points, 0, 250, 250, 0, 1, 1, 180 + 180/star_points )

    if spellName=="lion_impale" and star_points==5 and origin~=caster:GetAbsOrigin() then -- if lion made a pentagram away from himself (~1/57 chance), summon a chaos golem, lol
      SplitSubcast( caster, ability, "warlock_rain_of_chaos", origin, original_angles, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0 ) -- doesn't give control of golem, but still funny
    end
    
  end

end

function GetReturnReleaseOrEndAbilityName( name )
  
  local secondary_name = nil

  if ALL_ABILITY_EXCEPTIONS[name] then
    secondary_name = ALL_ABILITY_EXCEPTIONS[name].has_secondary
  end

  if secondary_name~=nil then
    return secondary_name
  end

  return nil
end

function IsReturnReleaseOrEndAbilityName( name )
  
  local primary_name = nil

  if ALL_ABILITY_EXCEPTIONS[name] then
    primary_name = ALL_ABILITY_EXCEPTIONS[name].has_primary
  end

  if primary_name~=nil then
    return primary_name
  else
    return false
  end
end

--------------------------
-- GETTING AND CREATING SUBCASTERS
--------------------------

function CreateSubcasters( hero, num )
  hero.subcasters = {}
  for i=1,num do
    local unit = CreateUnitByName( "npc_dota_subcaster", hero:GetOrigin(), false, nil, hero, hero:GetTeam() )
    -- unit:SetControllableByPlayer(-1,true)
    -- unit:SetOwner( hero )
    unit:SetBaseDamageMin( hero:GetBaseDamageMin() )
    unit:SetBaseDamageMax( hero:GetBaseDamageMax() )

    hero.subcasters[i] = unit
    hero.subcasters[i].busy = false
    -- unit.busy = false
  end
  return hero.subcasters
end

function GetSubcasters( hero )
  return hero.subcasters
end

function GetIdleSubcasters( hero )
  local subcs = hero.subcasters
  local idle = {}
  local add_shard = hero:HasModifier( "modifier_item_aghanims_shard" )
  local add_scepter = hero:HasModifier( "modifier_item_ultimate_scepter" ) or hero:HasModifier( "modifier_item_ultimate_scepter_consumed" )

  if subcs==nil then
    subcs = CreateSubcasters( hero, 10 )
  end

  for i=1,#subcs do
    local has_scepter = subcs[i]:HasModifier( "modifier_item_ultimate_scepter_consumed" ) or subcs[i]:HasModifier( "modifier_item_ultimate_scepter" )

    if add_shard and not subcs[i]:HasModifier("modifier_item_aghanims_shard") then
      subcs[i]:AddNewModifier( hero, nil, "modifier_item_aghanims_shard", { duration = nil } )
    end

    if add_scepter and not has_scepter then
      subcs[i]:AddNewModifier( hero, nil, "modifier_item_ultimate_scepter_consumed", { duration = 0 } )
    end

    if not subcs[i]:IsChanneling() and not subcs[i].busy then
      subcs[i]:SetMana(600)
      table.insert( idle, subcs[i] )
    end
  end

  return idle
end

function DelayCastWithOrders( unit, order_params, delay )
  order_params.UnitIndex = unit:GetEntityIndex()

  Timers:CreateTimer( delay, function()

    ExecuteOrderFromTable( order_params )

    return nil
  end)
  
end

function GetRandomPointInRadius( v_location, min_dist, max_dist )
  local random_length = RandomInt( min_dist, max_dist )
  local random_point = v_location + RandomVector( random_length )
  return random_point
end