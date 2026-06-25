#===============================================================================
#
#===============================================================================
class StandardRules < PokemonRuleSet
    attr_reader :number

    def initialize(number, level = nil)
      super(number)
      addPokemonRule(StandardRestriction.new)
      addTeamRule(SpeciesClause.new)
      addTeamRule(ItemClause.new)
      addPokemonRule(MaximumLevelRestriction.new(level)) if level
    end
  end

  ###########################################
  #  Generation IV Cups
  ###########################################
  #===============================================================================
  #
  #===============================================================================
  class StandardCup < StandardRules
    def initialize
      super(3, 50)
    end

    def name
      return _INTL("Standard Cup")
    end
  end

  #===============================================================================
  #
  #===============================================================================
  class DoubleCup < StandardRules
    def initialize
      super(4, 50)
    end

    def name
      return _INTL("Double Cup")
    end
  end

  #===============================================================================
  #
  #===============================================================================
  class FancyCup < PokemonRuleSet
    def initialize
      super(3)
      addPokemonRule(StandardRestriction.new)
      addPokemonRule(MaximumLevelRestriction.new(30))
      addTeamRule(TotalLevelRestriction.new(80))
      addPokemonRule(HeightRestriction.new(2))
      addPokemonRule(WeightRestriction.new(20))
      addPokemonRule(BabyRestriction.new)
      addTeamRule(SpeciesClause.new)
      addTeamRule(ItemClause.new)
    end

    def name
      return _INTL("Fancy Cup")
    end
  end

  #===============================================================================
  #
  #===============================================================================
  class LittleCup < PokemonRuleSet
    def initialize
      super(3)
      addPokemonRule(StandardRestriction.new)
      addPokemonRule(MaximumLevelRestriction.new(5))
      addPokemonRule(BabyRestriction.new)
      addTeamRule(SpeciesClause.new)
      addTeamRule(ItemClause.new)
    end

    def name
      return _INTL("Little Cup")
    end
  end

  #===============================================================================
  #
  #===============================================================================
  class LightCup < PokemonRuleSet
    def initialize
      super(3)
      addPokemonRule(StandardRestriction.new)
      addPokemonRule(MaximumLevelRestriction.new(50))
      addPokemonRule(WeightRestriction.new(99))
      addPokemonRule(BabyRestriction.new)
      addTeamRule(SpeciesClause.new)
      addTeamRule(ItemClause.new)
    end

    def name
      return _INTL("Light Cup")
    end
  end
