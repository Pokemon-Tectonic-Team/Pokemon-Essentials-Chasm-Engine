BattleHandlers::AccuracyCalcTargetAbility.add(:LIGHTNINGROD,
  proc { |_ability, mults, _user, _target, _move, type|
      mults[:base_accuracy] = 0 if type == :ELECTRIC
  }
)

BattleHandlers::AccuracyCalcTargetAbility.add(:NOGUARD,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:base_accuracy] = 0
  }
)

BattleHandlers::AccuracyCalcTargetAbility.add(:STORMDRAIN,
  proc { |_ability, mults, _user, _target, _move, type|
      mults[:base_accuracy] = 0 if type == :WATER
  }
)
BattleHandlers::AccuracyCalcTargetAbility.add(:WONDERSKIN,
  proc { |_ability, mults, user, target, move, _type|
      mults[:base_accuracy] = 50 if move.statusMove? && user.opposes?(target) && (mults[:base_accuracy] > 50)
  }
)
