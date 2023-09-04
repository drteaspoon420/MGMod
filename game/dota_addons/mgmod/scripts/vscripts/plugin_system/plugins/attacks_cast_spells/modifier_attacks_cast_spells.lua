if modifier_attacks_cast_spells == nil then
    modifier_attacks_cast_spells = class({})
end

function modifier_attacks_cast_spells:OnCreated(keys)
    if not IsServer() then return end
    local hHero = self:GetParent()

    self.args = {
        procChance = AttacksCastSpellsPlugin.settings.ACSP_PROC,
        itemProcChance = AttacksCastSpellsPlugin.settings.ACSP_PROC_ITEM,
        problematicChance = AttacksCastSpellsPlugin.settings.ACSP_PROC_PROBLEM,
        illProcChance = AttacksCastSpellsPlugin.settings.ACSP_PROC_ILL,
        noultimate = AttacksCastSpellsPlugin.settings.ACSP_NO_ULT,
        lastSpell = AttacksCastSpellsPlugin.settings.ACSP_NO_RANDOM,
        strict = AttacksCastSpellsPlugin.settings.ACSP_STRICT,
        dsilence = AttacksCastSpellsPlugin.settings.ACSP_SILENCE,
        dbreak = AttacksCastSpellsPlugin.settings.ACSP_BREAK,
        dimmune = AttacksCastSpellsPlugin.settings.ACSP_IMMUNE,
        btrolls = AttacksCastSpellsPlugin.settings.ACSP_TROLLS,
        proc_damage = AttacksCastSpellsPlugin.settings.ACSP_PROC_MODE,
        proc_reverse = false,
    }
    --Deep--printTable(self.args)
    if self.args.btrolls then
        --Deep--printTable(AttacksCastSpellsPlugin.lists.normal)
        --Deep--printTable(AttacksCastSpellsPlugin.lists.illusion)
        self.trolls = AttacksCastSpellsPlugin.lists.normal
        self.ill_trolls = AttacksCastSpellsPlugin.lists.illusion
    else
        self.trolls = {}
        self.ill_trolls = {}
    end
    self.problematic = AttacksCastSpellsPlugin.lists.problematic
    self.channelSpecial = AttacksCastSpellsPlugin.lists.channelspecial
    self.ACSP_CHAOS = AttacksCastSpellsPlugin.settings.ACSP_CHAOS
end


function modifier_attacks_cast_spells:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ABILITY_EXECUTED,MODIFIER_EVENT_ON_ATTACK_LANDED,MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_attacks_cast_spells:CheckCreep(npc)
	local name = npc:GetUnitName()
	if (name ~= nil and string.find(name,"npc_dota_creep_") ~= nil) then return true end
	return false
end

function modifier_attacks_cast_spells:OnAbilityExecuted(keys)
    if not IsServer() then return end
    if keys.unit ~= self:GetParent() then return end
    if not keys.ability:IsItem() and not self:InList(self.trolls,keys.ability)  then
        if self:CheckOption(self.args.noultimate) and keys.ability:GetAbilityType() == 1  then return end
        self.last_spell = keys.ability:GetAbilityIndex()
    end
end

