def hasEitherTaoStone?
    return pbHasItem?(:LIGHTSTONE) || pbHasItem?(:DARKSTONE)
end

TAO_STONES = %i[LIGHTSTONE DARKSTONE]

def pbChooseTaoStone(var = 0)
	ret = nil
	pbFadeOutIn {
	  scene = PokemonBag_Scene.new
	  screen = PokemonBagScreen.new(scene,$PokemonBag)
	  ret = screen.pbChooseItemScreen(Proc.new { |item| TAO_STONES.include?(item) })
	}
	$game_variables[var] = ret || :NONE if var > 0
	return ret
end

RESHIRAM_REVIVED_GLOBAL = 378
ZEKROM_REVIVED_GLOBAL = 379

def reviveTaoStone(stone)
    unless TAO_STONES.include?(stone)
		pbMessage(_INTL("Was this an attempt at a gaff?"))
        pbMessage(_INTL("Prank the dottering old man, eh?"))
        pbMessage(_INTL("I've not gone blind yet, fledgling!"))
		return
	end

	stonesToSpecies = {
		:LIGHTSTONE => :RESHIRAM,
		:DARKSTONE => :ZEKROM,
	}

	species = stonesToSpecies[stone] || nil
	
	if species.nil?
		pbMessage(_INTL("Error! Could not determine how to revive the given stone."))
		return
	end

	item_data = GameData::Item.get(stone)
	pbMessage(_INTL("\\PN hands over the {1}.",item_data.name))
	
	blackFadeOutIn(30) {
		$PokemonBag.pbDeleteItem(stone)
	}

	setGlobalSwitch(RESHIRAM_REVIVED_GLOBAL) if species == :RESHIRAM
	setGlobalSwitch(ZEKROM_REVIVED_GLOBAL) if species == :ZEKROM

    pbMessage(_INTL("I have never been more overcome with emotion than in this very moment."))
    pbMessage(_INTL("It's beautiful."))
    pbMessage(_INTL("Here, take it."))

    pbAddPokemon(species,50)

    pbMessage(_INTL("All I ask is that you appreciate it for many years, young one."))
end