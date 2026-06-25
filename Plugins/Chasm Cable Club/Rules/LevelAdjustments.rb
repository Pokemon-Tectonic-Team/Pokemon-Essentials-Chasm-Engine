# Base class for the "LevelAdjustment" key in a .rules file, e.g.
# "LevelAdjustment = FixedLevelAdjustment,70". Applied once at battle start to
# temporarily override both trainers' Pokemon levels identically (restored
# afterwards), so a ruleset can host battles at a level its participants
# don't actually have. Not meant to be referenced directly in a .rules file -
# use one of the concrete subclasses below instead.
#
# Cable Club is always a fair PvP battle between two real trainers - there's
# no fixed "enemy" side, both players see the other as the enemy, and
# adjusting one side differently from the other would be unfair. So unlike
# Battle Frontier's asymmetric, enemy-only version of this class (see
# Rules/LevelAdjustments.rb there), this one has no concept of which side to
# apply to - getAdjustment is always applied to both teams the same way.
class LevelAdjustment
  def self.getNullAdjustment(thisTeam, _otherTeam)
    ret = []
    thisTeam.each_with_index { |pkmn, i| ret[i] = pkmn.level }
    return ret
  end

  def getAdjustment(thisTeam, otherTeam)
    return self.getNullAdjustment(thisTeam, otherTeam)
  end

  def getOldExp(team1, _team2)
    ret = []
    team1.each_with_index { |pkmn, i| ret[i] = pkmn.exp }
    return ret
  end

  def unadjustLevels(team1, team2, adjustments)
    team1.each_with_index do |pkmn, i|
      next if !adjustments[0][i] || pkmn.exp == adjustments[0][i]
      pkmn.exp = adjustments[0][i]
      pkmn.calc_stats
    end
    team2.each_with_index do |pkmn, i|
      next if !adjustments[1][i] || pkmn.exp == adjustments[1][i]
      pkmn.exp = adjustments[1][i]
      pkmn.calc_stats
    end
  end

  def adjustLevels(team1, team2)
    ret = [getOldExp(team1, team2), getOldExp(team2, team1)]
    adj1 = getAdjustment(team1, team2)
    adj2 = getAdjustment(team2, team1)
    team1.each_with_index do |pkmn, i|
      next if pkmn.level == adj1[i]
      pkmn.level = adj1[i]
      pkmn.calc_stats
    end
    team2.each_with_index do |pkmn, i|
      next if pkmn.level == adj2[i]
      pkmn.level = adj2[i]
      pkmn.calc_stats
    end
    return ret
  end
end

# LevelAdjustment = FixedLevelAdjustment,70
# Sets every Pokemon on both teams to exactly the given level.
class FixedLevelAdjustment < LevelAdjustment
  def initialize(level)
    @level = level.clamp(1, GameData::GrowthRate.max_level)
  end

  def getAdjustment(thisTeam, _otherTeam)
    ret = []
    thisTeam.each_with_index { |pkmn, i| ret[i] = @level }
    return ret
  end
end

# LevelAdjustment = CappedLevelAdjustment,50
# Lowers any Pokemon on either team above the given level down to it; leaves
# Pokemon already at or below it untouched.
class CappedLevelAdjustment < LevelAdjustment
  def initialize(level)
    @level = level.clamp(1, GameData::GrowthRate.max_level)
  end

  def getAdjustment(thisTeam, _otherTeam)
    ret = []
    thisTeam.each_with_index { |pkmn, i| ret[i] = [pkmn.level, @level].min }
    return ret
  end
end

# LevelAdjustment = LevelBalanceAdjustment
# Scales each Pokemon's level inversely with its base stat total, so a
# weaker species gets a level boost and a stronger one gets a level
# handicap - evening out matchups based on species choice alone rather than
# real EXP/training. Anchored to the weakest and strongest base stat totals
# found across every species in this game's PBS data (195 and 720): the
# weakest gets the level cap, the strongest gets LEVEL_SPREAD below it, and
# everything else is linearly interpolated (and clamped) between the two.
class LevelBalanceAdjustment < LevelAdjustment
  WEAKEST_BST   = 195
  STRONGEST_BST = 720
  LEVEL_SPREAD  = 30

  def getAdjustment(thisTeam, _otherTeam)
    maxLevel = GameData::GrowthRate.max_level
    minLevel = maxLevel - LEVEL_SPREAD
    slope = LEVEL_SPREAD.to_f / (STRONGEST_BST - WEAKEST_BST)
    ret = []
    thisTeam.each_with_index do |pkmn, i|
      bst = 0
      pkmn.baseStats.each_value { |s| bst += s }
      ret[i] = (maxLevel - (bst - WEAKEST_BST) * slope).round.clamp(minLevel, maxLevel)
    end
    return ret
  end
end
