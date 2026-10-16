# There aren't any!

############################################
# Ability Code for cut or unused abilities
############################################

BattleHandlers::RunFromBattleAbility.add(:RUNAWAY,
    proc { |ability, _battler|
        next true
    }
)