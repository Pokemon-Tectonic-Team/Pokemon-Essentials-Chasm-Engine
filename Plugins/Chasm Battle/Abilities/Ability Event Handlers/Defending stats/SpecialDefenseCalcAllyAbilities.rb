BattleHandlers::SpecialDefenseCalcAllyAbility.add(:FLOWERGIFT,
    proc { |ability, _user, battle, spDefMult|
        spDefMult *= 1.5 if battle.sunny?
        next spDefMult
    }
)

############################################
# Ability Code for cut or unused abilities
############################################

BattleHandlers::SpecialDefenseCalcAllyAbility.add(:NEGATIVEOUTLOOK,
    proc { |ability, user, _battle, spDefMult|
        spDefMult *= 1.5 if user.pbHasType?(:ELECTRIC)
        next spDefMult
    }
)