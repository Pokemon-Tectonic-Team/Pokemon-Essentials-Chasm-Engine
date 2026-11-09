BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:SPACIALDISTORTION,
  proc { |ability, user, move, types, battle|
      next true
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:MULTITASKER,
  proc { |ability, user, move, types, battle|
      next types.include?(:PSYCHIC)
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:EVENHANDED,
  proc { |ability, user, move, types, battle|
      next types.include?(:FIGHTING)
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:VICIOUSCYCLE,
  proc { |ability, user, move, types, battle|
      next types.include?(:DRAGON)
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:HORDETACTICS,
  proc { |ability, user, move, types, battle|
      next types.include?(:NORMAL)
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:LETEMHAVEIT,
  proc { |ability, user, move, types, battle|
      next move.pulseMove?
  }
)