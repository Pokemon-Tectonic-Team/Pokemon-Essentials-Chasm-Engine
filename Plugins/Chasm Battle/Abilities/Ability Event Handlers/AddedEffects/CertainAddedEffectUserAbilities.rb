BattleHandlers::CertainAddedEffectUserAbility.add(:STARSALIGN,
    proc { |ability, battle, user, target, move|
        next battle.eclipsed?
    }
)

BattleHandlers::CertainAddedEffectUserAbility.add(:CATASTROPHIC,
    proc { |ability, battle, user, target, move|
        next true
    }
)

############################################
# Ability Code for cut or unused abilities
############################################

BattleHandlers::CertainAddedEffectUserAbility.add(:TERRORIZE,
    proc { |ability, battle, user, target, move|
        next move.flinchingMove?
    }
)