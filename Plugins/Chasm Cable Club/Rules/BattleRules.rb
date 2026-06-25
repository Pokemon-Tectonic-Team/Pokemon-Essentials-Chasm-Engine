# Base class for the "BattleRules" clause list in a .rules file. Each
# subclass below can be referenced by name, e.g. "BattleRules = DoubleBattle",
# and has setRule(battle) called once against the real battle when it starts.
class BattleRule
  def setRule(battle); end
end

# BattleRules = DoubleBattle
# Makes the battle a double battle. There's no equivalent "SingleBattle" rule
# here since single is the implicit default; see Battle Frontier's
# Rules/BattleRules.rb if you need it for something other than Cable Club.
class DoubleBattle < BattleRule
  def setRule(battle); battle.setBattleMode("double"); end
end
