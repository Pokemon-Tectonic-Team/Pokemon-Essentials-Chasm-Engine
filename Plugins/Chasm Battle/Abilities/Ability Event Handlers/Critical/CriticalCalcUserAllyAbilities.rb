BattleHandlers::CriticalCalcUserAllyAbility.add(:SPECTRUMVISION,
    proc { |_ability, _user, _target, _move, c|
        next c + 1
    }
)

BattleHandlers::CriticalCalcUserAllyAbility.add(:VICTORYSTAR,
    proc { |_ability, _user, _target, _move, c|
        next c + 1
    }
)
