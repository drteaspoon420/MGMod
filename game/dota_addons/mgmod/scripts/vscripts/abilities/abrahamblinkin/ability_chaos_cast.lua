LinkLuaModifier( "modifier_chaos_cast", "abilities/abrahamblinkin/ability_chaos_cast", LUA_MODIFIER_MOTION_NONE )

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

function modifier_chaos_cast:OnCreated()
  self["invoker_invoke"]              = { cast = false, spend = false }
  self["elder_titan_return_spirit"]   = { cast = true, spend = false }
  self["phoenix_launch_fire_spirit"]  = { cast = true, spend = false }
  self["shredder_chakram"]            = { cast = true, spend = true }
  self["shredder_chakram_2"]          = { cast = true, spend = true }
  self["shredder_return_chakram"]     = { cast = true, spend = false }
  self["shredder_return_chakram_2"]   = { cast = true, spend = false }
  self["ancient_apparition_ice_blast"] = { cast = true, spend = true }
  self["ancient_apparition_ice_blast_release"] = { cast = true, spend = false }
end

function modifier_chaos_cast:OnAbilityFullyCast( event )

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
    if self[ability:GetName()]~=nil and self[ability:GetName()].spend==false or self:GetAbility():GetCurrentAbilityCharges() >= 1 then
      local pos = ability:GetCursorPosition()

      if cast_type==DOTA_UNIT_ORDER_CAST_POSITION or cast_type==DOTA_UNIT_ORDER_CAST_NO_TARGET then
        local rand = RandomInt( 1, 10 )

        if rand > 7 then
          pos = caster:GetAbsOrigin() -- 70% chance to use target position instead of caster position
        end

        -- Logic for deciding whether to cahos cast and whether to spend charges
        
        local should_chaos_cast = self[ability:GetName()]==nil or self[ability:GetName()].cast==true
        local should_spend_charge = self[ability:GetName()]==nil or self[ability:GetName()].spend==true

        if should_chaos_cast then
          self:GetAbility():ChaosCastPointSpell( ability, pos ) -- Chaos-cast and also check whether there is secondary ability that should re-use the same units
        end

        if should_spend_charge then
          self:GetAbility():OnSpellStart()
        end

      elseif cast_type==DOTA_UNIT_ORDER_CAST_TARGET then
        -- print("casting unit target spell")
      end
    end
  end

end

-------------------
---- Ability Extra Logic
-------------------

function BeginCastStormRadial( caster, chaos_ability, ability_name, origin, cast_qty, delay, min_dist, max_dist )

  if IsClient() then return end

  chaos_ability.last_casters = {}

  local hero = caster
  local subcasters = GetIdleSubcasters( hero )

  chaos_ability.pos = {}

  for i=1,cast_qty do
    chaos_ability.pos[i] = GetRandomPointInRadius( origin, min_dist, max_dist )
    local unit = subcasters[i]

    -- print(unit)
    local ability = unit:FindAbilityByName( ability_name )
    if ability == nil then
      ability = unit:AddAbility(ability_name)
    end

    ability:SetLevel( chaos_ability:GetLevel() )
    ability:EndCooldown()
    -- table.insert( chaos_ability.abilities, ability )

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
    -- local radius = ability:GetSpecialValueFor("radius")
    -- chaos_ability:CreateIndicator( chaos_ability.pos[i], 2, radius )
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

