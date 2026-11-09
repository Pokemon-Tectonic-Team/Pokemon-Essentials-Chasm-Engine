BattleHandlers::DamageCalcTargetItem.add(:BABIRIBERRY,
    proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
        pbBattleTypeWeakingBerry(item, :STEEL, types, target, mults, false, aiCheck)
    }
)

BattleHandlers::DamageCalcTargetItem.add(:CHARTIBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :ROCK, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:CHILANBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :NORMAL, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:CHOPLEBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :FIGHTING, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:COBABERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :FLYING, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:COLBURBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :DARK, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:HABANBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :DRAGON, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:KASIBBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :GHOST, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:KEBIABERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :POISON, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:OCCABERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :FIRE, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:PASSHOBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :WATER, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:PAYAPABERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :PSYCHIC, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:RINDOBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :GRASS, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:ROSELIBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :FAIRY, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:SHUCABERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :GROUND, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:TANGABERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :BUG, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:WACANBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :ELECTRIC, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:YACHEBERRY,
  proc { |item, _user, target, _move, mults, _baseDmg, types, aiCheck|
      pbBattleTypeWeakingBerry(item, :ICE, types, target, mults, false, aiCheck)
  }
)

BattleHandlers::DamageCalcTargetItem.add(:EVIOLITE,
  proc { |item, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      # NOTE: Eviolite cares about whether the Pokémon itself can evolve, which
      #       means it also cares about the Pokémon's form. Some forms cannot
      #       evolve even if the species generally can, and such forms are not
      #       affected by Eviolite.
      unless target.notFullyEvolved?
          mults[:defense_multiplier] *= 1.5
          target.aiLearnsItem(item) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetItem.add(:COVERTCLOAK,
  proc { |item, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 0.9
      target.aiLearnsItem(item) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetItem.add(:RUSTEDSHIELD,
  proc { |item, _user, target, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 0.9
      target.aiLearnsItem(item) unless aiCheck
  }
)
