class PokeBattle_Battler
    def getPlainStat(stat, aiCheck = false)
        case stat
        when :ATTACK
            return attack(aiCheck)
        when :DEFENSE
            return defense(aiCheck)
        when :SPECIAL_ATTACK
            return spatk(aiCheck)
        when :SPECIAL_DEFENSE
            return spdef(aiCheck)
        when :SPEED
            return speed(aiCheck)
        end
        return -1
    end

    def plainStats
        ret = {}
        ret[:ATTACK]          = attack
        ret[:DEFENSE]         = defense
        ret[:SPECIAL_ATTACK]  = spatk
        ret[:SPECIAL_DEFENSE] = spdef
        ret[:SPEED]           = speed
        return ret
    end

    def tribalBonusForStat(stat)
        return 0 unless owner
        return owner.tribalBonus.getTribeBonusStats(self)[stat]
    end

    def allStatBonus
        return 0
    end

    def puzzleRoom?
        return @battle.field.effectActive?(:PuzzleRoom)
    end

    def oddRoom?
        return @battle.field.effectActive?(:OddRoom)
    end

    def wonderRoom?
        return false
    end

    def attack(aiCheck = false)
        if puzzleRoom? && oddRoom?
            return base_special_defense(aiCheck)
        elsif puzzleRoom? && !oddRoom?
            return base_special_attack(aiCheck)
        elsif oddRoom? && !puzzleRoom?
            return base_defense(aiCheck)
        else
            return base_attack(aiCheck)
        end
    end

    def defense(aiCheck = false)
        if wonderRoom? && oddRoom?
            return base_special_attack(aiCheck)
        elsif wonderRoom? && !oddRoom?
            return base_special_defense(aiCheck)
        elsif oddRoom? && !wonderRoom?
            return base_attack(aiCheck)
        else
            return base_defense(aiCheck)
        end
    end

    def spatk(aiCheck = false)
        if puzzleRoom? && oddRoom?
            return base_defense(aiCheck)
        elsif puzzleRoom? && !oddRoom?
            return base_attack(aiCheck)
        elsif oddRoom? && !puzzleRoom?
            return base_special_defense(aiCheck)
        else
            return base_special_attack(aiCheck)
        end
    end

    def spdef(aiCheck = false)
        if wonderRoom? && oddRoom?
            return base_attack(aiCheck)
        elsif wonderRoom? && !oddRoom?
            return base_defense(aiCheck)
        elsif oddRoom? && !wonderRoom?
            return base_special_attack(aiCheck)
        else
            return base_special_defense(aiCheck)
        end
    end

    OFFENSIVE_LOCK_STAT = 120

    DEFENSIVE_LOCK_STAT = 95

    def speed(aiCheck = false)
        return base_speed
    end

    # Don't use for HP
    def recalcStat(stat, base)
        return calcStatGlobal(base, @level, @pokemon.ev[stat], stylish: hasActiveAbility?(:STYLISH), accumulation: hasActiveAbility?(:ACCUMULATION))
    end

    def base_attack(aiCheck = false)
        return @effects[:BaseAttack] if effectActive?(:BaseAttack)
        attack_bonus = tribalBonusForStat(:ATTACK)
        attack_bonus += allStatBonus
        if hasActiveItem?(%i[POWERLOCK POWERKEY]) && !aiHidesStatItem?(:POWERLOCK, aiCheck)
            return recalcStat(:ATTACK, OFFENSIVE_LOCK_STAT) + attack_bonus
        else
            return @attack + attack_bonus
        end
    end

    def base_defense(aiCheck = false)
        return @effects[:BaseDefense] if effectActive?(:BaseDefense)
        defense_bonus = tribalBonusForStat(:DEFENSE)
        defense_bonus += allStatBonus
        if hasActiveItem?(:GUARDLOCK)
            return recalcStat(:DEFENSE, DEFENSIVE_LOCK_STAT) + defense_bonus
        elsif hasActiveItem?(:POWERKEY)
            return recalcStat(:DEFENSE, OFFENSIVE_LOCK_STAT) + defense_bonus
        else
            return @defense + defense_bonus
        end
    end

    def base_special_attack(aiCheck = false)
        return @effects[:BaseSpecialAttack] if effectActive?(:BaseSpecialAttack)
        spatk_bonus = tribalBonusForStat(:SPECIAL_ATTACK)
        spatk_bonus += allStatBonus
        if hasActiveItem?(%i[ENERGYLOCK ENERGYKEY]) && !aiHidesStatItem?(:ENERGYLOCK, aiCheck)
            return recalcStat(:SPECIAL_ATTACK, OFFENSIVE_LOCK_STAT) + spatk_bonus
        else
            return @spatk + spatk_bonus
        end
    end

    def base_special_defense(aiCheck = false)
        return @effects[:BaseSpecialDefense] if effectActive?(:BaseSpecialDefense)
        spdef_bonus = tribalBonusForStat(:SPECIAL_DEFENSE)
        spdef_bonus += allStatBonus
        if hasActiveItem?(:WILLLOCK)
            return recalcStat(:SPECIAL_DEFENSE, DEFENSIVE_LOCK_STAT) + spdef_bonus
        elsif hasActiveItem?(:ENERGYKEY)
            return recalcStat(:SPECIAL_DEFENSE, OFFENSIVE_LOCK_STAT) + spdef_bonus
        else
            return @spdef + spdef_bonus
        end
    end

    def base_speed
        return @effects[:BaseSpeed] if effectActive?(:BaseSpeed)
        speed_bonus = tribalBonusForStat(:SPEED)
        speed_bonus += allStatBonus
        return @speed + speed_bonus
    end

    #=============================================================================
    # Query about stats after room modification, steps, abilities and item modifiers.
    #=============================================================================
    AI_CHEATS_FOR_STAT_ABILITIES = true

    # When false, the AI estimates an opposing player-owned battler's stats as if
    # it were not holding certain disguising stat items, until the item reveals
    # itself through real (non-AI) use. Set true to let the AI always see them.
    AI_CHEATS_FOR_STAT_ITEMS = false

    # Held items whose stat contribution is hidden from the AI's stat/damage
    # estimates until revealed. Split by how the item becomes evident in battle,
    # which drives WHEN each is revealed (see revealActedHiddenStatItems /
    # revealHitHiddenStatItems and their call sites). The reveal is event-driven,
    # never triggered by a stat read.
    #   offensive -> revealed when the holder takes its action (inflated damage)
    #   speed     -> revealed when the holder takes its action (turn order seen)
    #   defensive -> revealed when the holder is hit by a real damaging move
    AI_HIDDEN_OFFENSIVE_ITEMS = %i[CHOICEBAND CHOICESPECS POWERLOCK ENERGYLOCK]
    AI_HIDDEN_SPEED_ITEMS     = %i[CHOICESCARF SEVENLEAGUEBOOTS]
    AI_HIDDEN_DEFENSIVE_ITEMS = %i[ASSAULTVEST STRIKEVEST]
    AI_HIDDEN_STAT_ITEMS = (AI_HIDDEN_OFFENSIVE_ITEMS + AI_HIDDEN_SPEED_ITEMS + AI_HIDDEN_DEFENSIVE_ITEMS).freeze

    # True when the AI should not yet see this held item's stat contribution: it
    # is a hidden stat item on a player-owned battler that the AI has not learned,
    # and this is an AI estimate (aiCheck) with the item cheat disabled. Accepts a
    # single item id or an array (any matching held item triggers hiding).
    def aiHidesStatItem?(item, aiCheck)
        return false unless aiCheck
        return false if AI_CHEATS_FOR_STAT_ITEMS
        return false unless pbOwnedByPlayer?
        return Array(item).any? do |singleItem|
            AI_HIDDEN_STAT_ITEMS.include?(singleItem) &&
                hasActiveItem?(singleItem) &&
                !aiKnowsItem?(singleItem)
        end
    end

    # Reveal any of the given hidden stat items this player-owned battler actually
    # holds. Reveal is driven by observable battle EVENTS (the call sites below),
    # never by a stat-calc method -- a stat read must never reveal an item, or
    # routine real stat computations (turn-order priority, finalStats inside move
    # effects, etc.) would mark items known before the AI ever estimates.
    def revealHiddenStatItems(*items)
        return unless pbOwnedByPlayer?
        items.flatten.each do |singleItem|
            next unless AI_HIDDEN_STAT_ITEMS.include?(singleItem)
            next unless hasActiveItem?(singleItem)
            next if aiKnowsItem?(singleItem)
            aiLearnsItem(singleItem)
        end
    end

    # Call when this battler takes its action (uses a move): its offensive and
    # speed disguising items become evident (inflated damage / observed turn order).
    def revealActedHiddenStatItems
        revealHiddenStatItems(*AI_HIDDEN_OFFENSIVE_ITEMS, *AI_HIDDEN_SPEED_ITEMS)
    end

    # Call when this battler is hit by a real damaging move: its defensive
    # disguising items become evident (the attacker's damage came up short).
    def revealHitHiddenStatItems
        revealHiddenStatItems(*AI_HIDDEN_DEFENSIVE_ITEMS)
    end

    def pbAttack(aiCheck = false, step = nil)
        return 1 if fainted? && !dummy?
        attack = statAfterStep(:ATTACK, step, aiCheck)
        attackMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            attackMult = BattleHandlers.triggerAttackCalcUserAbility(ability, self, @battle, attackMult)
        end
        eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                next if ally.ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
                attackMult = BattleHandlers.triggerAttackCalcAllyAbility(ability, self, @battle, attackMult)
            end
        end

        eachActiveItem do |item|
            next if aiHidesStatItem?(item, aiCheck)
            attackMult = BattleHandlers.triggerAttackCalcUserItem(item, self, battle, attackMult)
        end

        # Dragon Ride
        attackMult *= 2.0 if effectActive?(:OnDragonRide)

        # Calculation
        return [(attack * attackMult).round, 1].max
    end

    def pbSpAtk(aiCheck = false, step = nil)
        return 1 if fainted? && !dummy?
        special_attack = statAfterStep(:SPECIAL_ATTACK, step, aiCheck)
        spAtkMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            spAtkMult = BattleHandlers.triggerSpecialAttackCalcUserAbility(ability, self, @battle, spAtkMult)
        end
        eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                next if ally.ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
                spAtkMult = BattleHandlers.triggerSpecialAttackCalcAllyAbility(ability, self, @battle, spAtkMult)
            end
        end

        eachActiveItem do |item|
            next if aiHidesStatItem?(item, aiCheck)
            spAtkMult = BattleHandlers.triggerSpecialAttackCalcUserItem(item, self, battle, spAtkMult)
        end

        # Calculation
        return [(special_attack * spAtkMult).round, 1].max
    end

    def pbDefense(aiCheck = false, step = nil)
        return 1 if fainted? && !dummy?
        defense = statAfterStep(:DEFENSE, step, aiCheck)
        defenseMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            defenseMult = BattleHandlers.triggerDefenseCalcUserAbility(ability, self, @battle, defenseMult)
        end
        eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                next if ally.ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
                defenseMult = BattleHandlers.triggerDefenseCalcAllyAbility(ability, self, @battle, defenseMult)
            end
        end

        eachActiveItem do |item|
            next if aiHidesStatItem?(item, aiCheck)
            defenseMult = BattleHandlers.triggerDefenseCalcUserItem(item, self, battle, defenseMult)
        end

        defenseMult *= 1.3 if hasTribeBonus?(:SCRAPPER)
        defenseMult *= 1.5 if pbOwnSide.effectActive?(:AutumnHarvests)

        # Hail and Ice Age
        if @battle.icy? && (pbHasType?(:ICE) || (pbHasType?(:GHOST) && @battle.pbWeather == :IceAge))
            hailAddition = 0.5
            hailAddition *= 2 if @battle.pbCheckGlobalAbility(:BITTERCOLD)
            hailAddition *= 2 if @battle.curseActive?(:CURSE_BOOSTED_HAIL)
            defenseMult *= (1 + hailAddition)
        end

        # Calculation
        return [(defense * defenseMult).round, 1].max
    end

    def pbSpDef(aiCheck = false, step = nil)
        return 1 if fainted? && !dummy?
        special_defense = statAfterStep(:SPECIAL_DEFENSE, step, aiCheck)
        spDefMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            spDefMult = BattleHandlers.triggerSpecialDefenseCalcUserAbility(ability, self, @battle, spDefMult)
        end
        eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                spDefMult = BattleHandlers.triggerSpecialDefenseCalcAllyAbility(ability, self, @battle, spDefMult)
            end
        end

        eachActiveItem do |item|
            next if aiHidesStatItem?(item, aiCheck)
            spDefMult = BattleHandlers.triggerSpecialDefenseCalcUserItem(item, self, battle, spDefMult)
        end

        spDefMult *= 1.3 if hasTribeBonus?(:RADIANT)
        spDefMult *= 1.5 if pbOwnSide.effectActive?(:SpringPlantings)

        # Sandstorm and Star Storm
        if @battle.sandy? && (pbHasType?(:ROCK) || (pbHasType?(:GROUND) && @battle.pbWeather == :StarStorm))
            sandAddition = 0.5
            sandAddition *= 2 if @battle.pbCheckGlobalAbility(:IRONSTORM)
            sandAddition *= 2 if @battle.curseActive?(:CURSE_BOOSTED_SAND)
            spDefMult *= (1 + sandAddition)
        end

        # Calculation
        return [(special_defense * spDefMult).round, 1].max
    end

    def pbSpeed(aiCheck = false, step = nil, afterSwitching: false, move: nil)
        return 1 if fainted? && !dummy?
        speed = statAfterStep(:SPEED, step, aiCheck)
        speedMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            speedMult = BattleHandlers.triggerSpeedCalcAbility(ability, self, speedMult)
        end

        # Item effects that alter calculated Speed
        eachActiveItem do |item|
            next if aiHidesStatItem?(item, aiCheck)
            speedMult = BattleHandlers.triggerSpeedCalcItem(item, self, speedMult)
        end
        
        # Other effects
        unless afterSwitching
            speedMult *= 2.0 if pbOwnSide.effectActive?(:Tailwind) || pbOwnSide.effectActive?(:EmpoweredTailwind)
            speedMult /= 2.0 if pbOwnSide.effectActive?(:Swamp)
            speedMult *= 2.0 if effectActive?(:OnDragonRide)
            speedMult *= 2.0 if effectActive?(:SugarRush)
            eachAlly do |ally|
                speedMult *= 2.0 if ally.hasActiveAbility?(:SUPERCONDUCTOR)
            end
        end
        
        # Numb
        numbRelevant = numbed?
        numbRelevant = false if afterSwitching && hasActiveAbilityAI?(:NATURALCURE)
        if numbRelevant
            speedMult /= 2.0
            speedMult /= 2.0 if pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            speedMult /= 2.0 if shouldAbilityApply?(:CLEANFREAK, aiCheck)
        end

        # Waterlog
        waterlogRelevant = waterlogged?
        waterlogRelevant = false if afterSwitching && hasActiveAbilityAI?(:NATURALCURE)
        if waterlogRelevant
            speedMult /= 2.0
            speedMult /= 2.0 if pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            speedMult /= 2.0 if shouldAbilityApply?(:CLEANFREAK, aiCheck)
        end

        speedMult *= applySpeedTriggers(move,true) if aiCheck

        # Stampede tribe
        speedMult *= 1.15 if hasTribeBonus?(:STAMPEDE)

        speedMult *= 1.5 if pbOwnSide.effectActive?(:SummerFestivals)

        # Calculation
        return [(speed * speedMult).round, 1].max
    end

    def applySpeedTriggers(move = nil,aiCheck = false)
        aiSpeedMult = 1.0

        if shouldItemApply?(:AGILITYHERB,aiCheck)
            if aiCheck
                aiSpeedMult *= 2.0
            else
                applyEffect(:AgilityHerb)
                @battle.pbCommonAnimation("UseItem",self)
                @battle.pbDisplay(_INTL("{1} moves at doubled speed thanks to its {2}!", pbThis, getItemName(:AGILITYHERB)))
            end
        end

        eachAbilityShouldApply(aiCheck) do |ability|
            aiSpeedMult = BattleHandlers.triggerMoveSpeedModifierAbility(ability, self, move, @battle, aiSpeedMult, aiCheck)
        end

        return aiSpeedMult
    end

    def getFinalStat(stat, aiCheck = false, step = nil)
        case stat
        when :ATTACK
            return pbAttack(aiCheck, step)
        when :DEFENSE
            return pbDefense(aiCheck, step)
        when :SPECIAL_ATTACK
            return pbSpAtk(aiCheck, step)
        when :SPECIAL_DEFENSE
            return pbSpDef(aiCheck, step)
        when :SPEED
            return pbSpeed(aiCheck, step)
        end
        return -1
    end
end
