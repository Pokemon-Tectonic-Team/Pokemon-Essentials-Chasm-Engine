# Covers the culprit-specific errorMessage(team)/errorMessage(pkmn) methods
# on TeamRules.rb/PokemonRules.rb classes (each returns an Array of every
# distinct violation, not just one), and that PokemonRuleSet#validityErrors
# collects all of them - across every Pokemon and every team rule - instead
# of stopping at the first problem.
require_relative "test_helper"

class ErrorMessagesTest < Minitest::Test
  def test_item_clause_names_both_pokemon_and_the_item
    a = Pkmn.new("Sparky", :PIKACHU, firstItem: :SOULDEW)
    b = Pkmn.new("Buzz", :CHARMANDER, firstItem: :SOULDEW)
    assert_equal ["Sparky and Buzz can't both hold Soul Dew."], ItemClause.new.errorMessage([a, b])
  end

  def test_item_clause_reports_every_duplicate_pair_not_just_the_first
    a = Pkmn.new("Sparky", :PIKACHU, firstItem: :SOULDEW)
    b = Pkmn.new("Buzz", :CHARMANDER, firstItem: :SOULDEW)
    c = Pkmn.new("X", :MEWTWO, firstItem: :LEFTOVERS)
    d = Pkmn.new("Y", :MEW, firstItem: :LEFTOVERS)
    errors = ItemClause.new.errorMessage([a, b, c, d])
    assert_equal 2, errors.length
    assert_includes errors, "Sparky and Buzz can't both hold Soul Dew."
    assert_includes errors, "X and Y can't both hold Leftovers."
  end

  def test_species_clause_names_both_pokemon_and_the_species
    a = Pkmn.new("Sparky", :PIKACHU)
    b = Pkmn.new("Sparky2", :PIKACHU)
    assert_equal ["Sparky and Sparky2 can't both be Pikachu."], SpeciesClause.new.errorMessage([a, b])
  end

  def test_restricted_legends_restriction_lists_the_actual_offenders
    team = [Pkmn.new("Mewtwo", :MEWTWO), Pkmn.new("Mew", :MEW), Pkmn.new("Sparky", :PIKACHU)]
    message = RestrictedLegendsRestriction.new(1).errorMessage(team).first
    assert_match(/Mewtwo/, message)
    assert_match(/Mew\b/, message)
    refute_match(/Sparky/, message)
  end

  def test_total_level_restriction_shows_the_actual_total
    team = [Pkmn.new("X", :PIKACHU, level: 60), Pkmn.new("Y", :CHARMANDER, level: 60)]
    assert_equal ["The combined level of these Pokémon (120) exceeds 100."], TotalLevelRestriction.new(100).errorMessage(team)
  end

  def test_primeval_move_restriction_names_the_specific_move
    arceus = Pkmn.new("Arcy", :ARCEUS, moves: [Move.new(:JUDGMENT), Move.new(:THUNDERBOLT)])
    assert_equal ["Arcy knows Judgment, a Primeval move, which isn't allowed."], PrimevalMoveRestriction.new.errorMessage(arceus)
  end

  def test_banned_move_restriction_names_every_banned_move_known
    arceus = Pkmn.new("Arcy", :ARCEUS, moves: [Move.new(:JUDGMENT), Move.new(:THUNDERBOLT)])
    errors = BannedMoveRestriction.new(:JUDGMENT, :THUNDERBOLT).errorMessage(arceus)
    assert_equal 2, errors.length
    assert_includes errors, "Arcy knows Judgment, which isn't allowed."
    assert_includes errors, "Arcy knows Thunderbolt, which isn't allowed."
  end

  def test_banned_item_restriction_names_the_specific_item
    holder = Pkmn.new("Holder", :PIKACHU, firstItem: :SOULDEW)
    assert_equal ["Holder is holding Soul Dew, which isn't allowed."], BannedItemRestriction.new(:SOULDEW).errorMessage(holder)
  end

  def test_maximum_level_restriction_shows_the_actual_level
    tall = Pkmn.new("Tall", :PIKACHU, level: 75)
    assert_equal ["Tall is level 75, above the maximum of 50."], MaximumLevelRestriction.new(50).errorMessage(tall)
  end

  def test_full_isvalid_is_still_a_plain_boolean
    ruleset = PokemonRuleSet.new(2)
    ruleset.setNumberRange(2, 2)
    ruleset.addTeamRule(ItemClause.new)
    a = Pkmn.new("Sparky", :PIKACHU, firstItem: :SOULDEW)
    b = Pkmn.new("Buzz", :CHARMANDER, firstItem: :SOULDEW)
    assert_equal false, ruleset.isValid?([a, b])
  end

  def test_validity_errors_collects_every_team_rule_violation_at_once
    ruleset = PokemonRuleSet.new(4)
    ruleset.setNumberRange(4, 4)
    ruleset.addTeamRule(ItemClause.new)
    ruleset.addTeamRule(SpeciesClause.new)
    a = Pkmn.new("A", :PIKACHU, firstItem: :SOULDEW)
    b = Pkmn.new("B", :PIKACHU, firstItem: :SOULDEW) # duplicates both species AND item with A
    c = Pkmn.new("C", :MEWTWO, firstItem: :LEFTOVERS)
    d = Pkmn.new("D", :MEW, firstItem: :LEFTOVERS) # duplicates item with C
    errors = ruleset.validityErrors([a, b, c, d])
    assert_includes errors, "A and B can't both hold Soul Dew."
    assert_includes errors, "A and B can't both be Pikachu."
    assert_includes errors, "C and D can't both hold Leftovers."
    assert_equal 3, errors.length
  end

  def test_validity_errors_collects_every_pokemon_rule_violation_at_once
    ruleset = PokemonRuleSet.new(2)
    ruleset.setNumberRange(2, 2)
    ruleset.addPokemonRule(NoLegendaryRestriction.new)
    a = Pkmn.new("Mewtwo", :MEWTWO)
    b = Pkmn.new("Mew", :MEW)
    errors = ruleset.validityErrors([a, b])
    assert_includes errors, "Mewtwo is a legendary Pokémon, which isn't allowed."
    assert_includes errors, "Mew is a legendary Pokémon, which isn't allowed."
    assert_equal 2, errors.length
  end

  def test_validity_errors_is_empty_for_a_valid_team
    ruleset = PokemonRuleSet.new(2)
    ruleset.setNumberRange(2, 2)
    ruleset.addTeamRule(SpeciesClause.new)
    a = Pkmn.new("A", :PIKACHU)
    b = Pkmn.new("B", :CHARMANDER)
    assert_empty ruleset.validityErrors([a, b])
  end
end