function modifier_attacks_cast_spells:GetRandomSpellChaos()
    local tPossible = {}
    local iTeam = self:GetParent():GetTeam()
    for i=0, DOTA_MAX_TEAM_PLAYERS do
            if PlayerResource:IsValidPlayer(i) then
                local player = PlayerResource:GetPlayer(i)
                local hHero = player:GetAssignedHero()
                if hHero ~= nil and hHero:GetTeam() == iTeam then
                for i = 0, hHero:GetAbilityCount()-1 do 
                    local hAbility = hHero:GetAbilityByIndex(i)
                    if (hAbility) then
                        local ultimateSkip = (self:CheckOption(self.args.noultimate) and hAbility:GetAbilityType() == 1 )
                        if not ultimateSkip then
                            if not hAbility:IsHidden() and not hAbility:IsToggle() and hAbility:IsTrained() and not hAbility:IsPassive() and not self:InList(self.trolls,hAbility)then
                                if not self:CheckProblematic(hAbility) then
                                    if not (hHero:IsIllusion() or hHero:IsTempestDouble()) or not self:InList(self.ill_trolls,hAbility) then
                                        tPossible[#tPossible+1] = hAbility
                                    end
                                end
                            end
                        end
                    end
                end


                if self.args.itemProcChance > 0 then
                    for i = 0, 5 do 
                        local hAbility = hHero:GetItemInSlot(i)
                            if (hAbility ~= nil) then
                            if (self:CheckItem(hAbility))then
                                if not (hHero:IsIllusion() or hHero:IsTempestDouble()) or not self:InList(self.ill_trolls,hAbility) then
                                    tPossible[#tPossible+1] = hAbility
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if #tPossible > 0 then
        return  tPossible[RandomInt(1,#tPossible)]
    end
    return nil
end
function modifier_attacks_cast_spells:GetRandomSpell()
    if self.ACSP_CHAOS then
        return self:GetRandomSpellChaos()
    end
    local tPossible = {}
    local hHero = self:GetParent()
    for i = 0, hHero:GetAbilityCount()-1 do 
        local hAbility = hHero:GetAbilityByIndex(i)
        if (hAbility) then
            local ultimateSkip = (self:CheckOption(self.args.noultimate) and hAbility:GetAbilityType() == 1 )
            if not ultimateSkip then
                if not hAbility:IsHidden() and not hAbility:IsToggle() and hAbility:IsTrained() and not hAbility:IsPassive() and not self:InList(self.trolls,hAbility)then
                    if not self:CheckProblematic(hAbility) then
                        if not (hHero:IsIllusion() or hHero:IsTempestDouble()) or not self:InList(self.ill_trolls,hAbility) then
                            tPossible[#tPossible+1] = hAbility
                        end
                    end
                end
            end
        end
    end


    if self.args.itemProcChance > 0 then
        for i = 0, 5 do 
            local hAbility = hHero:GetItemInSlot(i)
                if (hAbility ~= nil) then
                if (self:CheckItem(hAbility))then
                    if not (hHero:IsIllusion() or hHero:IsTempestDouble()) or not self:InList(self.ill_trolls,hAbility) then
                        tPossible[#tPossible+1] = hAbility
                    end
                end
            end
        end
    end
    if #tPossible > 0 then
        return  tPossible[RandomInt(1,#tPossible)]
    end
    return nil
end

function modifier_attacks_cast_spells:CheckItem(hAbility)
    if hAbility:IsItem() and not hAbility:IsPassive() and not self:InList(self.trolls,hAbility) then
        if (RandomInt(0,100) < self.args.itemProcChance) then
            return true;
        end
    end
    return false;
end

function modifier_attacks_cast_spells:GetLastSpell()
    if not self.last_spell or self.last_spell == -1 then
        local hIllLast = self:GetRandomSpell()
        if (hIllLast) then
            self.last_spell = hIllLast:GetAbilityIndex()
        else
            self.last_spell = -1
        end
    end
    if self.last_spell and self.last_spell > -1 then
        local hHero = self:GetParent()
        local hAbility = self:GetParent():GetAbilityByIndex(self.last_spell)
        if not self:CheckProblematic(hAbility) then
            if not hHero:IsIllusion() or not self:InList(self.ill_trolls,hAbility) then
                return hAbility
            end
        end
    end
    return nil
end

function modifier_attacks_cast_spells:CastASpell(hTarget)
    local hHero = self:GetParent()
    local chance = 1
    if hHero.IsIllusion and hHero:IsIllusion() then
        chance = chance * self.args.illProcChance
    else
        chance = chance * self.args.procChance
    end
    if (RandomInt(0,100) > chance) then return end
    local hAbility
    if self:CheckOption(self.args.lastSpell)  then
        hAbility = self:GetLastSpell()
    else
        hAbility = self:GetRandomSpell()
    end
    if (hAbility) then
        local nTeam = hAbility:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_BOTH
        local nFlags = hAbility:GetAbilityTargetType() or DOTA_UNIT_TARGET_ALL
        local nBehav = hAbility:GetBehavior()
        local hSpellTarget = hTarget
        if (self:FlagCheck(nBehav,DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)) and not (self:FlagCheck(nBehav,DOTA_ABILITY_BEHAVIOR_POINT)) then
            if self:CheckOption(self.args.strict) then
                hSpellTarget = self:FindStrictTarget(hAbility,hTarget)
            else
                if (nTeam == DOTA_UNIT_TARGET_TEAM_FRIENDLY) then
                    hSpellTarget = self:FindTarget(DOTA_UNIT_TARGET_TEAM_FRIENDLY,DOTA_UNIT_TARGET_ALL,hTarget,hAbility)
                else
                    hSpellTarget = self:FindTarget(DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_ALL,hTarget,hAbility)
                end
            end
        end
        if (hSpellTarget) then
            local hCaster = hAbility:GetCaster()
            if (AttacksCastSpellsPlugin.settings.ACSP_DELAY > 0) then
                Timers:CreateTimer(AttacksCastSpellsPlugin.settings.ACSP_DELAY, function()
                    hCaster:SetCursorCastTarget(hSpellTarget)
                    hCaster:SetCursorPosition(hSpellTarget:GetAbsOrigin())
                    if (not hSpellTarget:TriggerSpellAbsorb(hAbility)) then
                        if (AttacksCastSpellsPlugin.settings.ACSP_MODERN == 1) then
                            local storedcooldown = hAbility:GetCooldownTimeRemaining()
                            local storedmanacost = hAbility:GetManaCost(hAbility:GetLevel())
                            hAbility:EndCooldown()
                            hCaster:CastAbilityImmediately(hAbility,hCaster:GetPlayerOwnerID())
                            hAbility:EndCooldown()
                            if (storedcooldown > 0) then
                                hAbility:StartCooldown(storedcooldown)
                            end
                            hCaster:GiveMana(storedmanacost)
                        else
                            if (self:FlagCheck(nBehav,DOTA_ABILITY_BEHAVIOR_CHANNELLED)) then
                                self:CreateSpellBomb(hSpellTarget,hAbility)
                            else
                                hAbility:OnAbilityPhaseStart()
                                hAbility:OnSpellStart()
                            end
                        end
                    end
                end)
            else
                hCaster:SetCursorCastTarget(hSpellTarget)
                hCaster:SetCursorPosition(hSpellTarget:GetAbsOrigin())
                if (not hSpellTarget:TriggerSpellAbsorb(hAbility)) then
                    if (AttacksCastSpellsPlugin.settings.ACSP_MODERN == 1) then
                        local storedcooldown = hAbility:GetCooldownTimeRemaining()
                        local storedmanacost = hAbility:GetManaCost(hAbility:GetLevel())
                        hAbility:EndCooldown()
                        hCaster:CastAbilityImmediately(hAbility,hCaster:GetPlayerOwnerID())
                        hAbility:EndCooldown()
                        if (storedcooldown > 0) then
                            hAbility:StartCooldown(storedcooldown)
                        end
                        hCaster:GiveMana(storedmanacost)
                    else
                        if (self:FlagCheck(nBehav,DOTA_ABILITY_BEHAVIOR_CHANNELLED)) then
                            self:CreateSpellBomb(hSpellTarget,hAbility)
                        else
                            hAbility:OnAbilityPhaseStart()
                            hAbility:OnSpellStart()
                        end
                    end
                end
            end
           -- end
        end
    end
end

function modifier_attacks_cast_spells:CheckOption(op)
    return (op == 1 or op == true)
end

function modifier_attacks_cast_spells:CreateSpellBomb(hTarget,hAbility)
    local sAbility = hAbility:GetName()
    local iLevel = hAbility:GetLevel()
    local sSecond
    local sThird
    if hAbility.GetAssociatedPrimaryAbilities ~= nil then
        sSecond = hAbility:GetAssociatedPrimaryAbilities()
    end
    if hAbility.GetAssociatedSecondaryAbilities ~= nil then
        sThird = hAbility:GetAssociatedSecondaryAbilities()
    end
    
    CreateUnitByNameAsync("npc_dota_spell_bomb",self:GetParent():GetAbsOrigin(),true,self:GetParent(),self:GetParent(),self:GetParent():GetTeam(),
        function(hNpc)
        Timers:CreateTimer( 0, function ()
            local hAbility = hNpc:AddAbility(sAbility)
            if sSecond then hNpc:AddAbility(sSecond):SetLevel(iLevel) end
            if sThird then hNpc:AddAbility(sThird):SetLevel(iLevel) end
            hAbility:SetLevel(iLevel)
            hAbility:SetHidden(false)
            Timers:CreateTimer( 0, function()
                local hMod = hNpc:FindModifierByName("channelled_bomb_modifier")
                if hMod then
                    hMod:SetTarget(hAbility,hTarget)
                else
                    hNpc:ForceKill(false)
                end
                return nil
            end)
            return nil
        end)
    end)
end
function modifier_attacks_cast_spells:OnTakeDamage(keys)
    if not IsServer() then return end
    if not self.args.proc_damage then return end
    local hTarget = keys.unit
    local hHero = keys.attacker
    if self.args.proc_reverse and hTarget == self:GetParent() then
        if not hTarget:IsAlive() then return end
        if not hHero:IsAlive() then return end
        if hTarget:IsSilenced() and self:CheckOption(self.args.dsilence) then return end
        if hTarget:PassivesDisabled() and self:CheckOption(self.args.dbreak) then return end
        if hHero:IsMagicImmune() and self:CheckOption(self.args.dimmune) then return end
        if hHero:HasModifier("modifier_fountain_glyph") then return end
        self:CastASpell(hHero)
    elseif not self.args.proc_reverse and hHero == self:GetParent() then
        if not hTarget:IsAlive() then return end
        if not hHero:IsAlive() then return end
        if hHero:IsSilenced() and self:CheckOption(self.args.dsilence) then return end
        if hHero:PassivesDisabled() and self:CheckOption(self.args.dbreak) then return end
        if hTarget:IsMagicImmune() and self:CheckOption(self.args.dimmune) then return end
        if hTarget:HasModifier("modifier_fountain_glyph") then return end
        self:CastASpell(hTarget)
    end
end

function modifier_attacks_cast_spells:OnAttackLanded(keys)
    if not IsServer() then return end
    if self.args.proc_damage then return end
    local hTarget = keys.target
    local hHero = keys.attacker
    if self.args.proc_reverse and hTarget == self:GetParent() then
        if not hTarget:IsAlive() then return end
        if not hHero:IsAlive() then return end
        if hTarget:IsSilenced() and self:CheckOption(self.args.dsilence) then return end
        if hTarget:PassivesDisabled() and self:CheckOption(self.args.dbreak) then return end
        if hHero:IsMagicImmune() and self:CheckOption(self.args.dimmune) then return end
        if hHero:HasModifier("modifier_fountain_glyph") then return end
        self:CastASpell(hHero)
    elseif not self.args.proc_reverse and hHero == self:GetParent() then
        if not hTarget:IsAlive() then return end
        if not hHero:IsAlive() then return end
        if hHero:IsDisarmed() then return end
        if hHero:IsSilenced() and self:CheckOption(self.args.dsilence) then return end
        if hHero:PassivesDisabled() and self:CheckOption(self.args.dbreak) then return end
        if hTarget:IsMagicImmune() and self:CheckOption(self.args.dimmune) then return end
        if hTarget:HasModifier("modifier_fountain_glyph") then return end
        self:CastASpell(hTarget)
    end
end

function modifier_attacks_cast_spells:FlagCheck(iFlags,i)
    return (bit.band(iFlags,i) == i)
end

function modifier_attacks_cast_spells:FlagFilter(nTeam,nFlags,hTarget,hHero)
    if (self:FlagCheck(nTeam ,DOTA_UNIT_TARGET_TEAM_FRIENDLY) and hTarget:GetTeamNumber() ~= hHero:GetTeamNumber()) then return 1 end
    if (self:FlagCheck(nTeam ,DOTA_UNIT_TARGET_TEAM_ENEMY) and hTarget:GetTeamNumber() == hHero:GetTeamNumber()) then return 1 end
    if (self:FlagCheck(nFlags ,DOTA_UNIT_TARGET_BUILDING) and hTarget:IsBuilding()) then return 0 end
    if (self:FlagCheck(nFlags ,DOTA_UNIT_TARGET_CREEP) and hTarget:IsCreep()) then return 0 end
    if (self:FlagCheck(nFlags ,DOTA_UNIT_TARGET_HERO) and hTarget:IsHero()) then return 0 end
    if (self:FlagCheck(nFlags ,DOTA_UNIT_TARGET_BASIC) and hTarget:IsCreature()) then return 0 end
    if (self:FlagCheck(nFlags ,DOTA_UNIT_TARGET_CUSTOM) and (hTarget:IsCreep() and (hTarget:IsNeutralUnitType() and not hTarget:IsAncient()))) then return 0 end
    return 2
end

function modifier_attacks_cast_spells:FindStrictTarget(hAbility,hcTarget)
    local hHero = self:GetParent()
    local nTeam = hAbility:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_BOTH
    local nFlags = hAbility:GetAbilityTargetType() or DOTA_UNIT_TARGET_ALL
    local nBehav = hAbility:GetBehavior()
    if (self:FlagCheck(nBehav,DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)) then
        local nRes = self:FlagFilter(nTeam,nFlags,hcTarget,hHero) 
        if nRes == 0 then
            return hcTarget
        end
        local vPos = hcTarget:GetAbsOrigin()
        local tTargets = FindUnitsInRadius( hHero:GetTeamNumber(), vPos, nil, 500, nTeam, nFlags, 0, FIND_FARTHEST, false )
        local hEnemy = nil
        hcTarget = nil
        local hFriendly = hHero
        if #tTargets > 0 then
            for _,hTarget in pairs(tTargets) do
                if hTarget ~= nil and ( not hTarget:IsMagicImmune() ) and ( not hTarget:IsInvulnerable() ) then
                    if self:FlagFilter(nTeam,nFlags,hTarget,hHero) == 0 then
                        if (hHero:CanEntityBeSeenByMyTeam(hTarget)) then
                            hcTarget = hTarget
                        end
                    end
                end
            end
        end
    elseif (self:FlagCheck(nTeam,DOTA_UNIT_TARGET_TEAM_FRIENDLY)) then
        hcTarget = hHero
    end
    return hcTarget
end

function modifier_attacks_cast_spells:FindTarget(nTeam,nFlags,hcTarget,hAbility)
    local hHero = self:GetParent()
    local nTeam = hAbility:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_BOTH
    local nBehav = hAbility:GetBehavior()
    if (self:FlagCheck(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET,nBehav)) then
        local nRes = self:FlagFilter(nTeam,DOTA_UNIT_TARGET_ALL,hcTarget,hHero)
        if nRes == 0 then
            return hcTarget
        end
        local vPos = hHero:GetAbsOrigin()
        local tTargets = FindUnitsInRadius( hHero:GetTeamNumber(), vPos, nil, 500, nTeam, nFlags, 0, FIND_FARTHEST, false )
        local hEnemy = nil
        local hFriendly = hHero
        if #tTargets > 0 then
            for _,hTarget in pairs(tTargets) do
                if hTarget ~= nil and ( not hTarget:IsMagicImmune() ) and ( not hTarget:IsInvulnerable() ) then
                    if (hHero:CanEntityBeSeenByMyTeam(hTarget)) then
                        hcTarget = hTarget
                    end
                end
            end
        end
    elseif (self:FlagCheck(DOTA_UNIT_TARGET_TEAM_FRIENDLY,nTeam)) then
        hcTarget = hHero
    end
    return hcTarget
end

function modifier_attacks_cast_spells:IsDebuff() return false end
function modifier_attacks_cast_spells:DestroyOnExpire() return false end
function modifier_attacks_cast_spells:IsDebuff() return false end
function modifier_attacks_cast_spells:IsHidden() return true end
function modifier_attacks_cast_spells:IsPermanent() return true end
function modifier_attacks_cast_spells:IsPurgable() return false end
function modifier_attacks_cast_spells:IsPurgeException() return false end
function modifier_attacks_cast_spells:IsStunDebuff() return false end
function modifier_attacks_cast_spells:AllowIllusionDuplicate() return true end
function modifier_attacks_cast_spells:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT end


function modifier_attacks_cast_spells:CheckTrollAbility(hAbility)
    local name = hAbility:GetAbilityName()
    for k,v in pairs(self.trolls) do
        if (name == v) then return true end
    end
    return false
end

function modifier_attacks_cast_spells:CheckProblematic(hAbility)
    local name = hAbility:GetAbilityName()
    for k,v in pairs(self.problematic) do
        if (name == k) then
            if self.args.problematicChance < 100 then
                return (RandomInt(0,100) > self.args.problematicChance)
            else
                return false
            end
        end
    end
    return false
end

function modifier_attacks_cast_spells:InList(list,hAbility)
    --Deep--printTable(list)
    if (list ~= nil) then
        local name = hAbility:GetAbilityName()
        --print(name)
        return (list[name] ~= nil)
    end
    return true
end