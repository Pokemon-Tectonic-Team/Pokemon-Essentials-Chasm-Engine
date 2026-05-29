BattleHandlers::SpecialDefenseCalcUserAbility.add(:MARVELSKIN,
    proc { |_ability, user, _battle, spDefMult|
        spDefMult *= 2 if user.pbHasAnyStatus?
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:SOLARCELL,
    proc { |_ability, _user, battle, spDefMult|
        spDefMult *= 1.3 if battle.sunny?
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:FLOWERGIFT,
    proc { |_ability, _user, battle, spDefMult|
        spDefMult *= 1.5 if battle.sunny?
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:ICESCALES,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:ASSAULTSPINES,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:PARANOID,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:HEATVEIL,
    proc { |_ability, _user, battle, spDefMult|
        spDefMult *= 2 if battle.sunny?
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:WARPINGEFFECT,
    proc { |_ability, _user, battle, spDefMult|
        spDefMult *= 2 if battle.eclipsed?
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:ICEMIRROR,
    proc { |_ability, _user, battle, spDefMult|
        spDefMult *= 2 if battle.icy?
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:PETRIFYING,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 1.2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:POISONPUNISH,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 1.2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:FIERYSPIRIT,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 1.2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:SUDDENCHILL,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 1.2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:BEGUILING,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 1.2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:PUNISHER,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 1.2
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:BACKWASH,
    proc { |_ability, _user, _battle, spDefMult|
        spDefMult *= 1.2
        next spDefMult
    }
)
