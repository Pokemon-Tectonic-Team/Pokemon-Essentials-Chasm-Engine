PokeBattle_Battle::BattleStartApplyCurse.add(:CURSE_EXTRA_MOVES,
    proc { |curse_policy, battle, curses_array|
        battle.amuletActivates(
            _INTL("Dreadful Wings Begin To Beat / Once Forgotten, Now Unsealed"),
            _INTL("The foe's Pokemon know extra, unusual moves!")
        )
        curses_array.push(curse_policy)
        next curses_array
    }
)
