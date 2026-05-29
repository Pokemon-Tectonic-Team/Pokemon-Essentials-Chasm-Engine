BattleHandlers::SpeedCalcAbility.add(:CHLOROPHYLL,
  proc { |_ability, battler, mult|
      next mult * 2 if battler.battle.sunny?
  }
)

BattleHandlers::SpeedCalcAbility.add(:QUICKFEET,
  proc { |_ability, battler, mult|
      next mult * 2.0 if battler.pbHasAnyStatus?
  }
)

BattleHandlers::SpeedCalcAbility.add(:HYPERSPEED,
  proc { |_ability, _battler, mult|
      next mult * 2.0
  }
)

BattleHandlers::SpeedCalcAbility.add(:SANDRUSH,
  proc { |_ability, battler, mult|
      next mult * 2 if battler.battle.sandy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SLOWSTART,
  proc { |_ability, battler, mult|
      next mult / 2 if battler.effectActive?(:SlowStart)
  }
)

BattleHandlers::SpeedCalcAbility.add(:SLUSHRUSH,
  proc { |_ability, battler, mult|
      next mult * 2 if battler.battle.icy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SWIFTSWIM,
  proc { |_ability, battler, mult|
      next mult * 2 if battler.battle.rainy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:CLOUDBURST,
  proc { |_ability, battler, mult|
      next mult * 1.3 if battler.battle.rainy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:DEBRISFIELD,
  proc { |_ability, battler, mult|
      next mult * 1.3 if battler.battle.sandy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:UNBURDEN,
  proc { |_ability, battler, mult|
      next mult * 2 if battler.effectActive?(:ItemLost) && !battler.hasAnyItem?
  }
)

BattleHandlers::SpeedCalcAbility.add(:FEROCIOUS,
  proc { |_ability, battler, mult|
      active = false
      battler.eachOpposing do |b|
          next unless b.belowHalfHealth?
          active = true
          break
      end
      mult *= 2 if active
      next mult
  }
)

BattleHandlers::SpeedCalcAbility.add(:PRIMEVALSLOWSTART,
  proc { |_ability, _battler, mult|
      next mult / 2
  }
)

BattleHandlers::SpeedCalcAbility.add(:EXOTHERMENGINE,
  proc { |_ability, _battler, mult|
      next mult * 1.4
  }
)

BattleHandlers::SpeedCalcAbility.add(:LIGHTTRICK,
  proc { |_ability, battler, mult|
      active = false
      battler.eachOpposing do |b|
          next unless b.pbHasAnyStatus?
          active = true
          break
      end
      mult *= 2 if active
      next mult
  }
)

BattleHandlers::SpeedCalcAbility.add(:ANARCHIC,
  proc { |_ability, battler, mult|
      next mult * 2 if battler.battle.eclipsed?
  }
)

BattleHandlers::SpeedCalcAbility.add(:NIGHTLIFE,
  proc { |_ability, battler, mult|
      next mult * 2 if battler.battle.moonGlowing?
  }
)

BattleHandlers::SpeedCalcAbility.add(:NIGHTVISION,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.moonGlowing?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SANDWORNAUGER,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.sandy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:NIGHTOWL,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.moonGlowing?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SANDSNIPER,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.sandy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:TAIGATREKKER,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.icy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:FROSTFANGED,
  proc { |_ability, battler, mult|
      next mult * 1.3 if battler.battle.icy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:LIGHTNINGRIDE,
  proc { |_ability, battler, mult|
      next mult * 2.0 if battler.effectActive?(:EnergyCharge)
  }
)

BattleHandlers::SpeedCalcAbility.add(:METEORIC,
  proc { |_ability, battler, mult|
      next mult * 1.5 if %i[Sandstorm Hail].include?(battler.battle.pbWeather)
  }
)

BattleHandlers::SpeedCalcAbility.add(:SLUGGISH,
  proc { |_ability, _battler, mult|
      next mult / 2.0
  }
)

BattleHandlers::SpeedCalcAbility.add(:LIVEFAST,
  proc { |_ability, _battler, mult|
      next mult * 1.5
  }
)

BattleHandlers::SpeedCalcAbility.add(:WATERFALLCONDITIONING,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.rainy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SILVERLINING,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.rainy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:DYNAMICENTRANCE,
  proc { |_ability, battler, mult|
      next mult * 2.0 if battler.firstTurn?
      next mult
  }
)

BattleHandlers::SpeedCalcAbility.add(:FOREMAN,
  proc { |_ability, battler, mult|
      next mult * 2 if battler.battle.roomActive?
  }
)

BattleHandlers::SpeedCalcAbility.add(:CAFFEINERUSH,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.icy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:HAILSTONEHELM,
  proc { |_ability, battler, mult|
      next mult / 2.0 if battler.battle.icy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SUNCHASER,
  proc { |_ability, battler, mult|
      next mult * 1.5 if battler.battle.sunny?
  }
)
