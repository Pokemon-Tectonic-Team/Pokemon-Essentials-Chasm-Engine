BattleHandlers::AccuracyCalcUserAbility.add(:COMPOUNDEYES,
    proc { |_ability, mults, _user, _target, _move, _type|
        mults[:accuracy_multiplier] *= 1.3
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:HUSTLE,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 0.8
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:KEENEYE,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:evasion_step] = 0 if mults[:evasion_step] > 0
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:NOGUARD,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:base_accuracy] = 0
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:VICTORYSTAR,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 2.0
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:OCULAR,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 1.5
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:SANDSNIPER,
    proc { |_ability, mults, user, _target, _move, _type|
        mults[:base_accuracy] = 0 if user.battle.sandy?
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:NIGHTOWL,
  proc { |_ability, mults, user, _target, _move, _type|
      mults[:base_accuracy] = 0 if user.battle.moonGlowing?
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:STARSALIGN,
  proc { |_ability, mults, user, _target, _move, _type|
      mults[:base_accuracy] = 0 if user.battle.eclipsed?
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:FREESTYLE,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 0.8
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:WATERFALLCONDITIONING,
    proc { |_ability, mults, user, _target, _move, _type|
        mults[:base_accuracy] = 0 if user.battle.rainy?
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:PINDOWN,
    proc { |_ability, mults, _user, target, _move, _type|
        mults[:base_accuracy] = 0 if target.trapped?
    }
)
