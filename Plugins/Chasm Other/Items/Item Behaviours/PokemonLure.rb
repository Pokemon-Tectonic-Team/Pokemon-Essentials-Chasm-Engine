def usePokemonLure
	$PokemonGlobal.pokemon_lure_inactive = !$PokemonGlobal.pokemon_lure_inactive
	duration = amuletMessageDuration / 2
	if $PokemonGlobal.pokemon_lure_inactive
		pbMessage(_INTL("\\db[Items/POKEMONLURE_inactive]The Pokémon Lure stops emitting fragrance.\\wtnp[{1}]",duration))
	else
		pbMessage(_INTL("\\db[Items/POKEMONLURE]The Pokémon Lure emits a sweet-smelling fragrance.\\wtnp[{1}]",duration))
	end
	return true
end

ItemHandlers::UseFromBag.add(:POKEMONLURE,proc { |item|
    usePokemonLure
	next 1
})

ItemHandlers::ConfirmUseInField.add(:POKEMONLURE,proc { |item|
  next true
})

ItemHandlers::UseInField.add(:POKEMONLURE,proc { |item|
	next usePokemonLure
})

def pokemonLureActive?
    return $PokemonBag && pbHasItem?(:POKEMONLURE) && !pokemonLureInactive?
end

def pokemonLureInactive?
	return ($PokemonGlobal.pokemon_lure_inactive || false)
end