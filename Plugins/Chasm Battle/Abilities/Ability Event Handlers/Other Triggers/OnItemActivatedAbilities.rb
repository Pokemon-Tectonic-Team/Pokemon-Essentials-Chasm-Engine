# When the JUGGLING user's own item activates, pass it to an ally.
# If multiple valid allies exist and the user is player-controlled, the player chooses.
BattleHandlers::OnItemActivatedAbility.add(:JUGGLING,
    proc { |ability, user, item, battle|
        valid_allies = []
        user.eachAlly { |b| valid_allies << b if b.canAddItem?(item) }
        next if valid_allies.empty?
        battle.pbShowAbilitySplash(user, ability)
        if valid_allies.length == 1
            ally = valid_allies[0]
        elsif user.pbOwnedByPlayer?
            choice = battle.scene.pbChooseWithThinkingLoop(
                _INTL("Pass {1} to which ally?", getItemName(item)),
                valid_allies.map { |b| b.pbThis }
            )
            ally = valid_allies[choice]
        else
            ally = valid_allies.sample
        end
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
        # Prevent multiple Juggling users from each catching the same item.
        # The flag is reset at the call site before each activation's ally loop.
        next if battle.jugglingItemTaken
        battle.jugglingItemTaken = true
        battle.pbShowAbilitySplash(user, ability)
        user.giveItem(item)
        battle.pbDisplay(_INTL("{1} caught {2}'s {3}!", user.pbThis, consumer.pbThis(true), getItemName(item)))
        battle.pbHideAbilitySplash(user)
        user.pbHeldItemTriggerCheck
    }
)
