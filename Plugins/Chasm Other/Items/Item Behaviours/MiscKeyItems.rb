ItemHandlers::UseInField.add(:TOWNMAP, proc { |_item|
    pbShowMap(-1, false)
    next 1
})

ItemHandlers::UseInField.add(:COINCASE, proc { |_item|
    pbMessage(_INTL("Coins: {1}", $Trainer.coins.to_s_formatted))
    next 1
})

ItemHandlers::UseInField.add(:EXPALL, proc { |_item|
    $PokemonBag.pbChangeItem(:EXPALL, :EXPALLOFF)
    pbMessage(_INTL("The Exp Share was turned off."))
    next 1
})

ItemHandlers::UseInField.add(:EXPALLOFF, proc { |_item|
    $PokemonBag.pbChangeItem(:EXPALLOFF, :EXPALL)
    pbMessage(_INTL("The Exp Share was turned on."))
    next 1
})
