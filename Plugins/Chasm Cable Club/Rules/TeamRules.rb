# Classes referenced by name from a .rules file's "TeamRules" key, e.g.
# "TeamRules = SpeciesClause" or "TeamRules = TotalLevelRestriction,80". Each
# is checked via isValid?(team) against any combination, sized anywhere from
# minTeamLength to maxTeamLength, of the entered team (PokemonRuleSet#isValid?/
# hasRegistrableTeam?, Rulesets.rb) - passes if at least one such combination
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

# TeamRules = RestrictedSpeciesRestriction,maxValue,species1,...
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

# TeamRules = RestrictedLegendsRestriction,maxValue
# Caps how many legendaries can appear together at maxValue. Used by Cable
# Club's own doubles.rules preset.
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
# RestrictedSpeciesRestriction with the cap fixed at 4. The "Team" in the
# name is a leftover from the removed TeamRules/SubsetRules distinction -
# both this and RestrictedSpeciesSubsetRestriction below go under TeamRules
# now, and only differ in their preset cap (4 vs 2).
class RestrictedSpeciesTeamRestriction < RestrictedSpeciesRestriction
  def initialize(*specieslist)
    super(4, *specieslist)
  end
end

# TeamRules = RestrictedSpeciesSubsetRestriction,species1,species2,...
# RestrictedSpeciesRestriction with the cap fixed at 2. See
# RestrictedSpeciesTeamRestriction above re: the "Subset" in the name.
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

# TeamRules = TotalLevelRestriction,level
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
