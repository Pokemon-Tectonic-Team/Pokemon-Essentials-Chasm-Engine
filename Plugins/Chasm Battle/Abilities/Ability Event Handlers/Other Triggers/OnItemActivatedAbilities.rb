# When the JUGGLING user's own item activates, pass it to a random ally.
BattleHandlers::OnItemActivatedAbility.add(:JUGGLING,
    proc { |ability, user, item, battle|
        ally = nil
        user.eachAlly { |b| next unless b.canAddItem?(item); ally = b; break }
        next if ally.nil?
        battle.pbShowAbilitySplash(user, ability)
        ally.giveItem(item)
        battle.pbDisplay(_INTL("{1} juggled its {2} to {3}!", user.pbThis, getItemName(item), ally.pbThis(true)))
        battle.pbHideAbilitySplash(user)
        ally.pbHeldItemTriggerCheck
    }
)

# When an ally's item activates, the JUGGLING user catches it.
BattleHandlers::OnAllyItemActivatedAbility.add(:JUGGLING,
    proc { |ability, user, consumer, item, battle|
        # Skip if the consumer also has JUGGLING — already handled by OnItemActivatedAbility
        next if consumer.hasActiveAbility?(:JUGGLING)
        next unless user.canAddItem?(item)
        battle.pbShowAbilitySplash(user, ability)
        user.giveItem(item)
        battle.pbDisplay(_INTL("{1} caught {2}'s {3}!", user.pbThis, consumer.pbThis(true), getItemName(item)))
        battle.pbHideAbilitySplash(user)
        user.pbHeldItemTriggerCheck
    }
)
