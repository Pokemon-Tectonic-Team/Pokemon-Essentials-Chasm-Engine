BattleHandlers::AttackCalcUserAbility.add(:FLOWERGIFT,
    proc { |_ability, user, _battle, attackMult|
        attackMult *= 1.5 if user.battle.sunny?
        next attackMult
    }
)

BattleHandlers::AttackCalcUserAbility.add(:SLOWSTART,
    proc { |_ability, user, _battle, attackMult|
        attackMult /= 2 if user.effectActive?(:SlowStart)
        next attackMult
    }
)

BattleHandlers::AttackCalcUserAbility.add(:PRIMEVALSLOWSTART,
  proc { |_ability, _user, _battle, attackMult|
      attackMult /= 2
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:GORILLATACTICS,
    proc { |_ability, _user, _battle, attackMult|
        attackMult *= 1.4
        next attackMult
    }
)

BattleHandlers::AttackCalcUserAbility.add(:TOUGHCLAWS,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 1.3
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:TOXICBOOST,
  proc { |_ability, user, _battle, attackMult|
      attackMult *= 1.5 if user.poisoned?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:HUGEPOWER,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.copy(:HUGEPOWER, :PUREPOWER)

BattleHandlers::AttackCalcUserAbility.add(:FLUSTERFLOCK,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 2.0
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:PUREFORCE,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:ARCHVILLAIN,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:DEEPSTING,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:BIGTHORNS,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.sunny?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:WARMUP,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.sunny?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:SLEETSHAKER,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.icy?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:LUNATIC,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.moonGlowing?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:NIGHTSTALKER,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 1.5 if battle.moonGlowing?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:FULLMOONBLADE,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 2.0 if battle.fullMoon?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:EARTHSHAKER,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.sandy?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:SLIPSTREAM,
  proc { |_ability, user, _battle, attackMult|
      attackMult *= 1.5 if user.pbOwnSide.effectActive?(:Tailwind)
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:ROBUST,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 1.2
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:MIDDLEWAY,
  proc { |_ability, user, _battle, attackMult|
      attackMult *= 1.5 if user.lastRoundMoveCategory == 1
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:SERVEDCOLD,
  proc { |_ability, user, battle, attackMult|
      if battle.icy?
          if user.belowHalfHealth?
              attackMult *= 1.4
          else
              attackMult *= 1.2
          end
      end
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:FROSTFANGED,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.icy?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:FEELTHEBURN,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 1.75
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:EXTREMEPOWER,
  proc { |_ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:CASTELLAN,
  proc { |_ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.roomActive?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:TOOTHANDCLAW,
  proc { |_ability, user, battle, attackMult|
      previousMoveID = user.moveUsageHistory[1] || nil
      currentMoveID = user.moveUsageHistory[0] || nil

      next if currentMoveID.nil?
      next if previousMoveID.nil?

      previousMoveData = battle.getBattleMoveInstanceFromID(previousMoveID)
      currentMoveData = battle.getBattleMoveInstanceFromID(currentMoveID)

      next if currentMoveData.bitingMove?
      attackMult *= 1.5 if previousMoveData.bitingMove?
      next attackMult
  }
)
