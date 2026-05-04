BattleHandlers::AbilityOnHPDropped.add(:PRIMEVALBOULDERNEST,
    proc { |ability, battler, battle, old_fraction, new_fraction|
        next if old_fraction <= 3.0/4.0
        next unless new_fraction <= 3.0/4.0
        battle.pbShowAbilitySplash(battler, ability)
        if battler.pbOpposingSide.effectActive?(:StealthRock)
            battle.pbDisplay(_INTL("But there were already pointed stones floating around {1}!",
                  battler.pbOpposingTeam(true)))
        else
            battle.pbAnimation(:STEALTHROCK, battler, nil)
            battler.pbOpposingSide.applyEffect(:StealthRock)
        end
        battle.pbHideAbilitySplash(battler)
    }
)
