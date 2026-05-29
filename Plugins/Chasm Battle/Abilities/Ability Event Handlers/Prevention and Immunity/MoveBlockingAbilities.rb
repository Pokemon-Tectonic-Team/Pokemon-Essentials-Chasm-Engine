BattleHandlers::MoveBlockingAbility.add(:ROYALMAJESTY,
  proc { |_ability, bearer, user, targets, move, battle, aiCheck|
      priority = battle.getMovePriority(move, user, targets, aiCheck)
      next false unless priority && priority > 0
      next false unless bearer.opposes?(user)
      next true
  }
)

BattleHandlers::MoveBlockingAbility.add(:DESICCATE,
    proc { |_ability, _bearer, _user, _targets, move, battle, _aiCheck|
        next %i[GRASS WATER].include?(move.calcType) && battle.sandy?
    }
)

BattleHandlers::MoveBlockingAbility.add(:DECONTAMINATION,
    proc { |_ability, _bearer, _user, _targets, move, battle, _aiCheck|
        next %i[BUG POISON].include?(move.calcType) && battle.moonGlowing?
    }
)
