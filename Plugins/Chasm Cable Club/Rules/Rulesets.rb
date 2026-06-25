# Holds the PokemonRules clause list (PokemonRules.rb) and the TeamRules/
# SubsetRules clause lists (TeamRules.rb) for one ruleset, plus its PartySize
# range. Not referenced by name from a
# .rules file itself - PokemonOnlineRules (007_CableClub_Rules.rb) owns one
# of these and drives it from the file's other keys: PartySize maps to
# setNumberRange, and each PokemonRules/TeamRules/SubsetRules line maps to
# addPokemonRule/addTeamRule/addSubsetRule.
class PokemonRuleSet
  def initialize(number = 0)
    @pokemonRules = []
    @teamRules    = []
    @subsetRules  = []
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
    for rule in @subsetRules
      ret.addSubsetRule(rule)
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
    for rule in @subsetRules
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

  # This rule checks either:
  # - the entire team to determine whether a subset of the team meets the rule, or
  # - whether the entire team meets the rule. If the condition holds for the
  #   entire team, the condition must also hold for any possible subset of the
  #   team with the suggested number.
  # Examples of team rules:
  # - No two Pokemon can be the same species.
  # - No two Pokemon can hold the same items.
  def addTeamRule(rule)
    @teamRules.push(rule)
    return self
  end

  # This rule checks:
  # - the entire team to determine whether a subset of the team meets the rule, or
  # - a list of Pokemon whose length is equal to the suggested number. For an
  #   entire team, the condition must hold for at least one possible subset of
  #   the team, but not necessarily for the entire team.
  # A subset rule is "number-dependent", that is, whether the condition is likely
  # to hold depends on the number of Pokemon in the subset.
  # Example of a subset rule:
  # - The combined level of X Pokemon can't exceed Y.
  def addSubsetRule(rule)
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

  def clearSubsetRules
    @subsetRules.clear
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

  def hasRegistrableTeam?(list)
    return false if !list || list.length < self.minTeamLength
    (self.minTeamLength..self.maxTeamLength).each do |x|
      pbEachCombination(list, x) { |comb|
        return true if canRegisterTeam?(comb)
      }
    end
    return false
  end

  # Returns true if the team's length is greater or equal to the suggested
  # number and is Settings::MAX_PARTY_SIZE or less, the team as a whole meets
  # the requirements of any team rules, and at least one subset of the team
  # meets the requirements of any subset rules. Each Pokemon in the team must be
  # valid.
  def canRegisterTeam?(team)
    return false if !team || team.length < self.minTeamLength
    return false if team.length > self.maxTeamLength
    teamNumber = [self.maxLength, team.length].min
    for pkmn in team
      return false if !isPokemonValid?(pkmn)
    end
    for rule in @teamRules
      return false if !rule.isValid?(team)
    end
    if @subsetRules.length > 0
      pbEachCombination(team, teamNumber) { |comb|
        isValid = true
        for rule in @subsetRules
          next if rule.isValid?(comb)
          isValid = false
          break
        end
        return true if isValid
      }
      return false
    end
    return true
  end

  # Returns true if the team's length is greater or equal to the suggested
  # number and at least one subset of the team meets the requirements of any
  # team rules and subset rules. Not all Pokemon in the team have to be valid.
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

  # Returns true if the team's length meets the subset length range requirements
  # and the team meets the requirements of any team rules and subset rules. Each
  # Pokemon in the team must be valid.
  def isValid?(team, error = nil)
    if team.length < self.minLength
      error.push(_INTL("Choose a Pokémon.")) if error && self.minLength == 1
      error.push(_INTL("{1} Pokémon are needed.", self.minLength)) if error && self.minLength > 1
      return false
    elsif team.length > self.maxLength
      error.push(_INTL("No more than {1} Pokémon may enter.", self.maxLength)) if error
      return false
    end
    for pkmn in team
      next if isPokemonValid?(pkmn)
      if pkmn
        error.push(_INTL("{1} is not allowed.", pkmn.name)) if error
      else
        error.push(_INTL("This team is not allowed.")) if error
      end
      return false
    end
    for rule in @teamRules
      next if rule.isValid?(team)
      error.push(rule.errorMessage) if error
      return false
    end
    for rule in @subsetRules
      next if rule.isValid?(team)
      error.push(rule.errorMessage) if error
      return false
    end
    return true
  end
end
