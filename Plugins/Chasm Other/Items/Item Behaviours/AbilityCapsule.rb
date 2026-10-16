def pbSwapAbility(pkmn, scene = nil)
  unless teamEditingAllowed?
    showNoTeamEditingMessage
    return false
  end
  
  abils = pkmn.getAbilityList
  abil1 = nil; abil2 = nil
  for i in abils
    abil1 = i[0] if i[1] == 0
    abil2 = i[0] if i[1] == 1
  end

  if abil1.nil? || abil2.nil? || pkmn.hasHiddenAbility? || pkmn.isSpecies?(:ZYGARDE)
    pbSceneDefaultDisplay(_INTL("It won't have any effect."), scene)
    return false
  end

  newabilindex = (pkmn.ability_index + 1) % 2
  newabil = GameData::Ability.get((newabilindex == 0) ? abil1 : abil2)
  newabilname = newabil.name

  if newabil.id == :PACIFIST && $Trainer.able_pokemon_count <= 1
    pbSceneDefaultDisplay(_INTL("You may not make your last able Pokémon a pacifist."), scene)
    return false
  end

  if GameData::Ability.getByFlag("UnableByDefault").include?(newabil.id) && $Trainer.able_pokemon_count <= 1
    pbSceneDefaultDisplay(_INTL("You may not make your last able Pokémon have this ability."), scene)
    return false
  end

  if pbSceneDefaultConfirm(_INTL("Would you like to change {1}'s Ability to {2}?", pkmn.name, newabilname),scene)
    pkmn.ability_index = newabilindex
    pkmn.ability = newabil
    scene&.pbRefresh
    pbSceneDefaultDisplay(_INTL("{1}'s Ability changed to {2}!", pkmn.name, newabilname),scene)
    pkmn.calc_stats
    return true
  end
  return false
end

ItemHandlers::UseOnPokemon.add(:ABILITYCAPSULE,proc { |item,pkmn,scene|
    next pbSwapAbility(pkmn, scene)
})
  
ItemHandlers::UseOnPokemon.copy(:ABILITYCAPSULE,:VIRALHELIX)