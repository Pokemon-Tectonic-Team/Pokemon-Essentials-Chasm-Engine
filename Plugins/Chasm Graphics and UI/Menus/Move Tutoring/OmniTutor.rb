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

def getOmniMoves(pkmn)
    relearnableMoves = getRelearnableMoves(pkmn)
    mentorableMoves = getMentorableMoves(pkmn)
    tmLearnableMoves = getTMLearnableMoves(pkmn)

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