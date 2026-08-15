# Base class for PokemonChallengeRules#addBattleRule (ChallengeRules.rb):
# each subclass's setRule(battle) is called once against the real battle
# when it starts. Cable Club used to have its own by-name-lookup version of
# this for its .rules file format, but that only ever needed to pick a
# battle size, so it was replaced with PokemonOnlineRules#setBattleMode
# instead - this class hierarchy now exists only for Battle Frontier's own
# (largely unused) challenge rules.
class BattleRule
  def setRule(battle); end
end

# Used by ChallengeRules.rb's setDoubleBattle and BattleChallenge.rb.
class DoubleBattle < BattleRule
  def setRule(battle); battle.setBattleMode("double"); end
end

# Used by ChallengeRules.rb's setDoubleBattle and BattleChallenge.rb.
class SingleBattle < BattleRule
  def setRule(battle); battle.setBattleMode("single"); end
end

# None of the clauses below are implemented by the battle engine - setting
# any of them has no gameplay effect. battle.rules only has one key the
# engine actually reads ("alwaysflee", for roamer encounters); these "...clause"
# keys have no reader anywhere. Kept only because ChallengeRules.rb's
# (themselves unused) pbXxxRules factory functions still construct them
# directly rather than through Cable Club's by-name rule lookup.
class SoulDewBattleClause < BattleRule
  def setRule(battle); battle.rules["souldewclause"] = true; end
end

class SleepClause < BattleRule
  def setRule(battle); battle.rules["sleepclause"] = true; end
end

class FreezeClause < BattleRule
  def setRule(battle); battle.rules["freezeclause"] = true; end
end

class EvasionClause < BattleRule
  def setRule(battle); battle.rules["evasionclause"] = true; end
end

class OHKOClause < BattleRule
  def setRule(battle); battle.rules["ohkoclause"] = true; end
end

class PerishSongClause < BattleRule
  def setRule(battle); battle.rules["perishsong"] = true; end
end

class SelfKOClause < BattleRule
  def setRule(battle); battle.rules["selfkoclause"] = true; end
end

class SelfdestructClause < BattleRule
  def setRule(battle); battle.rules["selfdestructclause"] = true; end
end

class SonicBoomClause < BattleRule
  def setRule(battle); battle.rules["sonicboomclause"] = true; end
end

class ModifiedSleepClause < BattleRule
  def setRule(battle); battle.rules["modifiedsleepclause"] = true; end
end

class SkillSwapClause < BattleRule
  def setRule(battle); battle.rules["skillswapclause"] = true; end
end
