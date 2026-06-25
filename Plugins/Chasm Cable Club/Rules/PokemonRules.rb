# Classes referenced by name from a .rules file's "PokemonRules" key, e.g.
# "PokemonRules = NoLegendaryRestriction". Each is checked once per Pokemon
# entered, via isValid?(pkmn); see TeamRules.rb for the classes checked
# against the team instead.
#
# errorMessage takes the same pkmn isValid? was just called with (the one it
# failed on), and returns an Array of every distinct thing about that
# Pokemon which violates the rule (e.g. one entry per banned move it knows,
# not just the first) - PokemonRuleSet#pokemonInvalidReasons concatenates
# these across every failing rule so a player can see everything wrong with
# a Pokemon at once. The generic "{name} is not allowed" fallback
# (Rulesets.rb) already names the Pokemon, so errorMessage only needs to
# add the "why".

# PokemonRules = StandardRestriction
# Bans eggs, Pokemon with a base stat total of 600 or more, and Wynaut/
# Wobbuffet specifically, but always allows Truant/Slow Start abilities and
# Dragonite/Salamence/Tyranitar by name despite their BST. Matches the
# Generation IV "Standard" ban list used by the Cup presets in Rulesets.rb.
class StandardRestriction
  def isValid?(pkmn)
    return false if !pkmn || pkmn.egg?
    # Species with disadvantageous abilities are not banned
    pkmn.species_data.abilities.each do |a|
      return true if [:TRUANT, :SLOWSTART].include?(a)
    end
    # Certain named species are not banned
    return true if [:DRAGONITE, :SALAMENCE, :TYRANITAR].include?(pkmn.species)
    # Certain named species are banned
    return false if [:WYNAUT, :WOBBUFFET].include?(pkmn.species)
    # Species with total base stat 600 or more are banned
    bst = 0
    pkmn.baseStats.each_value { |s| bst += s }
    return false if bst >= 600
    # Is valid
    return true
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is an egg, which isn't allowed.", pkmn.name)] if pkmn.egg?
    return [_INTL("{1} is banned under the Standard ruleset.", pkmn.name)] if [:WYNAUT, :WOBBUFFET].include?(pkmn.species)
    bst = 0
    pkmn.baseStats.each_value { |s| bst += s }
    return [_INTL("{1} has a base stat total of {2}, which is 600 or more.", pkmn.name, bst)]
  end
end

# PokemonRules = LaxStandardRestriction
# Same as StandardRestriction, but the BST ban only kicks in above 600 (not
# at 600), and Defeatist is also allowed alongside Truant/Slow Start.
class LaxStandardRestriction
  def isValid?(pkmn)
    return false if !pkmn || pkmn.egg?
    # Species with disadvantageous abilities are not banned
    pkmn.species_data.abilities.each do |a|
      return true if [:TRUANT, :SLOWSTART, :DEFEATIST].include?(a)
    end
    # Certain named species are banned
    return false if [:WYNAUT, :WOBBUFFET].include?(pkmn.species)
    # Species with total base stat 600 or more are banned
    bst = 0
    pkmn.baseStats.each_value { |s| bst += s }
    return false if bst > 600
    # Is valid
    return true
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is an egg, which isn't allowed.", pkmn.name)] if pkmn.egg?
    return [_INTL("{1} is banned under the Standard ruleset.", pkmn.name)] if [:WYNAUT, :WOBBUFFET].include?(pkmn.species)
    bst = 0
    pkmn.baseStats.each_value { |s| bst += s }
    return [_INTL("{1} has a base stat total of {2}, which is over 600.", pkmn.name, bst)]
  end
end

# PokemonRules = NoLegendaryRestriction
# Bans eggs and any species flagged as legendary.
class NoLegendaryRestriction
  def isValid?(pkmn)
    return false if !pkmn || pkmn.egg?
    return !pkmn.species_data.isLegendary?
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is an egg, which isn't allowed.", pkmn.name)] if pkmn.egg?
    return [_INTL("{1} is a legendary Pokémon, which isn't allowed.", pkmn.name)]
  end
end

# PokemonRules = HeightRestriction,maxHeightInMeters
# Bans any Pokemon taller than the given height, in meters.
class HeightRestriction
  def initialize(maxHeightInMeters)
    @level = maxHeightInMeters
  end

  def isValid?(pkmn)
    height = (pkmn.is_a?(Pokemon)) ? pkmn.height : GameData::Species.get(pkmn).height
    return height <= (@level * 10).round
  end

  def errorMessage(pkmn)
    height = (pkmn.is_a?(Pokemon)) ? pkmn.height : GameData::Species.get(pkmn).height
    return [_INTL("{1} is {2}m tall, taller than the {3}m maximum.", pkmn.name, height / 10.0, @level)]
  end
end

