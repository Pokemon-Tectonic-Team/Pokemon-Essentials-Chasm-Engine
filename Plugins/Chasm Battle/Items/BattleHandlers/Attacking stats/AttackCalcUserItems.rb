BattleHandlers::AttackCalcUserItem.add(:MUSCLEBAND,
    proc { |_item, _user, _battle, attackMult|
        attackMult *= 1.15
        next attackMult
    }
)

BattleHandlers::AttackCalcUserItem.add(:CHOICEBAND,
  proc { |_item, _user, _battle, attackMult|
      attackMult *= 1.4
      next attackMult
  }
)

BattleHandlers::AttackCalcUserItem.add(:THICKCLUB,
  proc { |_item, user, _battle, attackMult|
      attackMult *= 1.5 if user.isSpecies?(:CUBONE) || user.isSpecies?(:MAROWAK)
      next attackMult
  }
)

BattleHandlers::AttackCalcUserItem.add(:FRAGILELOCKET,
  proc { |_item, _user, _battle, attackMult|
      attackMult *= (1.0 - FRAGILE_LOCKET_STAT_REDUCTION)
      next attackMult
  }
)

BattleHandlers::AttackCalcUserItem.add(:PEARLOFWISDOM,
  proc { |_item, _user, _battle, attackMult|
      attackMult *= (1.0 + PEARL_OF_WISDOM_STAT_BOOST)
      next attackMult
  }
)
