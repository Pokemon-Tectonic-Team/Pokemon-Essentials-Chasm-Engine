BattleHandlers::ForbidsUserSwitchInAbility.add(:PACIFIST,
    proc { |ability, battle, partyMember, side, idxTrainer, idxParty|
        battle.pbMessage(_INTL("{1} refuses to join the battle. It's a pacifist!", partyMember.name))
        next true
    }
)

BattleHandlers::ForbidsUserSwitchInAbility.add(:EXOSPHERICDESCENT,
    proc { |ability, battle, partyMember, side, idxTrainer, idxParty|
        next false unless battle.isLastAboveHalfHealthInTeam?(idxParty, side, idxTrainer)
        pbMessage(_INTL("{1} refuses to join the battle, as it deems its presence not necessary!", partyMember.name))
        next true
    }
)

BattleHandlers::ForbidsUserSwitchInAbility.add(:SLUMBERINGSHIELD,
    proc { |ability, battle, partyMember, side, idxTrainer, idxParty|
        next false unless battle.field.effectActive?(:SlumberingShieldReady)
        pbMessage(_INTL("{1} is in a deep slumber, and cannot join the battle!", partyMember.name))
        next true
    }
)

BattleHandlers::ForbidsUserSwitchInAbility.add(:SLUMBERINGSWORD,
    proc { |ability, battle, partyMember, side, idxTrainer, idxParty|
        next false unless battle.field.effectActive?(:SlumberingSwordReady)
        pbMessage(_INTL("{1} is in a deep slumber, and cannot join the battle!", partyMember.name))
        next true
    }
)

BattleHandlers::ForbidsUserSwitchInAbility.add(:PRIMORDIALSEAL,
    proc { |ability, battle, partyMember, side, idxTrainer, idxParty|
        next false unless battle.haveSpeciesEnteredBattle(:REGIDRAGO, REGICE, REGIROCK, REGISTEEL, REGIELEKI)
        pbMessage(_INTL("{1} refuses to join the battle! It waits for its kin!", partyMember.name))
        next true
    }
)