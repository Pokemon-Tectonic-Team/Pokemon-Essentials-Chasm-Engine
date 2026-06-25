# Covers PokemonRuleSet's core validation engine (Rulesets.rb): the
# TeamRules/SubsetRules merge, the addSubsetRule bug that merge fixed, and
# the bounds-check fix that came from removing the redundant
# canRegisterTeam? nested-subset search.
require_relative "test_helper"

class RulesetValidationTest < Minitest::Test
  def test_addsubsetrule_and_canregisterteam_no_longer_exist
    ruleset = PokemonRuleSet.new
    refute ruleset.respond_to?(:addSubsetRule)
    refute ruleset.respond_to?(:canRegisterTeam?)
    assert ruleset.respond_to?(:addTeamRule)
  end

  def test_hasRegistrableTeam_basic_legal_and_illegal
    ruleset = PokemonRuleSet.new(1)
    ruleset.setNumberRange(1, 1)
    ruleset.addPokemonRule(NoLegendaryRestriction.new)
    assert ruleset.hasRegistrableTeam?([Pkmn.new("Pikachu", :PIKACHU)])
    refute ruleset.hasRegistrableTeam?([Pkmn.new("Mewtwo", :MEWTWO)])
  end

  # Before the canRegisterTeam? removal, isValid?-equivalent bounds checks
  # used the artificially wide minTeamLength/maxTeamLength (always up to
  # Settings::MAX_PARTY_SIZE) instead of the ruleset's real PartySize max,
  # so an oversized candidate could be wrongly accepted as registrable.
  def test_oversized_candidate_is_rejected_by_partysize_max
    ruleset = PokemonRuleSet.new(3) # PartySize max 3
    ruleset.setNumberRange(1, 3)
    ruleset.addTeamRule(SpeciesClause.new)
    four_distinct_species = [
      Pkmn.new("A", :PIKACHU), Pkmn.new("B", :CHARMANDER),
      Pkmn.new("C", :MEWTWO), Pkmn.new("D", :MEW),
    ]
    refute ruleset.isValid?(four_distinct_species)
    assert ruleset.isValid?(four_distinct_species[0..2])
  end

  # TotalLevelRestriction used to only be addable via addSubsetRule, which
  # pushed into @teamRules instead of @subsetRules - so it was checked, but
  # PokemonRuleSet#suggestedLevel's own @subsetRules scan for it never found
  # it. Now everything is one list, so this isn't an issue, but verify the
  # rule itself is actually enforced via the standard addTeamRule path.
  def test_total_level_restriction_is_enforced
    ruleset = PokemonRuleSet.new(2)
    ruleset.setNumberRange(2, 2)
    ruleset.addTeamRule(TotalLevelRestriction.new(100))
    under_cap = [Pkmn.new("A", :PIKACHU, level: 40), Pkmn.new("B", :CHARMANDER, level: 40)]
    over_cap = [Pkmn.new("C", :PIKACHU, level: 60), Pkmn.new("D", :CHARMANDER, level: 60)]
    assert ruleset.isValid?(under_cap)
    refute ruleset.isValid?(over_cap)
  end

  def test_registration_errors_end_to_end
    ruleset = PokemonRuleSet.new(2)
    ruleset.setNumberRange(2, 2)
    ruleset.addTeamRule(SpeciesClause.new)
    duplicates = [Pkmn.new("Pikachu1", :PIKACHU), Pkmn.new("Pikachu2", :PIKACHU)]
    refute ruleset.hasRegistrableTeam?(duplicates)
    errors = ruleset.registrationErrors(duplicates)
    assert_equal ["Pikachu1 and Pikachu2 can't both be Pikachu."], errors
  end
end
