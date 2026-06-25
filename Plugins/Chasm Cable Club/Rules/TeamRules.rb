# Classes referenced by name from a .rules file's "TeamRules" or "SubsetRules"
# key, e.g. "TeamRules = SpeciesClause" or "SubsetRules = TotalLevelRestriction,80".
# Each is checked once against a list of Pokemon, via isValid?(team); see
# PokemonRules.rb for the separate per-Pokemon checks instead.
#
# Kept in one file rather than split by key, because the TeamRules/SubsetRules
# distinction probably shouldn't exist: PokemonRuleSet#addSubsetRule
# (Rulesets.rb) currently pushes into @teamRules instead of @subsetRules, so
# every "SubsetRules" entry has only ever been checked exactly like a
# TeamRules one (against the whole entered team) - the @subsetRules-checking
# branches in canRegisterTeam?/isValid? are dead code. Separately, even
# working as documented, a subset rule checked against every valid-size
# subset would already cover the full-team case whenever PartySize's min
# equals its max (no choice in how many to bring), which is the common case.
# Plan is to drop "TeamRules" as a distinct concept later and rename today's
# (currently non-functional) SubsetRules to take over the "TeamRules" name -
# not done yet, so the key names and behavior below are unchanged for now.

# Helper used by NicknameClause to track which nicknames are already in use
# and which species' real names they collide with.
module NicknameChecker
  @@names = {}

  def getName(species)
    n = @@names[species]
    return n if n
    n = GameData::Species.get(species).name
    @@names[species] = n.upcase
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
  def isValid?(team)
    for i in 0...team.length - 1
      for j in i + 1...team.length
        return false if team[i].name == team[j].name
        return false if !NicknameChecker.check(team[i].name, team[i].species)
      end
    end
    return true
  end

  def errorMessage
    return _INTL("Two Pokémon on this team can't share the same nickname.")
  end
end

# TeamRules/SubsetRules = RestrictedSpeciesRestriction,maxValue,species1,...
# Caps how many of the listed species can appear together at maxValue. See
# RestrictedSpeciesTeamRestriction/RestrictedSpeciesSubsetRestriction below
# for ready-made versions of this with a fixed cap.
class RestrictedSpeciesRestriction
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
end

# TeamRules/SubsetRules = RestrictedLegendsRestriction,maxValue
# Caps how many legendaries can appear together at maxValue. Used by Cable
# Club's own doubles.rules preset (as a TeamRules entry).
class RestrictedLegendsRestriction
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

  def errorMessage
    return _INTL("Sorry, you can only have {1} legendary on your team!", @maxValue)
  end
end

# TeamRules = RestrictedSpeciesTeamRestriction,species1,species2,...
# RestrictedSpeciesRestriction with the cap fixed at 4, for capping a listed
# group of species across the whole entered team.
class RestrictedSpeciesTeamRestriction < RestrictedSpeciesRestriction
  def initialize(*specieslist)
    super(4, *specieslist)
  end
end

# SubsetRules = RestrictedSpeciesSubsetRestriction,species1,species2,...
# RestrictedSpeciesRestriction with the cap fixed at 2, for capping a listed
# group of species across just the Pokemon chosen to battle with.
class RestrictedSpeciesSubsetRestriction < RestrictedSpeciesRestriction
  def initialize(*specieslist)
    super(2, *specieslist)
  end
end

# TeamRules = SameSpeciesClause
# Every Pokemon on the team must be the same species as each other (a
# monotype-species theme team).
class SameSpeciesClause
  def isValid?(team)
    species = []
    team.each do |pkmn|
      species.push(pkmn.species) if pkmn && !species.include?(pkmn.species)
    end
    return species.length == 1
  end

  def errorMessage
    return _INTL("Every Pokémon on this team must be the same species.")
  end
end

# TeamRules = SpeciesClause
# No two Pokemon on the team can be the same species as each other. This is
# the standard competitive "Species Clause".
class SpeciesClause
  def isValid?(team)
    species = []
    team.each do |pkmn|
      next if !pkmn
      return false if species.include?(pkmn.species)
      species.push(pkmn.species)
    end
    return true
  end

  def errorMessage
    return _INTL("Two Pokémon on this team can't be the same species.")
  end
end

# TeamRules = ItemClause
# No two Pokemon on the team can hold the same item as each other. This is
# the standard competitive "Item Clause".
class ItemClause
  def isValid?(team)
    items = []
    team.each do |pkmn|
      next if !pkmn || !pkmn.hasItem?
      return false if items.include?(pkmn.firstItem)
      items.push(pkmn.firstItem)
    end
    return true
  end

  def errorMessage
    return _INTL("Two Pokémon on this team can't hold the same item.")
  end
end

# SubsetRules = TotalLevelRestriction,level
# The combined level of every Pokemon entered can't exceed the given value.
class TotalLevelRestriction
  attr_reader :level

  def initialize(level)
    @level = level
  end

  def isValid?(team)
    totalLevel = 0
    team.each { |pkmn| totalLevel += pkmn.level if pkmn }
    return totalLevel <= @level
  end

  def errorMessage
    return _INTL("The combined level of these Pokémon can't exceed {1}.", @level)
  end
end
