# Base class for the "LevelAdjustment" key in a .rules file, e.g.
# "LevelAdjustment = FixedLevelAdjustment,70". Applied once at battle start to
# temporarily override both trainers' Pokemon levels (restored afterwards),
# so a ruleset can host battles at a level its participants don't actually
# have. Not meant to be referenced directly in a .rules file - it only knows
# which side(s) to apply to (BothTeams/EnemyTeam/MyTeam/BothTeamsDifferent),
# not what level to apply; use one of the concrete subclasses below instead.
#
# Cable Club is always a battle between two real trainers, so there's no
# fixed "enemy" side - both players see the other as the enemy. Because of
# that, PokemonOnlineRules#adjustLevels (007_CableClub_Rules.rb) only ever
# applies a LevelAdjustment whose type is BothTeams; only the subclasses
# below are usable from a Cable Club .rules file. EnemyTeam/BothTeamsDifferent
# adjustments exist for Battle Frontier's asymmetric player-vs-trainer
# challenges instead - see Rules/LevelAdjustments.rb there.
class LevelAdjustment
  BothTeams          = 0
  EnemyTeam          = 1
  MyTeam             = 2
  BothTeamsDifferent = 3

  def initialize(adjustment)
    @adjustment = adjustment
  end

  def type
    @adjustment
  end

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
    adj1 = nil
    adj2 = nil
    ret = [getOldExp(team1, team2), getOldExp(team2, team1)]
    if @adjustment == BothTeams || @adjustment == MyTeam
      adj1 = getAdjustment(team1, team2)
    elsif @adjustment == BothTeamsDifferent
      adj1 = getMyAdjustment(team1, team2)
    end
    if @adjustment == BothTeams || @adjustment == EnemyTeam
      adj2 = getAdjustment(team2, team1)
    elsif @adjustment == BothTeamsDifferent
      adj2 = getTheirAdjustment(team2, team1)
    end
    if adj1
      team1.each_with_index do |pkmn, i|
        next if pkmn.level == adj1[i]
        pkmn.level = adj1[i]
        pkmn.calc_stats
      end
    end
    if adj2
      team2.each_with_index do |pkmn, i|
        next if pkmn.level == adj2[i]
        pkmn.level = adj2[i]
        pkmn.calc_stats
      end
    end
    return ret
  end
end

# LevelAdjustment = FixedLevelAdjustment,70
# Sets every Pokemon on both teams to exactly the given level.
class FixedLevelAdjustment < LevelAdjustment
  def initialize(level)
    super(LevelAdjustment::BothTeams)
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
    super(LevelAdjustment::BothTeams)
    @level = level.clamp(1, GameData::GrowthRate.max_level)
  end

  def getAdjustment(thisTeam, _otherTeam)
    ret = []
    thisTeam.each_with_index { |pkmn, i| ret[i] = [pkmn.level, @level].min }
    return ret
  end
end

# Unused. Was meant to scale level inversely with a species' base stat total
# (weaker species get a higher level), but nothing in the codebase
# constructs this today.
class LevelBalanceAdjustment < LevelAdjustment
  def initialize(minLevel)
    super(LevelAdjustment::BothTeams)
    @minLevel = minLevel
  end

  def getAdjustment(thisTeam, _otherTeam)
    ret = []
    thisTeam.each_with_index do |pkmn, i|
      ret[i] = (113 - (pbBaseStatTotal(pkmn.species) * 0.072)).round
    end
    return ret
  end
end
