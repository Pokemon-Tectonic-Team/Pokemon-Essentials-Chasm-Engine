BattleHandlers::AddedEffectChanceModifierUserAbility.add(:FUMIGATE,
    proc { |_ability, _user, _target, move, chance|
        chance += 50 if move.windMove?
        next chance
    }
)

BattleHandlers::AddedEffectChanceModifierUserAbility.add(:GNAWING,
    proc { |_ability, _user, _target, move, chance|
        chance += 50 if move.bitingMove?
        next chance
    }
)

BattleHandlers::AddedEffectChanceModifierUserAbility.add(:RATTLEEM,
    proc { |_ability, _user, _target, move, chance|
        chance *= 1.5 if move.flinchingMove?
        next chance
    }
)

BattleHandlers::AddedEffectChanceModifierUserAbility.add(:SERENEGRACE,
    proc { |_ability, _user, _target, _move, chance|
        chance *= 2.0
        next chance
    }
)

BattleHandlers::AddedEffectChanceModifierUserAbility.add(:SILVERLINING,
    proc { |_ability, user, _target, _move, chance|
        chance *= 2.0 if user.battle.rainy?
        next chance
    }
)

BattleHandlers::AddedEffectChanceModifierUserAbility.add(:VICTORYSTAR,
    proc { |_ability, _user, _target, _move, chance|
        chance *= 2.0
        next chance
    }
)
