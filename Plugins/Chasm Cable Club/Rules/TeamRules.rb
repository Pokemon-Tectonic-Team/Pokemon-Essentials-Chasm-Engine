# Classes referenced by name from a .rules file's "TeamRules" key, e.g.
# "TeamRules = SpeciesClause" or "TeamRules = TotalLevelRestriction,80". Each
# is checked via isValid?(team) against any combination, sized anywhere from
# minTeamLength to maxTeamLength, of the entered team (PokemonRuleSet#isValid?/
# hasValidTeam?, Rulesets.rb) - passes if at least one such combination
# satisfies every TeamRules entry. See PokemonRules.rb for the separate
# per-Pokemon checks instead.
#
# There used to be a separate "SubsetRules" key with its own (never actually
# working - see git history) semantics for "must hold for some subset, not
# necessarily the whole team." That distinction was removed: it never had a
# working implementation to begin with, and is redundant anyway whenever
# PartySize's min equals its max (the common case), since the team itself is
# then the only combination of the right size. "TeamRules" now means what
# "SubsetRules" was always meant to.
#
# errorMessage takes the same team isValid? was just called with (the one it
# failed on), and returns an Array of every distinct violation of that rule
# within the team (e.g. one entry per duplicate-item pair, not just the
# first) - PokemonRuleSet#validityErrors concatenates these across every
# failing rule so a player can see everything wrong with their team at once.
#
# Every class below also declares self.builder_name/self.builder_desc/
# self.builder_args for the in-game ruleset builder
# (009_CableClub_RulesetBuilder.rb) - see PokemonRules.rb's header comment
# for what these mean. Extending TeamRuleMetadata registers the class into
# TEAM_RULE_CLASSES automatically, so that list never needs to be maintained
# by hand.

# Classes extend this to automatically register themselves into
# TEAM_RULE_CLASSES - see the file header above.
module TeamRuleMetadata
  def self.extended(base)
    TEAM_RULE_CLASSES.push(base)
  end
end

TEAM_RULE_CLASSES = []

# Helper used by NicknameClause to track which nicknames are already in use
# and which species' real names they collide with. NicknameClause calls
# these directly on the module (NicknameChecker.check(...)), so extend self
# is required - without it these would only be usable as instance methods
# on something that includes this module, and the module-level calls below
# would raise NoMethodError.
module NicknameChecker
  extend self

  @@names = {}

  def getName(species)
    n = @@names[species]
    return n if n
    n = GameData::Species.get(species).name.upcase
    @@names[species] = n
    return n
  end

  def check(name, species)
    name = name.upcase
    return true if name == getName(species)
    return false if @@names.values.include?(name)
    GameData::Species.each do |species_data|
      next if species_data.species == species || species_data.form != 0
      return false if getName(species_data.id) == name
    end
    return true
  end
end

# TeamRules = NicknameClause
# No two Pokemon on the team can have the same nickname, and no nickname can
# match the (real) species name of another Pokemon on the team.
class NicknameClause
  extend TeamRuleMetadata

  def self.builder_name; _INTL("Nickname Clause"); end
  def self.builder_desc; _INTL("No two Pokémon may share a nickname or another's species name."); end
  def self.builder_args; []; end

  def isValid?(team)
    team.each do |pkmn|
      return false if !NicknameChecker.check(pkmn.name, pkmn.species)
    end
    for i in 0...team.length - 1
      for j in i + 1...team.length
        return false if team[i].name == team[j].name
      end
    end
    return true
  end

  def errorMessage(team)
    errors = []
    team.each do |pkmn|
      next if NicknameChecker.check(pkmn.name, pkmn.species)
      errors << _INTL("{1}'s nickname can't match another Pokémon's species name.", pkmn.name)
    end
    for i in 0...team.length - 1
      for j in i + 1...team.length
        next if team[i].name != team[j].name
        errors << _INTL("{1} and {2} can't have the same nickname.", team[i].name, team[j].name)
      end
    end
    return errors
  end
end

# TeamRules = RestrictedSpeciesRestriction,maxValue,species1,...
# Caps how many of the listed species can appear together at maxValue.
class RestrictedSpeciesRestriction
  extend TeamRuleMetadata

  def self.builder_name; _INTL("Restricted Species Count"); end
  def self.builder_desc; _INTL("Caps how many of the listed species may appear together."); end
  def self.builder_args; [[:int, _INTL("Max allowed")], [:species_list, _INTL("Restricted species")]]; end

  def initialize(maxValue, *specieslist)
    @specieslist = specieslist.clone
    @maxValue = maxValue
  end

  def isSpecies?(species, specieslist)
    return specieslist.include?(species)
  end

  def isValid?(team)
    count = 0
    team.each do |pkmn|
      count += 1 if pkmn && isSpecies?(pkmn.species, @specieslist)
    end
    return count <= @maxValue
  end

  def errorMessage(team)
    offenders = team.select { |pkmn| pkmn && isSpecies?(pkmn.species, @specieslist) }.map(&:name)
    return [_INTL("Only {1} of these Pokémon may be on your team: {2}", @maxValue, offenders.join(", "))]
  end
