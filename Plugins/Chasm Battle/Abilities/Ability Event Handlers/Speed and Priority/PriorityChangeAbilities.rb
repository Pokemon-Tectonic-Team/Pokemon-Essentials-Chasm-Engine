BattleHandlers::PriorityChangeAbility.add(:PRANKSTER,
  proc { |ability, battler, move, _pri, _targets = nil, aiCheck = false|
      if move.statusMove?
          battler.applyEffect(:Prankster) unless aiCheck
          next 1
      end
  }
)

BattleHandlers::PriorityChangeAbility.add(:TRIAGE,
  proc { |ability, _battler, move, _pri, _targets = nil, _aiCheck = false|
      next 3 if move.healingMove?
  }
)

BattleHandlers::PriorityChangeAbility.add(:FAUXLIAGE,
  proc { |ability, battler, move, _pri, _targets = nil, _aiCheck = false|
      next 1 if move.calcType == :GRASS
  }
)

BattleHandlers::PriorityChangeAbility.add(:ENVY,
  proc { |ability, _battler, _move, _pri, targets = nil, _aiCheck = false|
      next 1 if targets && targets.length == 1 && targets[0].hasRaisedStatSteps?
  }
)

BattleHandlers::PriorityChangeAbility.add(:QUICKBUILD,
  proc { |ability, _battler, move, _pri, _targets = nil, _aiCheck = false|
      next 1 if move.setsARoom?
  }
)

BattleHandlers::PriorityChangeAbility.add(:TIMEINTERLOPER,
  proc { |ability, _battler, _move, _pri, _targets = nil, _aiCheck = false|
      next 1
  }
)

BattleHandlers::PriorityChangeAbility.add(:POWERLIFTER,
  proc { |ability, _battler, move, _pri, _targets = nil, _aiCheck = false|
      next -6 if move.physicalMove?
  }
)

BattleHandlers::PriorityChangeAbility.add(:EGOIST,
  proc { |ability, battler, move, _pri, _targets = nil, _aiCheck = false|
      next 1 if move.type == :FIGHTING
  }
)

BattleHandlers::PriorityChangeAbility.add(:LEADDANCER,
  proc { |ability, _battler, move, _pri, _targets = nil, _aiCheck = false|
      next 1 if move.danceMove?
  }
)

BattleHandlers::PriorityChangeAbility.add(:TREMORSENSE,
  proc { |ability, battler, _move, _pri, targets = nil, aiCheck = false|
      next unless targets&.length == 1
      target = targets[0]
      next unless target.effectActive?(:TremorSensed)
      next unless target.effects[:TremorSensed].any? { |entry| entry[1] == battler.index }
      unless aiCheck
          target.effects[:TremorSensed].reject! { |entry| entry[1] == battler.index }
          target.disableEffect(:TremorSensed) if target.effects[:TremorSensed].empty?
          battler.showMyAbilitySplash(ability)
          battler.battle.pbDisplay(_INTL("{1} predicted {2}'s actions, and struck first!", battler.pbThis, target.pbThis(true)))
          battler.hideMyAbilitySplash
      end
      next 1
  }
)