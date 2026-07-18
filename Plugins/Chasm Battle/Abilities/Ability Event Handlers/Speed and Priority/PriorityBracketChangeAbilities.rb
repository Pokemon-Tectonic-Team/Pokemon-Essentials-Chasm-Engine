BattleHandlers::PriorityBracketChangeAbility.add(:APATHETIC,
  proc { |ability, _battler, subPri, _battle|
      next -1 if subPri == 0
  }
)

############################################
# Ability Code for cut or unused abilities
############################################

BattleHandlers::PriorityBracketChangeAbility.add(:QUICKDRAW,
    proc { |ability, _battler, subPri, battle|
        next 1 if subPri < 1 && battle.pbRandom(10) < 3
    }
)