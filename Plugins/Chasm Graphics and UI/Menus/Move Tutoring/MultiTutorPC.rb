def multiTutorPC
    loop do
        choices = []
        choices[cmdMentorMoves = choices.length] = _INTL("Mentor Moves")
        choices[cmdRelearnMoves = choices.length] = _INTL("Relearn Moves")
        choices[cmdUseTMs = choices.length] = _INTL("Use TMs")
        choices[cmdAdjustStylePoints = choices.length] = _INTL("Adjust Style Points")
        choices.push(_INTL("Cancel"))
        choice = pbMessage(_INTL("Open which utility?"),choices,choices.length)
        break if choice == choices.length - 1
    
        case choice
        when cmdMentorMoves
            canChooseForMentoringProc = proc do |pkmn|
                pkmn.can_mentor_move?
            end
            learnMentorMoveProc = proc do |pkmn|
                pbMentorMoveScreen(pkmn)
            end
            pbChoosePokemonRepeatedly(learnMentorMoveProc, canChooseForMentoringProc)
        when cmdRelearnMoves
            canChooseForRelearningProc = proc do |pkmn|
                pkmn.can_relearn_move?
            end
            relearnMoveProc = proc do |pkmn|
                pbRelearnMoveScreen(pkmn)
            end
            pbChoosePokemonRepeatedly(relearnMoveProc, canChooseForRelearningProc)
        when cmdUseTMs
            canChooseForTMsProc = proc do |pkmn|
                pkmn.can_teach_TM_move?
            end
            learnTMMovesProc = proc do |pkmn|
                pbTMMovesScreen(pkmn)
            end
            pbChoosePokemonRepeatedly(learnTMMovesProc, canChooseForTMsProc)
        when cmdAdjustStylePoints
            while true
                choosePokemonToStyle
                break if $game_variables[1] < 0
                pbStyleValueScreen(pbGetPokemon(1))
            end
        end
    end
end