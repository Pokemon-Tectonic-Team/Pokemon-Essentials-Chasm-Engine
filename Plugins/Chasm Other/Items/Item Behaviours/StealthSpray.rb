STEALTH_SPRAY_OPACITY = 100

def pbStealthSpray(item,steps)
  if stealthSprayActive?
    pbMessage(_INTL("But a stealth spray's effect still lingers from earlier."))
    return 0
  end
  pbUseItemMessage(item)
  $PokemonGlobal.stealthSpray = steps
  refreshPlayerAndFollowerPokemon
  return 3
end
  
ItemHandlers::UseInField.add(:STEALTHSPRAY,proc { |item|
  next pbStealthSpray(item,15)
})

def stealthSprayActive?
  $PokemonGlobal.stealthSpray = 0 if $PokemonGlobal.stealthSpray.nil?
  return $PokemonGlobal.stealthSpray.positive?
end