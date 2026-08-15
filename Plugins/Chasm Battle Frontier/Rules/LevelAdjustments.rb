# Adjusts only the enemy/Frontier trainer's team for a challenge; the
# player's own team is always left exactly as-is. See Cable Club's
# Rules/LevelAdjustments.rb for why its plain, always-symmetric
# LevelAdjustment doesn't fit these player-vs-trainer challenges - this is
# Battle Frontier's own asymmetric extension of that shared base class.
class EnemyTeamLevelAdjustment < LevelAdjustment
  def adjustLevels(playerTeam, enemyTeam)
    ret = [getOldExp(playerTeam, enemyTeam), getOldExp(enemyTeam, playerTeam)]
    adj = getAdjustment(enemyTeam, playerTeam)
    enemyTeam.each_with_index do |pkmn, i|
      next if pkmn.level == adj[i]
      pkmn.level = adj[i]
      pkmn.calc_stats
    end
    return ret
  end
end

# Only adjusts the enemy team. Starts every enemy Pokemon at minLevel, then
# raises them one at a time (looping over the team) up to maxLevel each,
# stopping once their combined level would exceed totalLevel. Set via
# PokemonChallengeRules#addLevelRule(minLevel, maxLevel, totalLevel).
class TotalLevelAdjustment < EnemyTeamLevelAdjustment
  def initialize(minLevel, maxLevel, totalLevel)
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
class EnemyLevelAdjustment < EnemyTeamLevelAdjustment
  def initialize(level)
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
class OpenLevelAdjustment < EnemyTeamLevelAdjustment
  def initialize(minLevel = 1)
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
