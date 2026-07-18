# There aren't any!

############################################
# Ability Code for cut or unused abilities
############################################

BattleHandlers::AbilityOnFlinch.add(:STEADFAST,
    proc { |ability, battler, _battle|
        battler.tryRaiseStat(:SPEED, battler, ability: ability)
    }
)