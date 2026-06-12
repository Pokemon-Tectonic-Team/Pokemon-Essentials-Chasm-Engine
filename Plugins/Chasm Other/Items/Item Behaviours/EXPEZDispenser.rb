EXP_JAR_BASE_EFFICIENCY = 1.0

class PokemonGlobalMetadata
	attr_accessor :expJARUpgraded
end

ItemHandlers::UseOnPokemon.add(:EXPEZDISPENSER,proc { |item,pkmn,scene|
	# Do nothing if the EXP-EZ Dispenser is empty
	if $PokemonGlobal.expJAR == 0
		pbSceneDefaultDisplay(_INTL("There is no EXP stored!"),scene)
		next false
	end

	current_lvl = pkmn.level
	current_exp = pkmn.exp
	level_cap = LEVEL_CAPS_USED ? getLevelCap : growth_rate.max_level

	# Do nothing if the pokemon's already at the level cap
	if pkmn.level >= level_cap
		pbSceneDefaultDisplay(_INTL("It won't have any effect."),scene)
		next false
	end

	expAfterAllFed = pkmn.growth_rate.add_exp(current_exp, $PokemonGlobal.expJAR)
	highestLevelForStoredEXP = pkmn.growth_rate.level_from_exp(expAfterAllFed)

	# Do nothing if the EXP-EZ Dispenser is empty
	if highestLevelForStoredEXP == current_lvl
		pbSceneDefaultDisplay(_INTL("There is not enough EXP stored to level up!"),scene)
		next false
	end

	# Player chooses the target level
	params = ChooseNumberParams.new
	choiceMaximum = [level_cap,highestLevelForStoredEXP].min
	params.setRange(current_lvl+1, choiceMaximum)
	params.setInitialValue(level_cap)
	params.setCancelValue(0)
	question = _INTL("Feed candy till {1} reaches which level?", pkmn.name)
	targetLevel = pbMessageChooseNumber(question, params)
	next true if targetLevel == 0

	# Max XP and level
	maxxp = pkmn.growth_rate.minimum_exp_for_level(targetLevel)
	
	expAmount = [maxxp - current_exp, $PokemonGlobal.expJAR].min

	# Apply the new EXP, accounting for the level cap
	$PokemonGlobal.expJAR -= expAmount
	pkmn.exp += expAmount
	new_level = pkmn.level
	if $Options.expez_dispenser_animation == 1
		if new_level == level_cap
			pbSceneDefaultDisplay(_INTL("{1} gained only {3} Exp. Points due to the level cap at level {2}.", pkmn.name, level_cap, separate_comma(expAmount)),scene)
		else
			pbSceneDefaultDisplay(_INTL("{1} gained {2} Exp. Points!", pkmn.name, separate_comma(expAmount)),scene)
		end
	else
		pbFadeOutInWithMusic do
			evo = PokemonFeedCandyScene.new
			evo.pbStartScreen(pkmn, expAmount)
			evo.pbFeedCandy
			if new_level == level_cap
				pbSceneDefaultDisplay(_INTL("{1} gained only {3} Exp. Points due to the level cap at level {2}.", pkmn.name, level_cap, separate_comma(expAmount)),scene)
			else
				pbSceneDefaultDisplay(_INTL("{1} gained {2} Exp. Points!", pkmn.name, separate_comma(expAmount)),scene)
			end
			evo.pbEndScreen
		end
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

def addEXPCandyToDispenser(item, quantity = 1)
    expAmount = getEXPAmountForCandy(item) * quantity
    expAmount = applyEXPCandyMultipliers(expAmount)
    $PokemonGlobal.expJAR += expAmount
end

def moveAllBagEXPCandyToDispenser
	storedAny = false
	GameData::Item.getByFlag("EXPCandy").each do |candyID|
		next unless pbHasItem?(candyID)
		amountOfThisCandy = pbQuantity(candyID)
		addEXPCandyToDispenser(candyID, amountOfThisCandy)
		pbDeleteItem(candyID, amountOfThisCandy)
		storedAny = true
	end
	pbMessage(_INTL("\\i[EXPEZDISPENSER]You put all of your EXP Candy into the \\c[1]{1}\\c[0]!\\wtnp[30]", getItemName(:EXPEZDISPENSER))) if storedAny
end

def calculateCandySplitForEXP(expAmount)
	# Calculate how many of each candy size could be given
	candyTotals = []
	EXP_CANDY_IDS.each do |expCandyID|
		expPerCandy = getEXPAmountForCandy(expCandyID)
		amountOfThisCandy = expAmount / expPerCandy
		candyTotals.push(amountOfThisCandy)
		expAmount = expAmount % expPerCandy
	end
	return candyTotals
end

def separate_comma(number)
	reverse_digits = number.to_s.chars.reverse
	reverse_digits.each_slice(3).map(&:join).join(",").reverse
end