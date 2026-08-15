class PokemonOnlineRules
  attr_reader :team_preview
  attr_reader :ruleset
  attr_reader :levelAdjustment
  attr_reader :battle_mode
  attr_reader :rules_hash

  def initialize
    @team_preview = 0
    @ruleset=ruleset ? ruleset : PokemonRuleSet.new
    @levelAdjustment=nil
    @battle_mode=nil
    @rules_hash={:battle_mode=>nil,:pokemon=>[], :team=>[],:level_adjust=>nil}
  end
  
  def team_preview?; return @team_preview>0; end
  
  def number
    return self.ruleset.number
  end

  def setNumberRange(minValue,maxValue)
    self.ruleset.setNumberRange(minValue,maxValue)
    return self
  end
  
  def setTeamPreview(value)
    @team_preview = value
    return self
  end
  
  def adjustLevels(party1,party2)
    return @levelAdjustment.adjustLevels(party1,party2) if @levelAdjustment
    return nil
  end

  def unadjustLevels(party1,party2,adjusts)
    @levelAdjustment.unadjustLevels(party1,party2,adjusts) if @levelAdjustment && adjusts
  end

  def addPokemonRule(rule, *args)
    saved_args = CableClub::apply_args_type_hint(*args)
    @rules_hash[:pokemon].push([rule,*saved_args])
    self.ruleset.addPokemonRule(rule.new(*args))
    return self
  end
  
  def addTeamRule(rule, *args)
    saved_args = CableClub::apply_args_type_hint(*args)
    @rules_hash[:team].push([rule,*saved_args])
    self.ruleset.addTeamRule(rule.new(*args))
    return self
  end

  def setLevelAdjustment(rule,*args)
    if rule
      saved_args = CableClub::apply_args_type_hint(*args)
      @rules_hash[:level_adjust]=[rule,*saved_args]
      @levelAdjustment=rule.new(*args)
    else
      @rules_hash[:level_adjust]=nil
      @levelAdjustment=nil
    end
    return self
  end

  def setBattleMode(mode)
    @battle_mode = mode
    @rules_hash[:battle_mode] = mode
    return self
  end

  def applyBattleMode(battle)
    battle.setBattleMode(@battle_mode) if @battle_mode
  end
end