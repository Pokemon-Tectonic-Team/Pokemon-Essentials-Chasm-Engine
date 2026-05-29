BattleHandlers::CriticalCalcUserAbility.add(:SUPERLUCK,
  proc { |_ability, _user, _target, _move, c|
      next c + 2
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SNIPER,
  proc { |_ability, _user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SHARPSHOOTER,
  proc { |_ability, _user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:RUNTHROUGH,
  proc { |_ability, user, _target, _move, c|
      next 0 if user.steps[:SPEED] <= 0
      next c + user.steps[:SPEED]
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:RAZORSEDGE,
  proc { |_ability, _user, _target, move, c|
      next c + 1 if move.sliceMove?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:NIGHTVISION,
  proc { |_ability, user, _target, _move, c|
      next c + 1 if user.battle.moonGlowing?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SANDWORNAUGER,
  proc { |_ability, user, _target, _move, c|
      next c + 1 if user.battle.sandy?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SPECTRUMVISION,
  proc { |_ability, _user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SILVERSENSE,
  proc { |_ability, _user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:VICTORYSTAR,
  proc { |_ability, _user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:CAFFEINERUSH,
  proc { |_ability, user, _target, _move, c|
      next c + 1 if user.battle.icy?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:RELUCTANTWARRIOR,
  proc { |_ability, user, _target, _move, c|
      next c + 1 if user.belowHalfHealth?
      next c
  }
)
