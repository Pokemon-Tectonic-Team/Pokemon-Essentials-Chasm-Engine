BattleHandlers::TrappingTargetAbility.add(:ARENATRAP,
    proc { |_ability, switcher, _bearer, _battle|
        next true unless switcher.airborne?
    }
)

BattleHandlers::TrappingTargetAbility.add(:SHADOWTAG,
  proc { |_ability, switcher, _bearer, _battle|
      next true unless switcher.hasActiveAbility?(:SHADOWTAG)
  }
)

BattleHandlers::TrappingTargetAbility.add(:CLINGY,
  proc { |_ability, switcher, _bearer, _battle|
      next true if switcher.pbHasAnyStatus?
  }
)

BattleHandlers::TrappingTargetAbility.add(:FROSTPITALITY,
  proc { |_ability, _switcher, _bearer, battle|
      next true if battle.icy?
  }
)

BattleHandlers::TrappingTargetAbility.add(:TRACTORBEAM,
  proc { |_ability, _switcher, _bearer, battle|
      next true if battle.eclipsed?
  }
)

BattleHandlers::TrappingTargetAbility.add(:NOHOPE,
  proc { |_ability, switcher, _bearer, _battle|
      next true if switcher.belowHalfHealth?
  }
)
