ItemHandlers::UseOnPokemon.add(:FIGMENT,proc { |item,pkmn,scene|
    unless teamEditingAllowed?
        showNoTeamEditingMessage
        return
    end
    unless pkmn.can_learn_any_move?
        pbSceneDefaultDisplay(_INTL("It won't have any effect."),scene)
        next false
    end
    getFigmentMovesProc = proc do |pokemon|
        pokemon.learnable_moves
    end
    next moveLearningScreen(pkmn, getFigmentMovesProc, addFirstMove: true, singleUse: true)
})

class Pokemon
	def can_learn_any_move?
		return false if egg?
		return !learnable_moves.empty?
	end
end