EXP_JAR_BASE_EFFICIENCY = 1.0

class PokemonGlobalMetadata
	attr_accessor :expJARUpgraded
end

ItemHandlers::UseOnPokemon.add(:EXPEZDISPENSER,proc { |item,pkmn,scene|
	current_lvl = pkmn.level
	current_exp = pkmn.exp
	level_cap = LEVEL_CAPS_USED ? getLevelCap : growth_rate.max_level

	# Do nothing if the EXP-EZ Dispenser is empty
	if $PokemonGlobal.expJAR == 0
		pbSceneDefaultDisplay(_INTL("There is no EXP stored!"),scene)
		next false
	end

	# Do nothing if the pokemon's already at the level cap
	if pkmn.level >= level_cap
		pbSceneDefaultDisplay(_INTL("It won't have any effect."),scene)
		next false
	end

	# Max XP and level
	maxxp = pkmn.growth_rate.minimum_exp_for_level(level_cap)
	
	expAmount = [maxxp - current_exp, $PokemonGlobal.expJAR].min

	# Apply the new EXP, accounting for the level cap
	$PokemonGlobal.expJAR -= expAmount
	pkmn.exp += expAmount
	new_level = pkmn.level
	if new_level == level_cap
		pbSceneDefaultDisplay(_INTL("{1} gained only {3} Exp. Points due to the level cap at level {2}.", pkmn.name, level_cap, separate_comma(expAmount)),scene)
	else
		pbSceneDefaultDisplay(_INTL("{1} gained {2} Exp. Points!", pkmn.name, separate_comma(expAmount)),scene)
	end
	scene&.pbRefresh

	# Leave if didn't level up
	next true if new_level == current_lvl

	# Show messages surrounding leveling up
	showPokemonChangesWindow(pkmn) do
		pkmn.calc_stats
		scene&.pbRefresh
		pbMessage(_INTL("{1} grew to Lv. {2}!", pkmn.name, new_level))
	end

	(new_level - current_lvl).times do
		pkmn.changeHappiness("candylevelup")
	end
	
	# Learn new moves upon level up
	unless $Options.prompt_level_moves == 1
		movelist = pkmn.getMoveList
		for i in movelist
			next if i[0] <= current_lvl
			break if i[0] > new_level
			pbLearnMove(pkmn, i[1], true)
		end
	end

	# Check for evolution
	while true
		newspecies = pkmn.check_evolution_on_level_up
		break unless newspecies
		evolutionSuccess = false
		pbFadeOutInWithMusic do
			evo = PokemonEvolutionScene.new
			evo.pbStartScreen(pkmn, newspecies)
			evolutionSuccess = true if evo.pbEvolution
			evo.pbEndScreen
			scene&.pbRefresh
		end
		break unless evolutionSuccess
	end

	next true
})

def calculateCandySplitForEXP(expAmount, biggerSized = false)
	# Calculate how many of each candy size could be given
	if !biggerSized
		xsCandyTotal = expAmount / EXP_PER_EXTRA_SMALL
		sCandyTotal = xsCandyTotal / 4
		xsCandyTotal = xsCandyTotal % 4
	else
		xsCandyTotal = 0
		sCandyTotal = expAmount / (EXP_PER_EXTRA_SMALL * 4)
	end
	mCandyTotal = sCandyTotal / 4
	sCandyTotal = sCandyTotal % 4
	if biggerSized
		lCandyTotal = mCandyTotal / 4
		mCandyTotal = mCandyTotal % 4
	else
		lCandyTotal = 0
	end
	return xsCandyTotal,sCandyTotal,mCandyTotal,lCandyTotal
end

def separate_comma(number)
	reverse_digits = number.to_s.chars.reverse
	reverse_digits.each_slice(3).map(&:join).join(",").reverse
end