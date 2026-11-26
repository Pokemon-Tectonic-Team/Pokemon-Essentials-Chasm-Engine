BattleHandlers::AccuracyCalcTargetAbility.add(:NOGUARD,
  proc { |_ability, mults, _user, _target, _move, _types|
      mults[:base_accuracy] = 0
  }
)

############################################
# Ability Code for cut or unused abilities
############################################

BattleHandlers::AccuracyCalcTargetAbility.add(:LIGHTNINGROD,
  proc { |_ability, mults, _user, _target, _move, types|
      mults[:base_accuracy] = 0 if types.include?(:ELECTRIC)
  }
)

BattleHandlers::AccuracyCalcTargetAbility.add(:STORMDRAIN,
  proc { |_ability, mults, _user, _target, _move, types|
      mults[:base_accuracy] = 0 if types.include?(:WATER)
  }
)
BattleHandlers::AccuracyCalcTargetAbility.add(:WONDERSKIN,
  proc { |_ability, mults, user, target, move, _types|
      mults[:base_accuracy] = 50 if move.statusMove? && user.opposes?(target) && (mults[:base_accuracy] > 50)
  }
)
