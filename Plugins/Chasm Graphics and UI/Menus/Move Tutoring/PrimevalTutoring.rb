def primevalTutor()
    if !teamEditingAllowed?()
		showNoTeamEditingMessage()
		return
	end
    canPrimevalTutorProc = proc do |pkmn|
        pkmn.species_data.can_learn_sketch?
    end
    learnPrimevalMoveProc = proc do |pkmn|
        pbPrimevalTutorScreen(pkmn)
    end
    pbChoosePokemonRepeatedly(learnPrimevalMoveProc, canPrimevalTutorProc)
end

def pbPrimevalTutorScreen(pkmn)
    primevalMoves = getPrimevalMoves(pkmn)
    return false if primevalMoves.empty?
    getPrimevalMovesProc = proc do |pokemon|
        getPrimevalMoves(pokemon)
    end
    return moveLearningScreen(pkmn, getPrimevalMovesProc, addFirstMove: true)
end

def getPrimevalMoves(pkmn)
    moves = []
    GameData::Move.each do |moveData|
        next unless moveData.primeval
        next if pkmn.hasMove?(moveData.id)
        moves.push(moveData.id)
    end
    return moves
end