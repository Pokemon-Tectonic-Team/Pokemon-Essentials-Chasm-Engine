BattleHandlers::SpecialAttackCalcUserItem.add(:DEEPSEATOOTH,
    proc { |_item, user, _battle, spAtkMult|
        spAtkMult *= 2 if user.isSpecies?(:CLAMPERL)
        next spAtkMult
    }
)

BattleHandlers::SpecialAttackCalcUserItem.add(:WISEGLASSES,
  proc { |_item, _user, _battle, spAtkMult|
      spAtkMult *= 1.15
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserItem.add(:CHOICESPECS,
  proc { |_item, _user, _battle, spAtkMult|
      spAtkMult *= 1.4
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserItem.add(:FRAGILELOCKET,
  proc { |_item, _user, _battle, spAtkMult|
      spAtkMult *= (1.0 - FRAGILE_LOCKET_STAT_REDUCTION)
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserItem.add(:PEARLOFWISDOM,
proc { |_item, _user, _battle, spAtkMult|
    spAtkMult *= (1.0 + PEARL_OF_WISDOM_STAT_BOOST)
    next spAtkMult
}
)
