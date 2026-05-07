def useOmniTutor()
    if !teamEditingAllowed?()
		showNoTeamEditingMessage()
		return
	end

    canOmniTutorProc = proc do |pkmn|
        pkmn.can_omni_tutor?
    end
    learnFromOmniTutorProc = proc do |pkmn|
        omniTutorScreen(pkmn)
    end
    pbChoosePokemonRepeatedly(learnFromOmniTutorProc, canOmniTutorProc)
end

def getTMLearnableMoves
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

def getOmniMoves(pkmn)
    relearnableMoves = getRelearnableMoves(pkmn)
    mentorableMoves = getMentorableMoves(pkmn)
    tmLearnableMoves = getTMLearnableMoves

    omniMoves = [relearnableMoves, mentorableMoves, tmLearnableMoves].reduce([], :concat)
    omniMoves = omniMoves & pkmn.learnable_moves

    return omniMoves
end

def omniTutorScreen(pkmn)
    getOmniMovesProc = proc do |pokemon|
        getOmniMoves(pokemon)  
    end
    return moveLearningScreen(pkmn, getOmniMovesProc, addFirstMove: true)
end

class Pokemon
	def can_omni_tutor?
		return false if egg?
		return !getOmniMoves(self).empty?
	end
end