BattleHandlers::SpecialAttackCalcUserAbility.add(:FLAREBOOST,
    proc { |_ability, user, _battle, spAtkMult|
        spAtkMult *= 1.5 if user.burned?
        next spAtkMult
    }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:SOLARPOWER,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.5 if battle.sunny?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:HEADACHE,
  proc { |_ability, _user, _battle, spAtkMult|
      spAtkMult *= 2.0
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:PUREENERGY,
  proc { |_ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.5
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:CLOUDBURST,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.rainy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:DEBRISFIELD,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.sandy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:SOLARCELL,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.sunny?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:ARCANE,
  proc { |_ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.3
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:OVERTHINKING,
  proc { |_ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.3
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:MIDDLEWAY,
  proc { |_ability, user, _battle, spAtkMult|
      spAtkMult *= 1.5 if user.lastRoundMoveCategory == 0
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:FELLOMEN,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.eclipsed?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:ILLUMINANCE,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.moonGlowing?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:SANDPOWER,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.sandy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:OVERWHELM,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.rainy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:SUMMITSPIRIT,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.icy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:COLDCALCULATION,
  proc { |_ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.75
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:EXTREMEVOLTAGE,
  proc { |_ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.5
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:CASTELLAN,
  proc { |_ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.roomActive?
      next spAtkMult
  }
)
