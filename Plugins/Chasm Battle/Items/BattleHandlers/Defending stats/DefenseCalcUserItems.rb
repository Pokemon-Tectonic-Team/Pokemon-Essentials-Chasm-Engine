BattleHandlers::DefenseCalcUserItem.add(:STRIKEVEST,
  proc { |_item, _user, _battle, defenseMult|
      defenseMult *= 1.5
      next defenseMult
  }
)

BattleHandlers::DefenseCalcUserItem.add(:FRAGILELOCKET,
  proc { |_item, _user, _battle, defenseMult|
      defenseMult *= (1.0 - FRAGILE_LOCKET_STAT_REDUCTION)
      next defenseMult
  }
)

BattleHandlers::DefenseCalcUserItem.add(:PEARLOFWISDOM,
  proc { |_item, _user, _battle, defenseMult|
      defenseMult *= (1.0 + PEARL_OF_WISDOM_STAT_BOOST)
      next defenseMult
  }
)
