# These adjust only one side (the enemy/Frontier trainer) rather than both
# players equally, so they only make sense for Battle Frontier's
# player-vs-trainer challenges - see Cable Club's Rules/LevelAdjustments.rb
# for why they're not usable from a Cable Club .rules file.

# Only adjusts the enemy team. Starts every enemy Pokemon at minLevel, then
# raises them one at a time (looping over the team) up to maxLevel each,
# stopping once their combined level would exceed totalLevel. Set via
# PokemonChallengeRules#addLevelRule(minLevel, maxLevel, totalLevel).
class TotalLevelAdjustment < LevelAdjustment
  def initialize(minLevel, maxLevel, totalLevel)
    super(LevelAdjustment::EnemyTeam)
    @minLevel = minLevel.clamp(1, GameData::GrowthRate.max_level)
    @maxLevel = maxLevel.clamp(1, GameData::GrowthRate.max_level)
    @totalLevel = totalLevel
  end

  def getAdjustment(thisTeam, _otherTeam)
    ret = []
    total = 0
    thisTeam.each_with_index do |pkmn, i|
      ret[i] = @minLevel
      total += @minLevel
    end
    loop do
      work = false
      thisTeam.each_with_index do |pkmn, i|
        next if ret[i] >= @maxLevel || total >= @totalLevel
        ret[i] += 1
        total += 1
        work = true
      end
      break if !work
    end
    return ret
  end
end

# Sets every Pokemon on the enemy team to exactly the given level. The
# player's own team is left alone, unlike FixedLevelAdjustment.
class EnemyLevelAdjustment < LevelAdjustment
  def initialize(level)
    super(LevelAdjustment::EnemyTeam)
    @level = level.clamp(1, GameData::GrowthRate.max_level)
  end

  def getAdjustment(thisTeam, _otherTeam)
    ret = []
    thisTeam.each_with_index { |pkmn, i| ret[i] = @level }
    return ret
  end
end

# Sets every Pokemon on the enemy team to match the player's highest-level
# Pokemon (or minLevel, whichever is higher; minLevel defaults to 1). The
# player's own team is left alone.
class OpenLevelAdjustment < LevelAdjustment
  def initialize(minLevel = 1)
    super(LevelAdjustment::EnemyTeam)
    @minLevel = minLevel
  end

  def getAdjustment(thisTeam, otherTeam)
    maxLevel = 1
    otherTeam.each do |pkmn|
      level = pkmn.level
      maxLevel = level if maxLevel < level
    end
    maxLevel = @minLevel if maxLevel < @minLevel
    ret = []
    thisTeam.each_with_index { |pkmn, i| ret[i] = maxLevel }
    return ret
  end
end

# Applies one LevelAdjustment to "my" team and a different one to "their"
# team. Takes other LevelAdjustment instances (not plain values), so it can't
# be written directly as a .rules clause - it's a building block for
# composing asymmetric presets in code instead (see
# SinglePlayerCappedLevelAdjustment below for an example). Nothing currently
# constructs this, but it's kept as a reusable primitive for future
# Frontier-style challenge presets that need different rules per side.
class CombinedLevelAdjustment < LevelAdjustment
  def initialize(my, their)
    super(LevelAdjustment::BothTeamsDifferent)
    @my    = my
    @their = their
  end

  def getMyAdjustment(myTeam,theirTeam)
    return @my.getAdjustment(myTeam, theirTeam) if @my
    return LevelAdjustment.getNullAdjustment(myTeam, theirTeam)
  end

  def getTheirAdjustment(theirTeam,myTeam)
    return @their.getAdjustment(theirTeam, myTeam) if @their
    return LevelAdjustment.getNullAdjustment(theirTeam, myTeam)
  end
end

# Caps the player's own team at the given level (their actual level if lower)
# and fixes the enemy team to exactly that level. A CombinedLevelAdjustment
# preset for one-sided challenges where only the player's levels vary.
# Nothing currently constructs this either, kept for the same reason.
class SinglePlayerCappedLevelAdjustment < CombinedLevelAdjustment
  def initialize(level)
    super(CappedLevelAdjustment.new(level), FixedLevelAdjustment.new(level))
  end
end
