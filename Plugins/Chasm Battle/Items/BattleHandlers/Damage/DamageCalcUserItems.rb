######################################################################
# Space-time trio orbs
######################################################################

BattleHandlers::DamageCalcUserItem.add(:ADAMANTORB,
    proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
        if user.isSpecies?(:DIALGA) && types.intersect?(%i[DRAGON STEEL])
            mults[:base_damage_multiplier] *= 1.2
            user.aiLearnsItem(item) unless aiCheck
        end
    }
)

BattleHandlers::DamageCalcUserItem.add(:LUSTROUSORB,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      if user.isSpecies?(:PALKIA) && types.intersect?(%i[DRAGON WATER])
          mults[:base_damage_multiplier] *= 1.2
          user.aiLearnsItem(item) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserItem.add(:GRISEOUSORB,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      if user.isSpecies?(:GIRATINA) && types.intersect?(%i[DRAGON GHOST])
          mults[:base_damage_multiplier] *= 1.2
          user.aiLearnsItem(item) unless aiCheck
      end
  }
)

######################################################################
# Type boosting items and plates
######################################################################

BattleHandlers::DamageCalcUserItem.add(:BLACKBELT,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :FIGHTING, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:BLACKBELT, :FISTPLATE)

BattleHandlers::DamageCalcUserItem.add(:BLACKGLASSES,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :DARK, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:BLACKGLASSES, :DREADPLATE)

BattleHandlers::DamageCalcUserItem.add(:CHARCOAL,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :FIRE, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:CHARCOAL, :FLAMEPLATE)

BattleHandlers::DamageCalcUserItem.add(:DRAGONFANG,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :DRAGON, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:DRAGONFANG, :DRACOPLATE)

BattleHandlers::DamageCalcUserItem.add(:HARDSTONE,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :ROCK, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:HARDSTONE, :STONEPLATE)

BattleHandlers::DamageCalcUserItem.add(:MAGNET,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :ELECTRIC, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:MAGNET, :ZAPPLATE)

BattleHandlers::DamageCalcUserItem.add(:METALCOAT,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :STEEL, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:METALCOAT, :IRONPLATE)

BattleHandlers::DamageCalcUserItem.add(:MIRACLESEED,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :GRASS, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:MIRACLESEED, :MEADOWPLATE)

BattleHandlers::DamageCalcUserItem.add(:MYSTICWATER,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :WATER, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:MYSTICWATER, :SPLASHPLATE)

BattleHandlers::DamageCalcUserItem.add(:NEVERMELTICE,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :ICE, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:NEVERMELTICE, :ICICLEPLATE)

BattleHandlers::DamageCalcUserItem.add(:FAIRYFEATHER,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :FAIRY, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:FAIRYFEATHER, :PIXIEPLATE)

BattleHandlers::DamageCalcUserItem.add(:POISONBARB,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :POISON, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:POISONBARB, :TOXICPLATE)

BattleHandlers::DamageCalcUserItem.add(:SHARPBEAK,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :FLYING, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:SHARPBEAK, :SKYPLATE)

BattleHandlers::DamageCalcUserItem.add(:SILKSCARF,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :NORMAL, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.add(:SILVERPOWDER,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :BUG, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:SILVERPOWDER, :INSECTPLATE)

BattleHandlers::DamageCalcUserItem.add(:SOFTSAND,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :GROUND, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:SOFTSAND, :EARTHPLATE)

BattleHandlers::DamageCalcUserItem.add(:SPELLTAG,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :GHOST, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:SPELLTAG, :SPOOKYPLATE)

BattleHandlers::DamageCalcUserItem.add(:TWISTEDSPOON,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      typeBoostingItem(item, user, :PSYCHIC, mults, types, aiCheck)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:TWISTEDSPOON, :MINDPLATE)

######################################################################
# GEMS
######################################################################

BattleHandlers::DamageCalcUserItem.add(:BUGGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :BUG, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:FAIRYGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :FAIRY, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:FIGHTINGGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :FIGHTING, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:FIREGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :FIRE, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:FLYINGGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :FLYING, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:GHOSTGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :GHOST, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:GRASSGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :GRASS, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:DARKGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :DARK, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:DRAGONGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :DRAGON, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:ELECTRICGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :ELECTRIC, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:GROUNDGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :GROUND, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:ICEGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :ICE, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:NORMALGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :NORMAL, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:POISONGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :POISON, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:PSYCHICGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :PSYCHIC, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:ROCKGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :ROCK, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:WATERGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :WATER, move, mults, types, aiCheck, aiContext)
  }
)

