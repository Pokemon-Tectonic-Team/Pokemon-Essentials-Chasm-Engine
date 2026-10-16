def moveRelearner
	unless teamEditingAllowed?
		showNoTeamEditingMessage
		return
	end

	choices = []
	choices[cmdMoveRelearning = choices.length] = _INTL("Relearn Moves")
	choices[cmdExplainMoveRelearning = choices.length] = _INTL("What is Move Relearning?")
	choices.push(_INTL("Cancel"))
	choice = pbMessage(_INTL("I'm the Move Relearner. How can I help?"),choices,choices.length)

	if choice == cmdMoveRelearning
		canChooseForRelearningProc = proc do |pkmn|
			pkmn.can_relearn_move?
		end
		relearnMoveProc = proc do |pkmn|
			pbRelearnMoveScreen(pkmn)
		end
		pbChoosePokemonRepeatedly(relearnMoveProc, canChooseForRelearningProc)
	elsif choice == cmdExplainMoveRelearning
		pbMessage(_INTL("I can teach moves to your Pokémon -- at no cost!"))
		pbMessage(_INTL("I know every single move that Pokémon learn while leveling up or evolving."))
		pbMessage(_INTL("I can also help Pokemon to relearn moves they learned through TMs, Mentoring, or Sketching!"))
	end
end

def getRelearnableMoves(pkmn)
	moves = []
	pkmn.getMoveList.each do |m|
		next if m[0] > pkmn.level || pkmn.hasMove?(m[1])
		moves.push(m[1]) if !moves.include?(m[1])
	end
	
	pkmn.first_moves.each do |m|
		next if pkmn.hasMove?(m)
		moves.push(m) if !moves.include?(m)
	end

	moves.uniq!
	moves.compact!
	
	return moves
end

def pbRelearnMoveScreen(pkmn)
	relearnableMoves = getRelearnableMoves(pkmn)
	return false if relearnableMoves.empty?
	getRelearnableMovesProc = proc do |pokemon|
		getRelearnableMoves(pokemon)
	end
	return moveLearningScreen(pkmn, getRelearnableMovesProc)
end

class Pokemon
	def can_relearn_move?
		return false if egg?
		return !getRelearnableMoves(self).empty?
	end
end