end

# TeamRules = RestrictedLegendsRestriction,maxValue
# Caps how many legendaries can appear together at maxValue. Used by Cable
# Club's own doubles.rules preset.
class RestrictedLegendsRestriction
  extend TeamRuleMetadata

  def self.builder_name; _INTL("Restricted Legend Count"); end
  def self.builder_desc; _INTL("Caps how many legendaries may appear together."); end
  def self.builder_args; [[:int, _INTL("Max allowed")]]; end

  def initialize(maxValue)
    @maxValue = maxValue
  end

  def isValid?(team)
    count = 0
    team.each do |pkmn|
      count += 1 if pkmn && pkmn.species_data.isLegendary?
    end
    return count <= @maxValue
  end

  def errorMessage(team)
    offenders = team.select { |pkmn| pkmn && pkmn.species_data.isLegendary? }.map(&:name)
    return [_INTL("Sorry, you can only have {1} legendary on your team! You have: {2}", @maxValue, offenders.join(", "))]
  end
end

# TeamRules = SameSpeciesClause
# Every Pokemon on the team must be the same species as each other (a
# monotype-species theme team).
class SameSpeciesClause
  extend TeamRuleMetadata

  def self.builder_name; _INTL("Same Species Clause"); end
  def self.builder_desc; _INTL("Every Pokémon on the team must be the same species."); end
  def self.builder_args; []; end

  def isValid?(team)
    species = []
    team.each do |pkmn|
      species.push(pkmn.species) if pkmn && !species.include?(pkmn.species)
    end
    return species.length == 1
  end

  def errorMessage(team)
    present = team.select { |pkmn| pkmn }
    return [] if present.empty?
    first = present[0]
    outliers = present.select { |pkmn| pkmn.species != first.species }
    return outliers.map { |pkmn| _INTL("{1} must be the same species as {2}.", pkmn.name, first.name) }
  end
end

# TeamRules = SpeciesClause
# No two Pokemon on the team can be the same species as each other. This is
# the standard competitive "Species Clause".
class SpeciesClause
  extend TeamRuleMetadata

  def self.builder_name; _INTL("Species Clause"); end
  def self.builder_desc; _INTL("No two Pokémon on the team may be the same species."); end
  def self.builder_args; []; end

  def isValid?(team)
    species = []
    team.each do |pkmn|
      next if !pkmn
      return false if species.include?(pkmn.species)
      species.push(pkmn.species)
    end
    return true
  end

  def errorMessage(team)
    errors = []
    seen = {}
    team.each do |pkmn|
      next if !pkmn
      if seen[pkmn.species]
        errors << _INTL("{1} and {2} can't both be {3}.", seen[pkmn.species].name, pkmn.name, pkmn.species_data.name)
      else
        seen[pkmn.species] = pkmn
      end
    end
    return errors
  end
end

# TeamRules = ItemClause
# No two Pokemon on the team can hold the same item as each other. This is
# the standard competitive "Item Clause".
class ItemClause
  extend TeamRuleMetadata

  def self.builder_name; _INTL("Item Clause"); end
  def self.builder_desc; _INTL("No two Pokémon on the team may hold the same item."); end
  def self.builder_args; []; end

  def isValid?(team)
    items = []
    team.each do |pkmn|
      next if !pkmn || !pkmn.hasItem?
      return false if items.include?(pkmn.firstItem)
      items.push(pkmn.firstItem)
    end
    return true
  end

  def errorMessage(team)
    errors = []
    seen = {}
    team.each do |pkmn|
      next if !pkmn || !pkmn.hasItem?
      if seen[pkmn.firstItem]
        errors << _INTL("{1} and {2} can't both hold {3}.", seen[pkmn.firstItem].name, pkmn.name, GameData::Item.get(pkmn.firstItem).name)
      else
        seen[pkmn.firstItem] = pkmn
      end
    end
    return errors
  end
end

# TeamRules = TotalLevelRestriction,level
# The combined level of every Pokemon entered can't exceed the given value.
class TotalLevelRestriction
  extend TeamRuleMetadata
  attr_reader :level

  def self.builder_name; _INTL("Total Level Cap"); end
  def self.builder_desc; _INTL("Caps the team's combined level."); end
  def self.builder_args; [[:int, _INTL("Max total level")]]; end

  def initialize(level)
    @level = level
  end

  def isValid?(team)
    totalLevel = 0
    team.each { |pkmn| totalLevel += pkmn.level if pkmn }
    return totalLevel <= @level
  end

  def errorMessage(team)
    totalLevel = 0
    team.each { |pkmn| totalLevel += pkmn.level if pkmn }
    return [_INTL("The combined level of these Pokémon ({1}) exceeds {2}.", totalLevel, @level)]
  end
end
