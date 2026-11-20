# pbBattleMoveImmunityStatAbility
BattleHandlers::MoveImmunityTargetAbility.add(:MOTORDRIVE,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :ELECTRIC, :SPEED, 1, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:SAPSIPPER,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :GRASS, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:AERODYNAMIC,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :FLYING, :SPEED, 1, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:FLYTRAP,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :BUG, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:DEBUGGER,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :BUG, :SPEED, 1, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:COLDRECEPTION,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :ICE, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:CHALLENGER,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :FIGHTING, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:HEARTOFJUSTICE,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :DARK, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:INDUSTRIALIZE,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :STEEL, :SPEED, 1, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:ROCKCLIMBER,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :ROCK, :SPEED, 1, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:FILTHY,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :POISON, DEFENDING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:GLASSFIRING,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :FIRE, DEFENDING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:VENOMDETTA,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :POISON, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:FOOLHARDY,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :PSYCHIC, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:FIREFIGHTER,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :FIRE, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:SWORDSMITHING,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :STEEL, ATTACKING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:SHIELDSMITHING,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, :STEEL, DEFENDING_STATS_1, nil, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:COLDFUSION,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, types, %i[FIRE ELECTRIC], ATTACKING_STATS_2, nil, battle, showMessages, aiCheck)
  }
)

# pbBattleMoveImmunityHealAbility

BattleHandlers::MoveImmunityTargetAbility.add(:HEARTLESS,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityHealAbility(ability, user, target, move, types, :FAIRY, battle, showMessages, aiCheck, canOverheal: true)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:POISONABSORB,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityHealAbility(ability, user, target, move, types, :POISON, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:VOLTABSORB,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityHealAbility(ability, user, target, move, types, :ELECTRIC, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:FINESUGAR,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityHealAbility(ability, user, target, move, types, :FIRE, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:WATERABSORB,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityHealAbility(ability, user, target, move, types, :WATER, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:HULLHUNGER,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityHealAbility(ability, user, target, move, types, :STEEL, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.copy(:WATERABSORB, :DRYSKIN)

# Other immunities

BattleHandlers::MoveImmunityTargetAbility.add(:DRAGONSLAYER,
  proc { |ability, user, target, _move, types, battle, showMessages, _aiCheck|
      next false if user.index == target.index
      next false unless types.include?(:DRAGON)
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:PECKINGORDER,
  proc { |ability, user, target, _move, types, battle, showMessages, _aiCheck|
      next false if user.index == target.index
      next false unless types.include?(:FLYING)
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:MINDLESS,
  proc { |ability, user, target, _move, types, battle, showMessages, _aiCheck|
      next false if user.index == target.index
      next false unless types.include?(:PSYCHIC)
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:TELEPATHY,
  proc { |ability, user, target, move, _types, battle, showMessages|
      next false if move.statusMove?
      next false if user.index == target.index || target.opposes?(user)
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("{1} avoids attacks by its ally Pokémon!", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

def typeModToCheck(battle, types, user, target, move, aiCheck)
    if aiCheck
        typeMod = battle.battleAI.pbCalcTypeModAI(types, user, target, move)
    else
        typeMod = target.damageState.typeMod
    end
    return typeMod
end

BattleHandlers::MoveImmunityTargetAbility.add(:WONDERGUARD,
  proc { |ability, user, target, move, types, battle, showMessages, aiCheck|
      next false if move.statusMove?
      next false if types.empty?
      next false if Effectiveness.super_effective?(typeModToCheck(battle, types, user, target, move, aiCheck))
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:WINTERINSULATION,
  proc { |ability, _user, target, _move, types, battle, showMessages|
      next false unless battle.icy?
      next false unless types.intersect?(%i[FIRE ELECTRIC])
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:INDESTRUCTIBLE,
  proc { |ability, _user, target, _move, types, battle, showMessages|
      next false unless target.effectActive?(:Indestructible)
      next false unless types.include?(target.effects[:Indestructible])
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:FULLBLUBBER,
  proc { |ability, user, target, _move, types, battle, showMessages, _aiCheck|
      next false if user.index == target.index
      next false unless types.intersect?(%i[FIRE ICE])
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:RESOLUTE,
  proc { |ability, user, target, _move, types, battle, showMessages, _aiCheck|
      next false if user.index == target.index
      next false unless types.intersect?(%i[DARK BUG])
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:RUGGED,
  proc { |ability, user, target, _move, types, battle, showMessages, _aiCheck|
      next false if user.index == target.index
      next false unless types.intersect?(%i[FIGHTING ROCK])
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:MUPROTOCOL,
  proc { |ability, user, target, _move, types, battle, showMessages, aiCheck|
      next false if user.index == target.index
      next false unless target.shouldItemApply?(:MEMORYSET, aiCheck)
      next false unless types.include?(target.itemTypeChosen)
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)

          target.aiLearnsItem(:MEMORYSET)
      end
      next true
  }
)

############################################
# Ability Code for cut or unused abilities
############################################

BattleHandlers::MoveImmunityTargetAbility.add(:SLICKSURFACE,
  proc { |ability, _user, target, move, _types, battle, showMessages|
      next false unless move.healingMove? && move.damagingMove?
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:SOUNDPROOF,
  proc { |ability, _user, target, move, _types, battle, showMessages|
      next false unless move.soundMove?
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:CYNIC,
  proc { |ability, user, target, _move, types, battle, showMessages, _aiCheck|
      next false if user.index == target.index
      next false unless types.intersect?(%i[FAIRY DRAGON GHOST])
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)
