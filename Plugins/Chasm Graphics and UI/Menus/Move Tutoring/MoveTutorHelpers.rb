def moveLearningScreen(pkmn,movesProc,addFirstMove: false, singleUse: false)
	return [] if !pkmn || pkmn.egg?

	if !teamEditingAllowed?()
		showNoTeamEditingMessage()
		return
	end
	
	retval = true
	pbFadeOutIn {
	  scene = MoveLearner_Scene.new
	  screen = MoveLearnerScreen.new(scene)
	  retval = screen.pbStartScreen(pkmn,movesProc,addFirstMove: addFirstMove, singleUse: singleUse)
	}
	return retval
end

def eachPokemonInPartyOrStorage()
	$Trainer.party.each do |pkmn|
		yield pkmn
	end

	for i in 0...Settings::NUM_STORAGE_BOXES
		for j in 0...$PokemonStorage.maxPokemon(i)
			pkmn = $PokemonStorage[i, j]
			yield pkmn if pkmn
		end
	end
end