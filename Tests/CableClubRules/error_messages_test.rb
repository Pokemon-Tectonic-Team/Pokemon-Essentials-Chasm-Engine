# Covers the culprit-specific errorMessage(team)/errorMessage(pkmn) methods
# on TeamRules.rb/PokemonRules.rb classes, and that PokemonRuleSet#isValid?
# threads the failing team/Pokemon through to them correctly.
require_relative "test_helper"

class ErrorMessagesTest < Minitest::Test
  def test_item_clause_names_both_pokemon_and_the_item
    a = Pkmn.new("Sparky", :PIKACHU, firstItem: :SOULDEW)
    b = Pkmn.new("Buzz", :CHARMANDER, firstItem: :SOULDEW)
    assert_equal "Sparky and Buzz can't both hold Soul Dew.", ItemClause.new.errorMessage([a, b])
  end

  def test_species_clause_names_both_pokemon_and_the_species
    a = Pkmn.new("Sparky", :PIKACHU)
    b = Pkmn.new("Sparky2", :PIKACHU)
    assert_equal "Sparky and Sparky2 can't both be Pikachu.", SpeciesClause.new.errorMessage([a, b])
  end

  def test_restricted_legends_restriction_lists_the_actual_offenders
    team = [Pkmn.new("Mewtwo", :MEWTWO), Pkmn.new("Mew", :MEW), Pkmn.new("Sparky", :PIKACHU)]
    message = RestrictedLegendsRestriction.new(1).errorMessage(team)
    assert_match(/Mewtwo/, message)
    assert_match(/Mew\b/, message)
    refute_match(/Sparky/, message)
  end

  def test_total_level_restriction_shows_the_actual_total
    team = [Pkmn.new("X", :PIKACHU, level: 60), Pkmn.new("Y", :CHARMANDER, level: 60)]
    assert_equal "The combined level of these Pokémon (120) exceeds 100.", TotalLevelRestriction.new(100).errorMessage(team)
  end

  def test_primeval_move_restriction_names_the_specific_move
    arceus = Pkmn.new("Arcy", :ARCEUS, moves: [Move.new(:JUDGMENT), Move.new(:THUNDERBOLT)])
    assert_equal "Arcy knows Judgment, a Primeval move, which isn't allowed.", PrimevalMoveRestriction.new.errorMessage(arceus)
  end

  def test_banned_move_restriction_names_the_specific_move
    arceus = Pkmn.new("Arcy", :ARCEUS, moves: [Move.new(:JUDGMENT)])
    assert_equal "Arcy knows Judgment, which isn't allowed.", BannedMoveRestriction.new(:JUDGMENT).errorMessage(arceus)
  end

  def test_banned_item_restriction_names_the_specific_item
    holder = Pkmn.new("Holder", :PIKACHU, firstItem: :SOULDEW)
    assert_equal "Holder is holding Soul Dew, which isn't allowed.", BannedItemRestriction.new(:SOULDEW).errorMessage(holder)
  end

  def test_maximum_level_restriction_shows_the_actual_level
    tall = Pkmn.new("Tall", :PIKACHU, level: 75)
    assert_equal "Tall is level 75, above the maximum of 50.", MaximumLevelRestriction.new(50).errorMessage(tall)
  end

  def test_full_isvalid_threads_team_through_to_team_rule_errors
    ruleset = PokemonRuleSet.new(2)
    ruleset.setNumberRange(2, 2)
    ruleset.addTeamRule(ItemClause.new)
    a = Pkmn.new("Sparky", :PIKACHU, firstItem: :SOULDEW)
    b = Pkmn.new("Buzz", :CHARMANDER, firstItem: :SOULDEW)
    errors = []
    refute ruleset.isValid?([a, b], errors)
    assert_equal ["Sparky and Buzz can't both hold Soul Dew."], errors
  end

  def test_full_isvalid_threads_pkmn_through_to_pokemon_rule_errors
    ruleset = PokemonRuleSet.new(1)
    ruleset.setNumberRange(1, 1)
    ruleset.addPokemonRule(PrimevalMoveRestriction.new)
    arceus = Pkmn.new("Arcy", :ARCEUS, moves: [Move.new(:JUDGMENT)])
    errors = []
    refute ruleset.isValid?([arceus], errors)
    assert_equal ["Arcy knows Judgment, a Primeval move, which isn't allowed."], errors
  end
end
