# Covers TeamRules classes' own isValid?/errorMessage correctness directly -
# as opposed to error_messages_test.rb (the array-returning contract) or
# ruleset_validation_test.rb (PokemonRuleSet's engine).
require_relative "test_helper"

class TeamRulesTest < Minitest::Test
  def test_nickname_clause_does_not_crash_when_checking_a_team
    team = [Pkmn.new("Sparky", :PIKACHU), Pkmn.new("Buzz", :CHARMANDER)]
    refute_nil NicknameClause.new.isValid?(team)
  end

  def test_nickname_clause_rejects_duplicate_nicknames
    team = [Pkmn.new("Same", :PIKACHU), Pkmn.new("Same", :CHARMANDER)]
    refute NicknameClause.new.isValid?(team)
  end

  # Regression test: isValid? used to only check the species-name collision
  # for the outer loop variable (team[i]), and i never reached the last
  # index - so an illegal nickname on the last team member alone would
  # wrongly pass, even though errorMessage (which checks every Pokemon) would
  # have flagged it.
  def test_nickname_clause_rejects_a_species_name_collision_on_the_last_team_member
    NicknameChecker.getName(:MEW) # primes the cache with Mew's real name
    team = [
      Pkmn.new("Pikachu", :PIKACHU),
      Pkmn.new("Charmander", :CHARMANDER),
      Pkmn.new("Mew", :MEWTWO), # nickname illegally matches Mew's real species name
    ]
    refute NicknameClause.new.isValid?(team)
    errors = NicknameClause.new.errorMessage(team)
    assert_equal ["Mew's nickname can't match another Pokémon's species name."], errors
  end

  def test_nickname_clause_allows_a_team_with_no_collisions
    team = [Pkmn.new("Sparky", :PIKACHU), Pkmn.new("Buzz", :CHARMANDER)]
    assert NicknameClause.new.isValid?(team)
    assert_empty NicknameClause.new.errorMessage(team)
  end
end
