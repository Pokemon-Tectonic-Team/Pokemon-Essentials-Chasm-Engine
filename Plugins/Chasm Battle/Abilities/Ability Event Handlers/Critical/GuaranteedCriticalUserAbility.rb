BattleHandlers::GuaranteedCriticalUserAbility.add(:MERCILESS,
    proc { |_ability, _user, target, _battle, _move|
        next true if target.poisoned?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:HARSH,
    proc { |_ability, _user, target, _battle, _move|
        next true if target.burned?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:COLDBLOODED,
    proc { |_ability, _user, target, _battle, _move|
        next true if target.frostbitten?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:SEVERE,
    proc { |_ability, _user, target, _battle, _move|
        next true if target.numbed?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:WALLNINJA,
    proc { |_ability, user, _target, _battle, move|
        next true if user.battle.roomActive? && (move.canRandomCrit? || user.effects[:RaisedCritChance] > 0)
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:BREAKINGWAVE,
    proc { |_ability, user, _target, _battle, _move|
        next true if user.turnCount <= 1
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:LURING,
    proc { |_ability, _user, target, _battle, _move|
        next true if target.dizzy?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:PERFECTLUCK,
    proc { |_ability, _user, _target, _battle, _move|
        next true
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:STERN,
    proc { |_ability, _user, target, _battle, _move|
        next true if target.waterlogged?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:STAYOFEXECUTION,
    proc { |_ability, _user, _target, _battle, move|
        next true if move.sliceMove?
    }
)
