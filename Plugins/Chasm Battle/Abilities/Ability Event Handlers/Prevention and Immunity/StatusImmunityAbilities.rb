BattleHandlers::StatusImmunityAbility.add(:FLOWERVEIL,
  proc { |_ability, battler, _status|
      next true if battler.pbHasType?(:GRASS)
  }
)

BattleHandlers::StatusImmunityAbility.add(:VITALSPIRIT,
  proc { |_ability, _battler, status|
      next true if status == :SLEEP
  }
)

BattleHandlers::StatusImmunityAbility.copy(:VITALSPIRIT, :SWEETVEIL, :INSOMNIA)

BattleHandlers::StatusImmunityAbility.add(:LEAFGUARD,
  proc { |_ability, battler, _status|
      next true if battler.battle.sunny?
  }
)

BattleHandlers::StatusImmunityAbility.add(:STABILITY,
  proc { |_ability, _battler, _status|
      next true
  }
)

BattleHandlers::StatusImmunityAbility.add(:LEVIATHAN,
  proc { |_ability, _battler, status|
      next true if %i[BURN FROSTBITE].include?(status)
  }
)

BattleHandlers::StatusImmunityAbility.add(:FAEVEIL,
  proc { |_ability, _battler, status|
      next true if %i[BURN FROSTBITE NUMB].include?(status)
  }
)

BattleHandlers::StatusImmunityAllyAbility.add(:FAEVEIL,
  proc { |_ability, _battler, status|
      next true if %i[BURN FROSTBITE NUMB].include?(status)
  }
)

BattleHandlers::StatusImmunityAbility.add(:CANDYVEIL,
  proc { |_ability, _battler, status|
      next true if %i[POISON LEECHED WATERLOG].include?(status)
  }
)

BattleHandlers::StatusImmunityAllyAbility.add(:CANDYVEIL,
  proc { |_ability, _battler, status|
      next true if %i[POISON LEECHED WATERLOG].include?(status)
  }
)

BattleHandlers::StatusImmunityAbility.add(:SLICKSURFACE,
  proc { |_ability, _battler, status|
      next true if status == :LEECHED
  }
)

BattleHandlers::StatusImmunityAbility.add(:FIGHTINGVIGOR,
  proc { |_ability, _battler, status|
      next true if %i[NUMB WATERLOG].include?(status)
  }
)

BattleHandlers::StatusImmunityAbility.add(:GROTESQUEVITALS,
  proc { |_ability, _battler, status|
      next true if status == :POISON
  }
)

BattleHandlers::StatusImmunityAbility.add(:SELFSUFFICIENT,
  proc { |_ability, _battler, status|
      next true if %i[BURN FROSTBITE].include?(status)
  }
)

BattleHandlers::StatusImmunityAbility.add(:DOMINEERING,
  proc { |_ability, _battler, status|
      next true if status == :DIZZY
  }
)

BattleHandlers::StatusImmunityAbility.add(:ENERGETIC,
  proc { |_ability, _battler, status|
      next true if %i[NUMB WATERLOG].include?(status)
  }
)

BattleHandlers::StatusImmunityAbility.add(:RUNNINGFREE,
  proc { |_ability, _battler, status|
      next true if %i[NUMB WATERLOG].include?(status)
  }
)

BattleHandlers::StatusImmunityAbility.add(:MENTALBLOCK,
  proc { |_ability, _battler, status|
      next true if status == :DIZZY
  }
)

BattleHandlers::StatusImmunityAbility.add(:PLOTARMOR,
  proc { |_ability, battler, _status|
      next true if battler.battle.eclipsed?
  }
)

BattleHandlers::StatusImmunityAbility.add(:STONESYMBOL,
  proc { |_ability, battler, _status|
      next true if battler.battle.sandy?
  }
)