# PokemonRules = WeightRestriction,maxWeightInKg
# Bans any Pokemon heavier than the given weight, in kilograms.
class WeightRestriction
  def initialize(maxWeightInKg)
    @level = maxWeightInKg
  end

  def isValid?(pkmn)
    weight = (pkmn.is_a?(Pokemon)) ? pkmn.weight : GameData::Species.get(pkmn).weight
    return weight <= (@level * 10).round
  end

  def errorMessage(pkmn)
    weight = (pkmn.is_a?(Pokemon)) ? pkmn.weight : GameData::Species.get(pkmn).weight
    return [_INTL("{1} weighs {2}kg, heavier than the {3}kg maximum.", pkmn.name, weight / 10.0, @level)]
  end
end

# Unused - nothing in the codebase constructs this today. Was a "Negative/
# Extended Game" ban on Arceus and the Sinnoh elemental berries.
class NegativeExtendedGameClause
  def isValid?(pkmn)
    return false if pkmn.isSpecies?(:ARCEUS)
    return false if pkmn.hasItem?(:MICLEBERRY)
    return false if pkmn.hasItem?(:CUSTAPBERRY)
    return false if pkmn.hasItem?(:JABOCABERRY)
    return false if pkmn.hasItem?(:ROWAPBERRY)
  end

  def errorMessage(pkmn)
    errors = []
    errors << _INTL("{1} is Arceus, which isn't allowed.", pkmn.name) if pkmn.isSpecies?(:ARCEUS)
    [:MICLEBERRY, :CUSTAPBERRY, :JABOCABERRY, :ROWAPBERRY].each do |item|
      errors << _INTL("{1} is holding {2}, which isn't allowed.", pkmn.name, GameData::Item.get(item).name) if pkmn.hasItem?(item)
    end
    return errors
  end
end

$babySpeciesData = {}

# PokemonRules = BabyRestriction
# Only allows a species' baby form itself (e.g. Pichu, not Pikachu/Raichu).
class BabyRestriction
  def isValid?(pkmn)
    if !$babySpeciesData[pkmn.species]
      $babySpeciesData[pkmn.species] = pkmn.species_data.get_baby_species
    end
    return pkmn.species == $babySpeciesData[pkmn.species]
  end

  def errorMessage(pkmn)
    return [_INTL("{1} isn't {2}'s baby form, which isn't allowed.", pkmn.name, pkmn.species_data.name)]
  end
end

$canEvolve = {}

# PokemonRules = UnevolvedFormRestriction
# Only allows a baby species that hasn't evolved yet but still can (so e.g.
# Pichu passes, but Pikachu/Raichu and baby-less, already-final-form species
# like Tauros don't).
class UnevolvedFormRestriction
  def isValid?(pkmn)
    if !$babySpeciesData[pkmn.species]
      $babySpeciesData[pkmn.species] = pkmn.species_data.get_baby_species
    end
    return false if pkmn.species != $babySpeciesData[pkmn.species]
    if $canEvolve[pkmn.species].nil?
      $canEvolve[pkmn.species] = (pkmn.species_data.get_evolutions.length > 0)
    end
    return $canEvolve[pkmn.species]
  end

  def errorMessage(pkmn)
    if pkmn.species != $babySpeciesData[pkmn.species]
      return [_INTL("{1} isn't an evolvable baby-form Pokémon.", pkmn.name)]
    end
    return [_INTL("{1}'s species has no further evolutions to grow into.", pkmn.name)]
  end
end

# PokemonRules = NonEggRestriction
# Bans eggs. Used by Cable Club's own Free For All presets.
class NonEggRestriction
  def isValid?(pkmn)
    return pkmn && !pkmn.egg?
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is an egg, which isn't allowed.", pkmn.name)]
  end
end

# PokemonRules = AblePokemonRestriction
# Bans Pokemon that can't battle (fainted, or otherwise unable per any
# ability flagged "UnableByDefault", e.g. an egg).
class AblePokemonRestriction
  def isValid?(pkmn)
    return pkmn && pkmn.able?(false, GameData::Ability.getByFlag("UnableByDefault"))
  end

  def errorMessage(pkmn)
    return [_INTL("{1} isn't able to battle.", pkmn.name)]
  end
end

# PokemonRules = SpeciesRestriction,species1,species2,...
# Only allows the listed species (an allow-list) - anything else is banned.
class SpeciesRestriction
  def initialize(*specieslist)
    @specieslist = specieslist.clone
  end

  def isSpecies?(species, specieslist)
    return specieslist.include?(species)
  end

  def isValid?(pkmn)
    return isSpecies?(pkmn.species, @specieslist)
  end

  def errorMessage(pkmn)
    return [_INTL("{1} ({2}) isn't one of the allowed species.", pkmn.name, pkmn.species_data.name)]
  end
end

# PokemonRules = BannedSpeciesRestriction,species1,species2,...
# Bans the listed species (a deny-list); anything not listed is allowed.
class BannedSpeciesRestriction
  def initialize(*specieslist)
    @specieslist = specieslist.clone
  end

  def isSpecies?(species, specieslist)
    return specieslist.include?(species)
  end

  def isValid?(pkmn)
    return !isSpecies?(pkmn.species, @specieslist)
  end

  def errorMessage(pkmn)
    return [_INTL("{1}'s species ({2}) isn't allowed.", pkmn.name, pkmn.species_data.name)]
  end
end

