# Whether or not a Pokemon's "previously known moves" can also be mentored to other mons
# This means any move that shows up when using the move relearner
CAN_MENTOR_PREVIOUS_MOVES = true

def mentorCoordinator
    unless teamEditingAllowed?
        showNoTeamEditingMessage
        return
    end

    choices = []
    choices[cmdMentorMoves = choices.length] = _INTL("Mentor Moves")
    choices[cmdExplainMentorMoves = choices.length] = _INTL("What is Move Mentoring?")
    choices.push(_INTL("Cancel"))
    choice = pbMessage(_INTL("I'm the Mentor Coordinator. How can I help?"),choices,choices.length)

    if choice == cmdMentorMoves
        canChooseForMentoringProc = proc do |pkmn|
            pkmn.can_mentor_move?
        end
        learnMentorMoveProc = proc do |pkmn|
            pbMentorMoveScreen(pkmn)
        end
        pbChoosePokemonRepeatedly(learnMentorMoveProc, canChooseForMentoringProc)
    elsif choice == cmdExplainMentorMoves
        pbMessage(_INTL("I help your Pokemon to teach each other moves!"))
        pbMessage(_INTL("Pokemon can teach moves they know, moves they used to know, and moves earlier on their level up learnset."))
        pbMessage(_INTL("Any Pokemon in your party or in your PC can be a mentor."))
        pbMessage(_INTL("Pokemon can be taught any moves on their Other Moves list."))
    end
end

def getMovesKnownByMentors(pokemonToSkip = nil)
    movesKnownByMentors = []
    eachPokemonInPartyOrStorage do |otherPkmn|
        next if pokemonToSkip && pokemonToSkip.personalID == otherPkmn.personalID
        otherPkmn.moves.each do |m|
            movesKnownByMentors.push(m.id)
        end
        movesKnownByMentors.concat(getRelearnableMoves(otherPkmn)) if CAN_MENTOR_PREVIOUS_MOVES
    end
    movesKnownByMentors.uniq!
    return movesKnownByMentors
end

def getMentorableMoves(pkmn)
    movesKnownByMentors = getMovesKnownByMentors(pkmn)
    mentorableMoves = pkmn.learnable_moves & movesKnownByMentors
    return mentorableMoves
end

def pbMentorMoveScreen(pkmn)
    mentorableMoves = getMentorableMoves(pkmn)
    return false if mentorableMoves.empty?
    getMentorMovesProc = proc do |pokemon|
        getMentorableMoves(pkmn)
    end
    return moveLearningScreen(pkmn, getMentorMovesProc, addFirstMove: true)
end

class Pokemon
    def can_mentor_move?
        return false if egg?

        ourLearnableMoves = learnable_moves
        eachPokemonInPartyOrStorage do |otherPkmn|
            next if otherPkmn.personalID == @personalID
            otherPkmn.moves.each do |m|
                next if hasMove?(m.id)
                next unless ourLearnableMoves.include?(m.id)
                return true
            end
            if CAN_MENTOR_PREVIOUS_MOVES
                getRelearnableMoves(otherPkmn).each do |m|
                    next if hasMove?(m)
                    next unless ourLearnableMoves.include?(m)
                    return true
                end
            end
        end

        return false
    end
end