function SplitSubcast( caster, chaos_ability, ability_name, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, vector_cast_rotation )

  if IsClient() then return end

  local hero = caster
  local subcasters = GetIdleSubcasters( hero )
  
  --------------
  -- Start logic for secondary abilities
  --------------

  local original_ability = hero:FindAbilityByName(ability_name)
  local has_secondary = GetReturnReleaseOrEndAbilityName( original_ability:GetName() )~=nil
  local is_secondary = IsReturnReleaseOrEndAbilityName( original_ability:GetName() )

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

  if is_secondary or original_ability.prepped_casters~=nil then

    -- DeepPrint(original_ability.prepped_casters)

    local previous_casters = original_ability.prepped_casters

    for i=1,#previous_casters do
      subcasters[i] = original_ability.prepped_casters[i]
    end
    cast_qty = #previous_casters

    if original_ability:GetName()=="phoenix_launch_fire_spirit" and original_ability:GetCurrentAbilityCharges()>0 then
      -- print("Launching fire spirits and NOT resetting prepped casters!")
    else
      original_ability.prepped_casters = {}
    end
    
    origin = hero:GetAbsOrigin()
    -- original_ability.prepped_casters = {}
  end

  --------------
  -- End Secondary Ability Logic
  --------------

  for i=1,cast_qty do
    local unit = subcasters[i]

    -- if unit==nil then return end
    
    unit:SetAbsOrigin( origin )
    -- unit.busy = true
    local angle_mult = i - 1 -- times to increment the angle, starting at 0 for the first iteration
    
    local y_degrees = offset_angle_degrees + ( angle_increment_degrees * angle_mult )
    local rotation = QAngle( 0, y_degrees, 0 )

    local random_degrees = vector_cast_rotation + ( angle_increment_degrees * angle_mult )
    local random_vector_rotation = QAngle( 0, random_degrees, 0 )
    local rand_rot_pos = unit:GetAbsOrigin() + ( unit:GetForwardVector() * ( dist_from_origin + dist_increment * i ) )

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

