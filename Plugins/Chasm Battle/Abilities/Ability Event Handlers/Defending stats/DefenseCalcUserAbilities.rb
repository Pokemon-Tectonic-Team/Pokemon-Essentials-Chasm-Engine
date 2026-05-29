BattleHandlers::DefenseCalcUserAbility.add(:FLUFFY,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:FURCOAT,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:MARVELSCALE,
    proc { |_ability, user, _battle, defenseMult|
        defenseMult *= 1.5 if user.pbHasAnyStatus?
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:DESERTARMOR,
    proc { |_ability, _user, battle, defenseMult|
        defenseMult *= 2 if battle.sandy?
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:SOLONOCTURNE,
    proc { |_ability, _user, battle, defenseMult|
        defenseMult *= 2 if battle.moonGlowing?
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:SAFEPASSAGE,
    proc { |_ability, _user, battle, defenseMult|
        defenseMult *= 2 if battle.rainy?
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:STATIC,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:POISONPOINT,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:FLAMEBODY,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:CHILLEDBODY,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:DISORIENT,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:KELPLINK,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:SOPPING,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:STRIKECORONA,
    proc { |_ability, _user, _battle, defenseMult|
        defenseMult *= 2
        next defenseMult
    }
)
