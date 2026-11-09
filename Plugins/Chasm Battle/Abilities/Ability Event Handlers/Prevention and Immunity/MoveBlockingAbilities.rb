BattleHandlers::MoveBlockingAbility.add(:ROYALMAJESTY,
  proc { |_ability, bearer, user, targets, move, battle, aiCheck|
      priority = battle.getMovePriority(move, user, targets, aiCheck)
      next false unless priority && priority > 0
      next false unless bearer.opposes?(user)
      # Check all targets and return true if any are on the ability bearer's side
      ret = false
      targets.each do |b|
          next if b.opposes?(bearer)
          ret = true
          break
      end
      next ret
  }
)

BattleHandlers::MoveBlockingAbility.add(:DESICCATE,
    proc { |_ability, _bearer, _user, _targets, move, battle, _aiCheck|
        next move.calcTypes.intersect?(%i[GRASS WATER]) && battle.sandy?
    }
)

BattleHandlers::MoveBlockingAbility.add(:DECONTAMINATION,
    proc { |_ability, _bearer, _user, _targets, move, battle, _aiCheck|
        next move.calcTypes.intersect?(%i[BUG POISON]) && battle.moonGlowing?
    }
)
