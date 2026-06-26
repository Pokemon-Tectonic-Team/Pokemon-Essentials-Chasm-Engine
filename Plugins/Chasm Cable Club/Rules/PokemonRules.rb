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
#
# Every class below also declares self.builder_name/self.builder_desc/
# self.builder_args, describing it for the in-game ruleset builder
# (009_CableClub_RulesetBuilder.rb): a display name, a one-line description
# shown while picking it, and its constructor's argument list in order.
# Each arg is [:type, label]; :int/:level are whole numbers (the latter
# clamped to 1..GameData::GrowthRate.max_level), :tenths is a decimal
# entered as tenths and divided by 10 before being passed to .new (matching
# HeightRestriction/WeightRestriction's own internal convention), and
# :species_list/:item_list/:move_list are picked via the Debug menu's
# species/item/move pickers, looped to build up a list. Extending
# PokemonRuleMetadata registers the class into POKEMON_RULE_CLASSES
# automatically, so that list never needs to be maintained by hand.

# Classes extend this to automatically register themselves into
# POKEMON_RULE_CLASSES - see the file header above.
module PokemonRuleMetadata
  def self.extended(base)
    POKEMON_RULE_CLASSES.push(base)
  end
end

POKEMON_RULE_CLASSES = []

# PokemonRules = NoLegendaryRestriction
# Bans any species flagged as legendary. Eggs are already banned
# unconditionally by PokemonRuleSet#isPokemonValid? (Rulesets.rb), so this
# doesn't need to check for them itself.
class NoLegendaryRestriction
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("No Legendaries"); end
  def self.builder_desc; _INTL("Bans legendary Pokémon."); end
  def self.builder_args; []; end

  def isValid?(pkmn)
    return false if !pkmn
    return !pkmn.species_data.isLegendary?
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is a legendary Pokémon, which isn't allowed.", pkmn.name)]
  end
end

# PokemonRules = HeightRestriction,maxHeightInMeters
# Bans any Pokemon taller than the given height, in meters.
class HeightRestriction
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("Height Limit"); end
  def self.builder_desc; _INTL("Bans Pokémon taller than a given height."); end
  def self.builder_args; [[:tenths, _INTL("Max height (m)")]]; end

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
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("Weight Limit"); end
  def self.builder_desc; _INTL("Bans Pokémon heavier than a given weight."); end
  def self.builder_args; [[:tenths, _INTL("Max weight (kg)")]]; end

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

$babySpeciesData = {}

# PokemonRules = BabyRestriction
# Only allows a species' baby form itself (e.g. Pichu, not Pikachu/Raichu).
class BabyRestriction
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("Baby Forms Only"); end
  def self.builder_desc; _INTL("Only allows baby-form Pokémon."); end
  def self.builder_args; []; end

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
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("Unevolved Forms Only"); end
  def self.builder_desc; _INTL("Only allows baby forms that can still evolve."); end
  def self.builder_args; []; end

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

# PokemonRules = SpeciesRestriction,species1,species2,...
# Only allows the listed species (an allow-list) - anything else is banned.
class SpeciesRestriction
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("Species Allow-List"); end
  def self.builder_desc; _INTL("Only allows the listed species."); end
  def self.builder_args; [[:species_list, _INTL("Allowed species")]]; end

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
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("Species Ban-List"); end
  def self.builder_desc; _INTL("Bans the listed species."); end
  def self.builder_args; [[:species_list, _INTL("Banned species")]]; end

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
  extend PokemonRuleMetadata
  attr_reader :level

  def self.builder_name; _INTL("Minimum Level"); end
  def self.builder_desc; _INTL("Bans Pokémon below a given level."); end
  def self.builder_args; [[:level, _INTL("Minimum level")]]; end

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
  extend PokemonRuleMetadata
  attr_reader :level

  def self.builder_name; _INTL("Maximum Level"); end
  def self.builder_desc; _INTL("Bans Pokémon above a given level."); end
  def self.builder_args; [[:level, _INTL("Maximum level")]]; end

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
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("Item Ban-List"); end
  def self.builder_desc; _INTL("Bans the listed held items."); end
  def self.builder_args; [[:item_list, _INTL("Banned items")]]; end

  def initialize(*itemlist)
    @itemlist = itemlist.clone
  end

  def isValid?(pkmn)
    return !pkmn.firstItem || !@itemlist.include?(pkmn.firstItem)
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is holding {2}, which isn't allowed.", pkmn.name, GameData::Item.get(pkmn.firstItem).name)]
  end
end

# PokemonRules = ItemsDisallowedClause
# Bans holding any item at all.
class ItemsDisallowedClause
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("No Held Items"); end
  def self.builder_desc; _INTL("Bans holding any item at all."); end
  def self.builder_args; []; end

  def isValid?(pkmn)
    return !pkmn.hasItem?
  end

  def errorMessage(pkmn)
    return [_INTL("{1} is holding {2}, but holding items isn't allowed.", pkmn.name, GameData::Item.get(pkmn.firstItem).name)]
  end
end

# PokemonRules = BannedMoveRestriction,move1,move2,...
# Bans any Pokemon that knows one of the listed moves.
class BannedMoveRestriction
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("Move Ban-List"); end
  def self.builder_desc; _INTL("Bans the listed moves."); end
  def self.builder_args; [[:move_list, _INTL("Banned moves")]]; end

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
# Bans any Pokemon that knows a Primeval (incl. empowered) move.
class PrimevalMoveRestriction
  extend PokemonRuleMetadata

  def self.builder_name; _INTL("No Primeval Moves"); end
  def self.builder_desc; _INTL("Bans Primeval and Empowered moves."); end
  def self.builder_args; []; end

  def isValid?(pkmn)
    return pkmn.moves.none? { |m| GameData::Move.get(m.id).empoweredMove? }
  end

  def errorMessage(pkmn)
    primeval = pkmn.moves.select { |m| GameData::Move.get(m.id).empoweredMove? }
    return primeval.map { |m| _INTL("{1} knows {2}, a Primeval move, which isn't allowed.", pkmn.name, GameData::Move.get(m.id).name) }
  end
end
