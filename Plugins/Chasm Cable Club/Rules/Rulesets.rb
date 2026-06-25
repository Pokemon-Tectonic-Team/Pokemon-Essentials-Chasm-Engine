# Holds the PokemonRules clause list (PokemonRules.rb) and the TeamRules
# clause list (TeamRules.rb) for one ruleset, plus its PartySize range. Not
# referenced by name from a .rules file itself - PokemonOnlineRules
# (007_CableClub_Rules.rb) owns one of these and drives it from the file's
# other keys: PartySize maps to setNumberRange, and each PokemonRules/
# TeamRules line maps to addPokemonRule/addTeamRule.
class PokemonRuleSet
  def initialize(number = 0)
    @pokemonRules = []
    @teamRules    = []
    @minLength    = 1
    @number       = number
  end

  def copy
    ret = PokemonRuleSet.new(@number)
    for rule in @pokemonRules
      ret.addPokemonRule(rule)
    end
    for rule in @teamRules
      ret.addTeamRule(rule)
    end
    return ret
  end

  def minLength
    return (@minLength) ? @minLength : self.maxLength
  end

  def maxLength
    return (@number < 0) ? Settings::MAX_PARTY_SIZE : @number
  end
  alias number maxLength

  def minTeamLength
    return [1, self.minLength].max
  end

  def maxTeamLength
    return [Settings::MAX_PARTY_SIZE, self.maxLength].max
  end

  # Returns the length of a valid subset of a Pokemon team.
  def suggestedNumber
    return self.maxLength
  end

  # Returns a valid level to assign to each member of a valid Pokemon team.
  def suggestedLevel
    minLevel = 1
    maxLevel = GameData::GrowthRate.max_level
    num = self.suggestedNumber
    for rule in @pokemonRules
      if rule.is_a?(MinimumLevelRestriction)
        minLevel = rule.level
      elsif rule.is_a?(MaximumLevelRestriction)
        maxLevel = rule.level
      end
    end
    totalLevel = maxLevel * num
    for rule in @teamRules
      totalLevel = rule.level if rule.is_a?(TotalLevelRestriction)
    end
    return [maxLevel, minLevel].max if totalLevel >= maxLevel * num
    return [totalLevel / self.suggestedNumber, minLevel].max
  end

  def setNumberRange(minValue, maxValue)
    @minLength = [1, minValue].max
    @number = [1, maxValue].max
    return self
  end

  def setNumber(value)
    return setNumberRange(value, value)
  end

  # Checked via isValid?(team) against the entered team: passes if there's
  # at least one combination, sized anywhere from minTeamLength to
  # maxTeamLength, where every Pokemon is individually valid and every team
  # rule holds for that combination. When PartySize requires an exact size
  # (min == max), this is equivalent to just checking the whole team, since
  # the team itself is the only combination of that size.
  # Examples: no two Pokemon can be the same species; no two Pokemon can
  # hold the same item; the combined level of the team can't exceed X.
  def addTeamRule(rule)
    @teamRules.push(rule)
    return self
  end

  def addPokemonRule(rule)
    @pokemonRules.push(rule)
    return self
  end

  def clearTeamRules
    @teamRules.clear
    return self
  end

  def clearPokemonRules
    @pokemonRules.clear
    return self
  end

  def isPokemonValid?(pkmn)
    return false if !pkmn
    for rule in @pokemonRules
      return false if !rule.isValid?(pkmn)
    end
    return true
  end

  # Collects every PokemonRule pkmn fails, concatenating each one's
  # errorMessage(pkmn) (itself a list, since a single rule can have more
  # than one thing wrong - e.g. knowing two different banned moves), so a
  # rejected Pokemon's issues can all be shown at once instead of just the
  # first. Only meant to be called once isPokemonValid?(pkmn) has already
  # returned false.
  def pokemonInvalidReasons(pkmn)
    errors = []
    for rule in @pokemonRules
      errors.concat(rule.errorMessage(pkmn)) if !rule.isValid?(pkmn)
    end
    return errors.empty? ? [_INTL("{1} is not allowed.", pkmn.name)] : errors
  end

  # Returns true if some combination of [minTeamLength, maxTeamLength]
  # Pokemon from the list would satisfy isValid?.
  def hasRegistrableTeam?(list)
    return false if !list || list.length < self.minTeamLength
    (self.minTeamLength..self.maxTeamLength).each do |x|
      pbEachCombination(list, x) { |comb|
        return true if isValid?(comb)
      }
    end
    return false
  end

  # Returns true if the team's length is greater or equal to the suggested
  # number and at least one subset of the team meets the requirements of any
  # team rules. Not all Pokemon in the team have to be valid.
  def hasValidTeam?(team)
    return false if !team || team.length < self.minTeamLength
    validPokemon = []
    for pkmn in team
      validPokemon.push(pkmn) if isPokemonValid?(pkmn)
    end
    return false if validPokemon.length < self.minLength
    if @teamRules.length > 0
      (self.minTeamLength..self.maxTeamLength).each do |x|
        pbEachCombination(team, x) { |comb| return true if isValid?(comb) }
      end
      return false
    end
    return true
  end

  # Quick true/false check: does the team's length meet the PartySize range,
  # is every Pokemon in it individually valid, and does it meet every team
  # rule? Stops at the first thing wrong, same as before - use
  # validityErrors below if you need to know what (all) is wrong, not just
  # whether something is.
  def isValid?(team)
    return false if team.length < self.minLength
    return false if team.length > self.maxLength
    for pkmn in team
      return false if !isPokemonValid?(pkmn)
    end
    for rule in @teamRules
      return false if !rule.isValid?(team)
    end
    return true
  end

  # Exhaustively explains every reason this exact team is invalid - unlike
  # isValid?, this doesn't stop at the first problem, so a player fixing
  # their selection can see everything wrong with it at once instead of
  # hitting issues one at a time by trial and error. Empty if the team is
  # valid.
  def validityErrors(team)
    errors = []
    if team.length < self.minLength
      errors.push(_INTL("Choose a Pokémon.")) if self.minLength == 1
      errors.push(_INTL("{1} Pokémon are needed.", self.minLength)) if self.minLength > 1
    elsif team.length > self.maxLength
      errors.push(_INTL("No more than {1} Pokémon may enter.", self.maxLength))
    end
    for pkmn in team
      next if isPokemonValid?(pkmn)
      if pkmn
        errors.concat(pokemonInvalidReasons(pkmn))
      else
        errors.push(_INTL("This team is not allowed."))
      end
    end
    for rule in @teamRules
      errors.concat(rule.errorMessage(team)) if !rule.isValid?(team)
    end
    return errors
  end
end
