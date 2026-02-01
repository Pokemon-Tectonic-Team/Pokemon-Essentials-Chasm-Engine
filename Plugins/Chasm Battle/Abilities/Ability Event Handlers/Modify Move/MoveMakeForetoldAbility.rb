BattleHandlers::MoveMakeForetoldAbility.add(:STAYOFEXECUTION,
  proc { |ability, user, move, type, battle|
    battle.pbDisplay(_INTL("{1} foresees an imminent demise!", user.pbThis))
    next 1 if move.bladeMove?
  }
)