BattleHandlers::TypeCalcAbility.add(:HAUNTED,
    proc { |ability, battler, types|
        types.push(:GHOST)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:INFECTED,
    proc { |ability, battler, types|
        types.push(:GRASS)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:RUSTWRACK,
    proc { |ability, battler, types|
        types.push(:STEEL)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:SLUGGISH,
    proc { |ability, battler, types|
        types.push(:BUG)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:UNIDENTIFIED,
    proc { |ability, battler, types|
        types.push(:MUTANT) unless types.include?(:MUTANT)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:FIERYGLOW,
    proc { |ability, battler, types|
        types.push(:FIRE)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:OTHERWORLDLY,
    proc { |ability, battler, types|
        types.push(:FAIRY)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:IONIZEDALLOY,
    proc { |ability, battler, types|
        types.push(:ELECTRIC) if battler.battle.rainy?
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:COLORCOLLECTOR,
    proc { |ability, battler, types|
        if battler.effectActive?(:ColorCollector)
            types.concat(battler.effects[:ColorCollector])
        end
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:RAINBOWTRAIL,
    proc { |ability, battler, types|
        if battler.effectActive?(:RainbowTrail)
            types.concat(battler.effects[:RainbowTrail])
        end
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:MOLTENADAPTED,
    proc { |ability, battler, types|
        types.push(:FIRE)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:PLASMAADAPTED,
    proc { |ability, battler, types|
        types.push(:ELECTRIC)
        next types
    }
)

BattleHandlers::TypeCalcAbility.add(:TYPINGTROJAN,
    proc { |ability, battler, types|
        newTypes = []
        battler.eachMoveWithIndex do |m, i|
            break if i > 1
            moveType = m.type
            next if GameData::Type.get(moveType).pseudo_type
            next if newTypes.include?(moveType)
            newTypes.push(moveType)
        end
        unless newTypes.empty?
            types.replace(newTypes)
        end
        next types
    }
)