def techSupporter
    unless teamEditingAllowed?
        showNoTeamEditingMessage
        return
    end

    choices = []
    choices[cmdUseTMs = choices.length] = _INTL("Use TMs")
    choices[cmdExplainTechnicalMachines = choices.length] = _INTL("What are Technical Machines?")
    choices.push(_INTL("Cancel"))
    choice = pbMessage(_INTL("I'm the Tech Supporter. How can I help?"),choices,choices.length)

    if choice == cmdUseTMs
        canChooseForTMsProc = proc do |pkmn|
            pkmn.can_teach_TM_move?
        end
        learnTMMovesProc = proc do |pkmn|
            pbTMMovesScreen(pkmn)
        end
        pbChoosePokemonRepeatedly(learnTMMovesProc, canChooseForTMsProc)
    elsif choice == cmdExplainTechnicalMachines
        pbMessage(_INTL("Technical Machines, or TMs for short, are items that teach moves to your Pokemon!"))
        pbMessage(_INTL("TMs are common place in our modern world, and they be unweildy to use."))
        pbMessage(_INTL("I'm here to help you use your TMs quickly and efficiently."))
        pbMessage(_INTL("Just select a Pokemon, and you'll be able to teach it any of the compatible TMs you own!"))
    end
end

def getMovesAvailableFromTMs
    moves = []
    $PokemonBag.pockets.each do |pocket|
        pocket.each do |itemEntry|
            itemID = itemEntry[0]
            itemData = GameData::Item.get(itemID)
            next unless itemData.is_machine?
            moves.push(itemData.move)
        end
    end

    moves.uniq!
    moves.compact!

    return moves
end

def getTMLearnableMoves(pkmn)
    movesAvailableByTM = getMovesAvailableFromTMs
    tmAbleMoves = pkmn.learnable_moves & movesAvailableByTM
    return tmAbleMoves
end

def pbTMMovesScreen(pkmn)
    tmAbleMoves = getTMLearnableMoves(pkmn)
    return false if tmAbleMoves.empty?
    getTMMovesProc = proc do |pokemon|
        getTMLearnableMoves(pkmn)
    end
    return moveLearningScreen(pkmn, getTMMovesProc, addFirstMove: true)
end

class Pokemon
    def can_teach_TM_move?
        return false if egg?

        ourLearnableMoves = learnable_moves
        $PokemonBag.pockets.each do |pocket|
            pocket.each do |itemEntry|
                itemID = itemEntry[0]
                itemData = GameData::Item.get(itemID)
                next unless itemData.is_machine?
                tmMove = itemData.move
                next if hasMove?(tmMove)
                next unless ourLearnableMoves.include?(tmMove)
                return true
            end
        end
        return false
    end
end
