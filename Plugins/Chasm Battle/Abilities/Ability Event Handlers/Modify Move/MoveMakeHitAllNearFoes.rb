BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:SPACIALDISTORTION,
  proc { |_ability, _user, _move, _type, _battle|
      next true
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:MULTITASKER,
  proc { |_ability, _user, _move, type, _battle|
      next type == :PSYCHIC
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:EVENHANDED,
  proc { |_ability, _user, _move, type, _battle|
      next type == :FIGHTING
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:VICIOUSCYCLE,
  proc { |_ability, _user, _move, type, _battle|
      next type == :DRAGON
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:HORDETACTICS,
  proc { |_ability, _user, _move, type, _battle|
      next type == :NORMAL
  }
)

BattleHandlers::MoveMakeHitAllNearFoesAbility.add(:LETEMHAVEIT,
  proc { |_ability, _user, move, _type, _battle|
      next move.pulseMove?
  }
)
