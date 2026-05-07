BattleHandlers::EndOfMoveItem.add(:LEPPABERRY,
    proc { |item, battler, battle, forced|
        next false if !forced && !battler.canConsumeBerry?
        choice = nil
        if battler.lastMoveUsed
            battler.pokemon.moves.each_with_index do |m, i|
                next if m.id != battler.lastMoveUsed
                if m.total_pp > 0 && m.pp == 0
                    choice = i
                end
                break
            end
        end
        if choice.nil?
            battler.pokemon.moves.each_with_index do |m, i|
                next if m.total_pp <= 0
                if m.pp == 0
                    choice = i
                    break
                end
            end
        end
        if choice.nil? && forced
            battler.pokemon.moves.each_with_index do |m, i|
                next if m.total_pp <= 0 || m.pp == m.total_pp
                choice = i
                break
            end
        end
        next false if choice.nil?
        itemName = GameData::Item.get(item).name
        battle.pbCommonAnimation("Nom", battler) unless forced
        pkmnMove = battler.pokemon.moves[choice]
        pkmnMove.pp += 10
        pkmnMove.pp = pkmnMove.total_pp if pkmnMove.pp > pkmnMove.total_pp
        battler.moves[choice].pp = pkmnMove.pp
        moveName = pkmnMove.name
        if forced
            battle.pbDisplay(_INTL("{1} restored its {2}'s PP.", battler.pbThis, moveName))
        else
            battle.pbDisplay(_INTL("{1}'s {2} restored its {3}'s PP!", battler.pbThis, itemName, moveName))
        end
        next true
    }
)
