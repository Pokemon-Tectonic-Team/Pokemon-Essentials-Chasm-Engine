BattleHandlers::EORGainItemAbility.add(:HARVEST,
    proc { |ability, battler, battle|
        next unless battler.recyclableItem
        next unless GameData::Item.get(battler.recyclableItem).is_berry?
        next if battler.hasItem?(battler.recyclableItem)
        next if !battle.sunny? && !(battle.pbRandom(100) < 50)
        recyclingMsg = _INTL("{1} harvested one {2}!", battler.pbThis, getItemName(battler.recyclableItem))
        battler.recycleItem(recyclingMsg: recyclingMsg, ability: ability)
    }
)

BattleHandlers::EORGainItemAbility.add(:LARDER,
    proc { |ability, battler, battle|
        next unless battler.recyclableItem
        next unless GameData::Item.get(battler.recyclableItem).is_berry?
        next if battler.hasItem?(battler.recyclableItem)
        recyclingMsg = _INTL("{1} withdrew another {2}!", battler.pbThis, getItemName(battler.recyclableItem))
        battler.recycleItem(recyclingMsg: recyclingMsg, ability: ability)
    }
)

BattleHandlers::EORGainItemAbility.add(:GOURMAND,
    proc { |ability, battler, battle|
        itemsCanAdd = []
        GameData::Item.getByFlag("Pinch").each do |pinch|
            next unless GameData::Item.get(pinch).legal?
            next unless battler.canAddItem?(pinch)
            itemsCanAdd.push(pinch) 
        end
        next if itemsCanAdd.length == 0
        battle.pbShowAbilitySplash(battler, ability)
        itemToAdd = itemsCanAdd.sample
        battler.giveItem(itemToAdd)
        battle.pbDisplay(_INTL("{1} was delivered one {2}!", battler.pbThis, getItemName(itemToAdd)))
        battle.pbHideAbilitySplash(battler)
        battler.pbHeldItemTriggerCheck
    }
)

BattleHandlers::EORGainItemAbility.add(:STRATAGEM,
    proc { |ability, battler, battle|
        itemsCanAdd = []
        attackingMoves = battler.moves.select { |m| m.category != :Status }
        GameData::Item.getByFlag("TypeGem").each do |gem|
            next unless GameData::Item.get(gem).legal?
            next unless battler.canAddItem?(gem)
            typeName = gem.to_s.chomp("GEM") # ROCKGEM -> ROCK
            next unless attackingMoves.any? { |m| m.type == typeName.to_sym }
            itemsCanAdd.push(gem) 
        end
        next if itemsCanAdd.length == 0
        battle.pbShowAbilitySplash(battler, ability)
        itemToAdd = itemsCanAdd.sample
        battler.giveItem(itemToAdd)
        battle.pbDisplay(_INTL("{1} found a {2} in its shell!", battler.pbThis, getItemName(itemToAdd)))
        battle.pbHideAbilitySplash(battler)
        battler.pbHeldItemTriggerCheck
    }
)