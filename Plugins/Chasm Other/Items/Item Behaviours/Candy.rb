ItemHandlers::UseOnPokemon.add(:RARECANDY,proc { |item,pkmn,scene|
  pbLevelGivingItem(pkmn, item, scene)
})


def pbLevelGivingItem(pkmn, item, scene)
  if pkmn.level >= GameData::GrowthRate.max_level
    pbSceneDefaultDisplay(_INTL("It won't have any effect."),scene)
    return false
  elsif LEVEL_CAPS_USED && (pkmn.level + 1) > getLevelCap
      pbSceneDefaultDisplay(_INTL("It won't have any effect due to the level cap at {1}.", getLevelCap),scene)
      return false
  end

  # Ask the player how many they'd like to apply
  level_cap = LEVEL_CAPS_USED ? getLevelCap : growth_rate.max_level
  maxLevelIncrease = level_cap - pkmn.level
  maximum = [maxLevelIncrease, $PokemonBag.pbQuantity(item)].min # Max items which can be used
  if maximum > 1
      params = ChooseNumberParams.new
      params.setRange(1, maximum)
      params.setInitialValue(1)
      params.setCancelValue(0)
      question = _INTL("How many {1} do you want to use?", GameData::Item.get(item).name_plural)
      qty = pbMessageChooseNumber(question, params)
  else
      qty = 1
  end

  return false if qty < 1

  $PokemonBag.pbDeleteItem(item, qty - 1)
  pbChangeLevel(pkmn,pkmn.level + qty,scene)
  scene&.pbHardRefresh

  return true
end

ItemHandlers::UseOnPokemon.copy(:RARECANDY)

EXP_PER_EXTRA_SMALL = 250
EXP_PER_SMALL = EXP_PER_EXTRA_SMALL * 4
EXP_PER_MEDIUM = EXP_PER_SMALL * 4
EXP_PER_LARGE = EXP_PER_MEDIUM * 4
EXP_PER_EXTRA_LARGE = EXP_PER_LARGE * 4

EXP_CANDY_IDS = %i[EXPCANDYXL EXPCANDYL EXPCANDYM EXPCANDYS EXPCANDYXS]

def getEXPAmountForCandy(candyID)
  case candyID
  when :EXPCANDYXS
    return EXP_PER_EXTRA_SMALL
  when :EXPCANDYS
    return EXP_PER_SMALL
  when :EXPCANDYM
    return EXP_PER_MEDIUM
  when :EXPCANDYL
    return EXP_PER_LARGE
  when :EXPCANDYXL
    return EXP_PER_EXTRA_LARGE
  end
  return 0
end

ItemHandlers::UseOnPokemon.add(:EXPCANDYXS,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,EXP_PER_EXTRA_SMALL,item,scene)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYS,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,EXP_PER_SMALL,item,scene)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYM,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,EXP_PER_MEDIUM,item,scene)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYL,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,EXP_PER_LARGE,item,scene)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXL,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,EXP_PER_EXTRA_LARGE,item,scene)
})