# PokemonRules = MinimumLevelRestriction,minLevel
# Bans any Pokemon below the given level.
class MinimumLevelRestriction
  attr_reader :level

  def initialize(minLevel)
    @level = minLevel
  end

  def isValid?(pkmn)
    return pkmn.level >= @level
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is level {2}, below the minimum of {3}.", pkmn.name, pkmn.level, @level)]
  end
end

# PokemonRules = MaximumLevelRestriction,maxLevel
# Bans any Pokemon above the given level.
class MaximumLevelRestriction
  attr_reader :level

  def initialize(maxLevel)
    @level = maxLevel
  end

  def isValid?(pkmn)
    return pkmn.level <= @level
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is level {2}, above the maximum of {3}.", pkmn.name, pkmn.level, @level)]
  end
end

# PokemonRules = BannedItemRestriction,item1,item2,...
# Bans any Pokemon holding one of the listed items.
class BannedItemRestriction
  def initialize(*itemlist)
    @itemlist = itemlist.clone
  end

  def isSpecies?(item,itemlist)
    return itemlist.include?(item)
  end

  def isValid?(pkmn)
    return !pkmn.firstItem || !isSpecies?(pkmn.firstItem, @itemlist)
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is holding {2}, which isn't allowed.", pkmn.name, GameData::Item.get(pkmn.firstItem).name)]
  end
end

# PokemonRules = ItemsDisallowedClause
# Bans holding any item at all.
class ItemsDisallowedClause
  def isValid?(pkmn)
    return !pkmn.hasItem?
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is holding {2}, but holding items isn't allowed.", pkmn.name, GameData::Item.get(pkmn.firstItem).name)]
  end
end

# PokemonRules = SoulDewClause
# Bans holding a Soul Dew specifically.
class SoulDewClause
  def isValid?(pkmn)
    return !pkmn.hasItem?(:SOULDEW)
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is holding a Soul Dew, which isn't allowed.", pkmn.name)]
  end
end

# PokemonRules = BannedMoveRestriction,move1,move2,...
# Bans any Pokemon that knows one of the listed moves.
class BannedMoveRestriction
  def initialize(*movelist)
    @movelist = movelist.clone
  end

  def isValid?(pkmn)
    return pkmn.moves.none? { |m| @movelist.include?(m.id) }
  end

  def errorMessage(pkmn)
    banned = pkmn.moves.select { |m| @movelist.include?(m.id) }
    return banned.map { |m| _INTL("{1} knows {2}, which isn't allowed.", pkmn.name, GameData::Move.get(m.id).name) }
  end
end

# PokemonRules = PrimevalMoveRestriction
# Bans any Pokemon that knows a Primeval (empowered/Delta) move.
class PrimevalMoveRestriction
  def isValid?(pkmn)
    return pkmn.moves.none? { |m| GameData::Move.get(m.id).empoweredMove? }
  end

  def errorMessage(pkmn)
    primeval = pkmn.moves.select { |m| GameData::Move.get(m.id).empoweredMove? }
    return primeval.map { |m| _INTL("{1} knows {2}, a Primeval move, which isn't allowed.", pkmn.name, GameData::Move.get(m.id).name) }
  end
end

# PokemonRules = LittleCupRestriction
# Bans a few items/moves/species that would otherwise undermine a Little
# Cup-style baby-Pokemon format: Berry Juice, Deep Sea Tooth, Sonic Boom,
# Dragon Rage, and species whose evolution doesn't depend on level (so it
# can't be capped by a level restriction alone).
class LittleCupRestriction
  BANNED_SPECIES = [:SCYTHER, :SNEASEL, :MEDITITE, :YANMA, :TANGELA, :MURKROW]

  def isValid?(pkmn)
    return false if pkmn.hasItem?(:BERRYJUICE)
    return false if pkmn.hasItem?(:DEEPSEATOOTH)
    return false if pkmn.hasMove?(:SONICBOOM)
    return false if pkmn.hasMove?(:DRAGONRAGE)
    return false if BANNED_SPECIES.any? { |s| pkmn.isSpecies?(s) }
    return true
  end

  def errorMessage(pkmn)
    errors = []
    errors << _INTL("{1} is holding a Berry Juice, which isn't allowed in Little Cup.", pkmn.name) if pkmn.hasItem?(:BERRYJUICE)
    errors << _INTL("{1} is holding a Deep Sea Tooth, which isn't allowed in Little Cup.", pkmn.name) if pkmn.hasItem?(:DEEPSEATOOTH)
    errors << _INTL("{1} knows {2}, which isn't allowed in Little Cup.", pkmn.name, GameData::Move.get(:SONICBOOM).name) if pkmn.hasMove?(:SONICBOOM)
    errors << _INTL("{1} knows {2}, which isn't allowed in Little Cup.", pkmn.name, GameData::Move.get(:DRAGONRAGE).name) if pkmn.hasMove?(:DRAGONRAGE)
    errors << _INTL("{1}'s species isn't allowed in Little Cup.", pkmn.name) if BANNED_SPECIES.any? { |s| pkmn.isSpecies?(s) }
    return errors
  end
end
