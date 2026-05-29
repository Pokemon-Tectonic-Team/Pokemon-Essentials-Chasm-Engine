BattleHandlers::CertainAddedEffectUserAbility.add(:STARSALIGN,
    proc { |_ability, battle, _user, _target, _move|
        next battle.eclipsed?
    }
)

BattleHandlers::CertainAddedEffectUserAbility.add(:TERRORIZE,
    proc { |_ability, _battle, _user, _target, move|
        next move.flinchingMove?
    }
)

BattleHandlers::CertainAddedEffectUserAbility.add(:CATASTROPHIC,
    proc { |_ability, _battle, _user, _target, _move|
        next true
    }
)
