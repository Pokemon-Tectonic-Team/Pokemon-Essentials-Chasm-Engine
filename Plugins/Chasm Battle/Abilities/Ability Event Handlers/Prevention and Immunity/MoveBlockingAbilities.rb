BattleHandlers::MoveBlockingAbility.add(:ROYALMAJESTY,
  proc { |ability, bearer, user, targets, move, battle, aiCheck|
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
    proc { |ability, _bearer, _user, _targets, move, battle, aiCheck|
        next %i[GRASS WATER].include?(move.calcType) && battle.sandy?
    }
)

BattleHandlers::MoveBlockingAbility.add(:DECONTAMINATION,
    proc { |ability, _bearer, _user, _targets, move, battle, aiCheck|
        next %i[BUG POISON].include?(move.calcType) && battle.moonGlowing?
    }
)