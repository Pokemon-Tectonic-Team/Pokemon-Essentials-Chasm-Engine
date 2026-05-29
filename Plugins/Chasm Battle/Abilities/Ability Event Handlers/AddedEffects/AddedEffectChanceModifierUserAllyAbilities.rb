BattleHandlers::AddedEffectChanceModifierUserAllyAbility.add(:VICTORYSTAR,
    proc { |_ability, _user, _target, _move, chance|
        chance *= 2.0
        next chance
    }
)
