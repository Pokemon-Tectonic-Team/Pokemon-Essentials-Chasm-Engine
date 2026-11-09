BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:SPACIALDISTORTION,
  proc { |_ability, _user, _move, _types, _battle|
      next true
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:MULTITASKER,
  proc { |_ability, _user, _move, types, _battle|
      next types.include?(:PSYCHIC)
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:EVENHANDED,
  proc { |_ability, _user, _move, types, _battle|
      next types.include?(:FIGHTING)
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:VICIOUSCYCLE,
  proc { |_ability, _user, _move, types, _battle|
      next types.include?(:DRAGON)
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:HORDETACTICS,
  proc { |_ability, _user, _move, types, _battle|
      next types.include?(:NORMAL)
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:LETEMHAVEIT,
  proc { |_ability, _user, move, _types, _battle|
      next move.pulseMove?
  }
)
