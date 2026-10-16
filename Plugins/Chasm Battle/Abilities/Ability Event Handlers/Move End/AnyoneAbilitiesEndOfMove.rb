BattleHandlers::AnyoneAbilityEndOfMove.add(:CELEBRATION,
    proc { |ability, battler, user, targets, move, battle|
        next unless move.danceMove?
        battler.applyFractionalHealing(1.0 / 5.0, ability: ability, canOverheal: true)
    }
)

BattleHandlers::AnyoneAbilityEndOfMove.add(:CHOREOGRAPHY,
    proc { |ability, battler, user, targets, move, battle|
        next unless move.danceMove?
        battler.pbRaiseMultipleStatSteps([:SPEED, 1], user, ability: ability)
    }
)

BattleHandlers::AnyoneAbilityEndOfMove.add(:GROOVY,
    proc { |ability, battler, user, targets, move, battle|
        next unless move.danceMove?
        battler.pbRaiseMultipleStatSteps(ATTACKING_STATS_1, user, ability: ability)
    }
)

BattleHandlers::AnyoneAbilityEndOfMove.add(:TREMORSENSE,
    proc { |ability, battler, user, targets, move, battle|
        next unless battler.opposes?(user)
        next if user.airborne?
        next unless move.damagingMove?
        if user.effectActive?(:TremorSensed)
            next if user.effects[:TremorSensed].any? { |entry| entry[1] == battler.index }
            user.effects[:TremorSensed].push([2, battler.index, battler.name])
        else
            user.applyEffect(:TremorSensed, [[2, battler.index, battler.name]])
        end
        battler.showMyAbilitySplash(ability)
        battle.pbDisplay(_INTL("{1} sensed {2}'s movements...", battler.pbThis, user.pbThis(true)))
        battler.hideMyAbilitySplash
    }
)