BattleHandlers::DamageCalcUserItem.add(:STEELGEM,
  proc { |item, user, _target, move, mults, _baseDmg, types, aiCheck, aiContext|
      pbBattleGem(item, user, :STEEL, move, mults, types, aiCheck, aiContext)
  }
)

######################################################################
# Other
######################################################################

BattleHandlers::DamageCalcUserItem.add(:STRENGTHHERB,
  proc { |item, user, _target, move, mults, _baseDmg, _types, aiCheck, aiContext|
      next unless move.category == 1 # Originally special, used instead of specialMove? because of adaptive moves and interloper abilities
      unless aiCheck
          user.applyEffect(:EmpoweringHerbConsumed, item)
          user.aiLearnsItem(item)
      end
      aiContext[:item_consumed] = true if aiContext
      mults[:final_damage_multiplier] *= 1.15
  }
)

BattleHandlers::DamageCalcUserItem.add(:INTELLECTHERB,
  proc { |item, user, _target, move, mults, _baseDmg, _types, aiCheck, aiContext|
      next unless move.category == 0 # Originally physical, used instead of specialMove? because of adaptive moves and interloper abilities
      unless aiCheck
          user.applyEffect(:EmpoweringHerbConsumed, item)
          user.aiLearnsItem(item)
      end
      aiContext[:item_consumed] = true if aiContext
      mults[:final_damage_multiplier] *= 1.15
  }
)

BattleHandlers::DamageCalcUserItem.add(:LUMBERAXE,
  proc { |item, user, _target, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 1.25
      user.aiLearnsItem(item) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserItem.add(:RUSTEDSWORD,
  proc { |item, user, _target, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 1.1
      user.aiLearnsItem(item) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserItem.add(:LIFEORB,
  proc { |item, user, _target, move, mults, _baseDmg, _types, aiCheck|
      unless move.is_a?(PokeBattle_SelfHit)
          mults[:final_damage_multiplier] *= 1.3
          user.aiLearnsItem(item) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserItem.add(:EXPERTBELT,
  proc { |item, user, target, _move, mults, _baseDmg, _types, aiCheck|
      if Effectiveness.super_effective?(target.damageState.typeMod)
          mults[:final_damage_multiplier] *= 1.2
          user.aiLearnsItem(item) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserItem.add(:METRONOME,
  proc { |item, user, _target, _move, mults, _baseDmg, _types, aiCheck|
      if user.countEffect(:Metronome) >= 1
          met = 1 + (0.2 * user.countEffect(:Metronome))
          mults[:final_damage_multiplier] *= met
          user.aiLearnsItem(item) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserItem.add(:PRISMATICPLATE,
  proc { |item, user, _target, _move, mults, _baseDmg, types, aiCheck|
      if types.any? { |type| user.pbHasType?(type) }
          mults[:final_damage_multiplier] *= 1.2
          user.aiLearnsItem(item) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserItem.add(:CRYSTALCALIBURN,
  proc { |item, user, _target, move, mults, _baseDmg, _types, aiCheck|
      if move.sliceMove? || move.lightMove?
          mults[:final_damage_multiplier] *= 1.5
          user.aiLearnsItem(item) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserItem.add(:TECHNIQUEBOOSTER,
  proc { |item, user, _target, move, mults, _baseDmg, _types, aiCheck|
      next if move.is_a?(PokeBattle_SelfHit)
      if move.move_data.is_signature?
          mults[:final_damage_multiplier] *= 1.4
          user.aiLearnsItem(item) unless aiCheck
      end
  }
)
