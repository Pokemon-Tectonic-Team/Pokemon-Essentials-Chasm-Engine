BattleHandlers::DamageCalcTargetAbility.add(:FILTER,
  proc { |ability, user, target, move, mults, _baseDmg, types, aiCheck|
      if Effectiveness.super_effective?(typeModToCheck(user.battle, types, user, target, move, aiCheck))
          mults[:final_damage_multiplier] *= 3 / 4.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.copy(:FILTER, :PRISMARMOR)

BattleHandlers::DamageCalcTargetAbility.add(:UNFAZED,
  proc { |ability, user, target, move, mults, _baseDmg, types, aiCheck|
      if Effectiveness.normal?(typeModToCheck(user.battle, types, user, target, move, aiCheck))
          mults[:final_damage_multiplier] *= 4 / 5.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:WELLSUITED,
  proc { |ability, user, target, move, mults, _baseDmg, types, aiCheck|
      if Effectiveness.not_very_effective?(typeModToCheck(user.battle, types, user, target, move, aiCheck))
          mults[:final_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SIMPLETON,
  proc { |ability, _user, target, move, mults, _baseDmg, _types, aiCheck|
      if move.tagged?
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:DRYSKIN,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.include?(:FIRE)
          mults[:base_damage_multiplier] *= 5 / 4.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FINESUGAR,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.include?(:WATER)
          mults[:base_damage_multiplier] *= 5 / 4.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FLUFFY,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.include?(:FIRE)
          mults[:final_damage_multiplier] *= 2
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PARANOID,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.include?(:PSYCHIC)
          mults[:final_damage_multiplier] *= 2
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:MULTISCALE,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.fullHealth?
          mults[:final_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.copy(:MULTISCALE, :DOMINEERING, :SHADOWSHIELD)

BattleHandlers::DamageCalcTargetAbility.add(:THICKFAT,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.intersect?(%i[FIRE ICE])
          mults[:base_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.copy(:THICKFAT, :THERMOSTASIS)

BattleHandlers::DamageCalcTargetAbility.add(:UNAFRAID,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.intersect?(%i[BUG DARK])
          mults[:base_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:EXORCIST,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.intersect?(%i[GHOST PSYCHIC])
          mults[:base_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FEATHERCOAT,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.intersect?(%i[ICE FLYING])
          mults[:base_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:REALIST,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.intersect?(%i[DRAGON FAIRY GHOST])
          mults[:base_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:TOUGH,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.intersect?(%i[FIGHTING ROCK])
          mults[:base_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:WATERBUBBLE,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.include?(:FIRE)
          mults[:final_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:STEAMPOWER,
  proc { |ability, _user, target, _move, mults, _baseDmg, types, aiCheck|
      if types.include?(:WATER)
          mults[:final_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:WEATHERED,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.pbWeather != :None
          mults[:final_damage_multiplier] *= 4 / 5.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SENTRY,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.effectActive?(:ChoseStatus)
          mults[:final_damage_multiplier] *= 3 / 4.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:TRAPPER,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.trapped?
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:BOTTOMFEEDER,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.trapped?
          mults[:final_damage_multiplier] *= 3 / 4.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PINDOWN,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.trapped?
          mults[:final_damage_multiplier] *= 4 / 5.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FORTIFIED,
  proc { |ability, user, target, move, mults, _baseDmg, _types, aiCheck|
      if aiCheck
          mults[:final_damage_multiplier] *= 7 / 10.0 unless user.pbSpeed(true) > target.pbSpeed(true, move: move)
      elsif !target.movedThisRound?
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability)
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SANDSHROUD,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.sandy?
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:DESERTSPIRIT,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.sandy?
          mults[:final_damage_multiplier] *= 4 / 5.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SNOWSHROUD,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.icy?
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FERROFLUID,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.rainy?
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:MISTBLANKET,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.moonGlowing?
          mults[:final_damage_multiplier] *= 3 / 4.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:APPREHENSIVE,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.partialEclipse?
          mults[:final_damage_multiplier] *= 13 / 20.0 # 0.65
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:BULLY,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      # Important reminder: User is the one using the move, target is the one being hit
      # This means for an ability that affects being hit, *target* is the Pokemon with the ability
      if user.pbHeight < target.pbHeight
          mults[:base_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:LIMINAL,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.effectActive?(:SwitchedIn)
          mults[:final_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:MISTFORM,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.effectActive?(:SwitchedIn)
          mults[:final_damage_multiplier] *= 2 / 3.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PLASMAGLOBE,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 3 / 2.0
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:INTROVERT,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      unless target.usedDamagingMove
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:QUARRELSOME,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.firstTurn?
          mults[:final_damage_multiplier] *= 2
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:RUSTWRACK,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 23 / 20.0 # 1.15
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:APRICORNARMOR,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.pbHasAnyStatus?
          mults[:final_damage_multiplier] *= 3 / 5.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:RUGGEDSCALES,
  proc { |ability, _user, target, move, mults, _baseDmg, _types, aiCheck|
      if move.randomEffect?
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:DARTER,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.pbOwnSide.effectActive?(:Tailwind)
          mults[:final_damage_multiplier] *= 7 / 10.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:WHITEKNIGHT,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 17 / 20.0 # 0.85
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:BURDENED,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 2 / 3.0
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PALACEGUARD,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.battle.roomActive?
          mults[:final_damage_multiplier] *= 2 / 3.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:MULTIHEADED,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.belowHalfHealth?
          mults[:final_damage_multiplier] *= 2 / 3.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PROTECTIVEINSTINCT,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.hasAnyNotFullyEvolvedAllies?
          mults[:final_damage_multiplier] *= 2 / 3.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:UMBRALTENACITY,
  proc { |ability, user, target, _move, mults, _baseDmg, types, aiCheck|
      if user.battle.moonGlowing? && !types.include?(:STEEL)
          mults[:final_damage_multiplier] *= 13 / 20.0 # 0.65
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:HAILSTONEHELM,
  proc { |ability, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.icy?
          mults[:final_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:BARRENBLOOD,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.battle.sandy? 
      mults[:final_damage_multiplier] *= 3 / 2.0
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

############################################
# Ability Code for cut or unused abilities
############################################

# This ability isn't cut, was just never implemented on anything
BattleHandlers::DamageCalcTargetAbility.add(:ROLLINGBLOWS,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.effectActive?(:TwoTurnAttack) || target.effectActive?(:HyperBeam)
          mults[:final_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SHIELDWALL,
  proc { |ability, user, target, move, mults, _baseDmg, types, aiCheck|
      if Effectiveness.hyper_effective?(typeModToCheck(user.battle, types, user, target, move, aiCheck))
          mults[:final_damage_multiplier] *= 1 / 2.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:VIGILANT,
  proc { |ability, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      if target.effectActive?(:ChoseStatus)
          mults[:final_damage_multiplier] *= 3 / 5.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)
