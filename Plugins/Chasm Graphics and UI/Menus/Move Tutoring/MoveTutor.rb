class Pokemon
    def can_tutor_move?
        return false if egg?
        species_data = GameData::Species.get(@species)
        species_data.tutor_moves.each { |m| 
            return true unless hasMove?(m)
        }
        return false
    end
end

def pbTutorMoveScreen(pkmn)
    return [] if !pkmn || pkmn.egg?

    movesProc = proc do |pokemon|
        moves = []
        species_data = GameData::Species.get(pokemon.species)
        species_data.tutor_moves.each do |m|
            next if pokemon.hasMove?(m)
            moves.push(m) if !moves.include?(m)
        end
        next moves
    end

    retval = true
    pbFadeOutIn {
        scene = MoveLearner_Scene.new
        screen = MoveLearnerScreen.new(scene)
        retval = screen.pbStartScreen(pkmn,movesProc,true)
    }
    return retval
end