--SplitSubcast( ability_name, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, vector_cast_rotation)

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

  local subs = GetSubcasters( caster )
  if subs==nil then
    CreateSubcasters( caster, 21 )
  end

  -- print("Pattern is " .. pattern)

  if pattern==1 then -- casts your spell four in four rows, in an 'x' pattern around you. The four prongs of this 'x' shape are usually curved 
    local dist_increment = RandomInt( 100, 200 ) -- distance between each cast on each row
    local angle_increment_degrees = RandomInt(-7,7) -- curve of the four rows on your spell
    local delay = RandomInt(1,3)/16 -- how quickly to cast these spells in succession
    SplitSubcast( caster, ability, spellName, origin, original_angles, 3, delay, angle_increment_degrees*5, 0, 0, 150, dist_increment, 1, 1, vector_rotation ) -- prong in front of you
    SplitSubcast( caster, ability, spellName, origin, original_angles, 3, delay, angle_increment_degrees*5, 120, 0, 150, dist_increment, 1, 1, vector_rotation + 90 ) -- prong left of you
    SplitSubcast( caster, ability, spellName, origin, original_angles, 3, delay, angle_increment_degrees*5, 240, 0, 150, dist_increment, 1, 1, vector_rotation + 180 ) -- prong behind you
    -- SplitSubcast( caster, ability, spellName, origin, original_angles, 3, delay, angle_increment_degrees*5, 270, 0, 150, dist_increment, 1, 1, vector_rotation + 270 ) -- prong right of you

  elseif pattern==2 then -- casts your spell in x number of rows leading away from you (4 rows would make an 'x' around you). These spells cast instantly and are never curved.
    local rows = RandomInt(3,5) -- random number of prongs
    local dist_increment = RandomInt(50,100) -- distance between each cast on each row
    SplitSubcast( caster, ability, spellName, origin, original_angles, rows*4, 0, 360/rows, 0, 1, 130, dist_increment, 0.4, 0.4, vector_rotation ) -- three lines

  elseif pattern==3 then -- cast your ability in a wave in front of you
    local delay = RandomInt( 3, 10 ) / 10 -- time between waves
    local dist = RandomInt( 150, 250 ) -- distance between waves
    local spread = RandomInt( 30, 70 ) -- width of wave
    for i=1,3 do
      Timers:CreateTimer( delay*(i-1), function()
        SplitSubcast( caster, ability, spellName, origin, original_angles, 1+i, 0, spread*2/(2+i), -spread, dist*i, 300, 1, 1, 1, 0 )
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern==4 then -- instantly cast your ability in a ring around you
    local magnitude = RandomInt( 5, 10 )
    SplitSubcast( caster, ability, spellName, origin, original_angles, magnitude, 0, 360/magnitude, 0, 0, magnitude*40*posNeg, 0, 5/magnitude, 5/magnitude, vector_rotation*posNeg )
    
  elseif pattern==5 then -- spiral
    --SplitSubcast( caster, ability_name, spellname, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, rotation )`
    local magnitude = 10 -- distance between waves
    local rand = RandomInt(1,2)

    SplitSubcast( caster, ability, spellName, origin, original_angles, magnitude, 0.15, 45, 90, 0, 150, magnitude*7, 1, 1, vector_rotation ) -- progressive spiral
    if rand==1 then
      SplitSubcast( caster, ability, spellName, origin, original_angles, magnitude, 0.15, 45*posNeg, 270, 0, 150, magnitude*7, 1, 1, vector_rotation ) -- flipped progressive spiral
    end
    -- SplitSubcast( caster, ability, spellName, origin, original_angles, magnitude, 0.15, 30, -90, 0, 1, magnitude*3, 1, 1, vector_rotation ) -- progressive spiral
    -- SplitSubcast( caster, ability, spellName, origin, original_angles, 12, 0.1, 25, 180, 150*posNeg, 1, 60, 1, 1 ) -- progressive spiral

  elseif pattern==6 then -- cast a totally random 'storm' of your spell in an area around you
    BeginCastStormRadial( caster, ability, spellName, origin, 10, 0.25, 100, 600 )

  elseif pattern==7 then -- Cast multiple times, crawling forward each cast, with growing radius
    -- local vector_rotation = RandomInt(1,360)
    local rand = RandomInt(3,6)
    for i=1,rand do
      Timers:CreateTimer( 0.2*i, function()
        SplitSubcast( caster, ability, spellName, ability:GetCaster():GetAbsOrigin(), original_angles, 1, 0, 0, 0, 0, 75, 300*i, 0.5 * i, 0.3*i, 0 ) -- progressive spiral
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern==8 then -- repeatedly cast your ability in a growing ring around you

    SplitSubcast( caster, ability, spellName, origin, original_angles, 5, 0, 360/5, 0, 150, 150, 0, 1, 1, vector_rotation*posNeg )

      Timers:CreateTimer( 1, function()
        SplitSubcast( caster, ability, spellName, origin, original_angles, 8, 0, 360/8, 0, 300, 150, 0, 1.3, 1, vector_rotation*posNeg2 )
        self.RemoveSelf = true
        return nil
      end)

  elseif pattern==9 then
    for i=1,4 do
      Timers:CreateTimer( 1*i, function()
        SplitSubcast( caster, ability, spellName, origin, original_angles, 1, 0, 0, 0, 150*i, 150, 0, 1, 1, vector_rotation )
        SplitSubcast( caster, ability, spellName, origin, original_angles, 1, 0, 0, 0, 150*i, 150, 0, 1, 1, -vector_rotation )
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern==10 then
    for i=1,3 do
      local angle = RandomInt(20,35)
      Timers:CreateTimer( 1*i, function()
        SplitSubcast( caster, ability, spellName, origin, original_angles, 1, 0, 0, angle, 200*i, 150, 0, 1, 1, vector_rotation )
        SplitSubcast( caster, ability, spellName, origin, original_angles, 1, 0, 0, -angle, 200*i, 150, 0, 1, 1, -vector_rotation )
        self.RemoveSelf = true
        return nil
      end)
    end
  end

end

function GetReturnReleaseOrEndAbilityName( name )

  if name=="elder_titan_ancestral_spirit" then
    return "elder_titan_return_spirit"

  elseif name=="phoenix_fire_spirits" then
    return "phoenix_launch_fire_spirit"

  elseif name=="shredder_chakram" then
    return "shredder_return_chakram"

  elseif name=="shredder_chakram_2" then
    return "shredder_return_chakram_2"

  elseif name=="ancient_apparition_ice_blast" then
    return "ancient_apparition_ice_blast_release"

  end

  return nil
end

function IsReturnReleaseOrEndAbilityName( name )

  if name=="elder_titan_return_spirit" then
    return true

  elseif name=="phoenix_launch_fire_spirit" then
    return true

  elseif name=="shredder_return_chakram" then
    return true

  elseif name=="shredder_return_chakram_2" then
    return true

  elseif name=="ancient_apparition_ice_blast_release" then
    return true

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
    local unit = CreateUnitByName( "npc_dota_subcaster", hero:GetOrigin(), false, hero, self, hero:GetTeam() )
    
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
      -- subcs[i]:Stop()
      subcs[i]:SetMana(600)
      table.insert( idle, subcs[i] )
      -- return subcs[i]
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