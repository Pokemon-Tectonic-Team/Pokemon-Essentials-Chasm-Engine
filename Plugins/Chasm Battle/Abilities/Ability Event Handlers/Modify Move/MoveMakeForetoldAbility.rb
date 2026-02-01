BattleHandlers::MoveMakeForetoldAbility.add(:STAYOFEXECUTION,
  proc { |ability, user, move, battle|
    next 1 if move.bladeMove?
  }
)