BattleHandlers::GuaranteedCriticalUserAbility.add(:MERCILESS,
    proc { |ability, _user, target, _battle, move|
        next true if target.poisoned?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:HARSH,
    proc { |ability, _user, target, _battle, move|
        next true if target.burned?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:COLDBLOODED,
    proc { |ability, _user, target, _battle, move|
        next true if target.frostbitten?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:SEVERE,
    proc { |ability, _user, target, _battle, move|
        next true if target.numbed?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:WALLNINJA,
    proc { |ability, user, _target, _battle, move|
        next true if user.battle.roomActive? && (move.canRandomCrit? || user.effects[:RaisedCritChance] > 0)
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:BREAKINGWAVE,
    proc { |ability, user, _target, _battle, move|
        next true if user.turnCount <= 1
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:PERFECTLUCK,
    proc { |ability, _user, target, _battle, move|
        next true
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:STERN,
    proc { |ability, _user, target, _battle, move|
        next true if target.waterlogged?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:STAYOFEXECUTION,
    proc { |ability, _user, target, _battle, move|
        next true if move.sliceMove?
    }
)

############################################
# Ability Code for cut or unused abilities
############################################

BattleHandlers::GuaranteedCriticalUserAbility.add(:LURING,
    proc { |ability, _user, target, _battle, move|
        next true if target.dizzy?
    }
)