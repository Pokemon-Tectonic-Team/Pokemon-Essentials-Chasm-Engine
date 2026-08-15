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

  def test_hasValidTeam_basic_legal_and_illegal
    ruleset = PokemonRuleSet.new(1)
    ruleset.setNumberRange(1, 1)
    ruleset.addPokemonRule(NoLegendaryRestriction.new)
    assert ruleset.hasValidTeam?([Pkmn.new("Pikachu", :PIKACHU)])
    refute ruleset.hasValidTeam?([Pkmn.new("Mewtwo", :MEWTWO)])
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
    refute ruleset.hasValidTeam?(duplicates)
    errors = ruleset.registrationErrors(duplicates)
    assert_equal ["Pikachu1 and Pikachu2 can't both be Pikachu."], errors
  end

  # Eggs and not-able Pokemon used to only be banned if a ruleset explicitly
  # opted into NonEggRestriction/AblePokemonRestriction. Both are gone now -
  # isPokemonValid?/pokemonInvalidReasons reject them unconditionally, with
  # no PokemonRules added at all.
  def test_eggs_are_always_rejected_with_no_rules_added
    ruleset = PokemonRuleSet.new(1)
    egg = Pkmn.new("Egg", :PIKACHU, egg: true)
    refute ruleset.isPokemonValid?(egg)
    assert_equal ["Egg is an egg, which isn't allowed."], ruleset.pokemonInvalidReasons(egg)
  end

  def test_not_able_pokemon_are_always_rejected_with_no_rules_added
    ruleset = PokemonRuleSet.new(1)
    fainted = Pkmn.new("Fainted", :PIKACHU, able: false)
    refute ruleset.isPokemonValid?(fainted)
    assert_equal ["Fainted isn't able to battle."], ruleset.pokemonInvalidReasons(fainted)
  end

  # pokemonInvalidReasons used to return as soon as it found the egg/not-able
  # issue, so a Pokemon that was also banned for some other reason (e.g. a
  # banned item) would only ever be told about the egg - the other rule never
  # even ran. It should report everything wrong at once, same as any other
  # PokemonRule.
  def test_egg_does_not_stop_other_pokemon_rules_from_also_being_reported
    ruleset = PokemonRuleSet.new(1)
    ruleset.addPokemonRule(BannedItemRestriction.new(:SOULDEW))
    egg = Pkmn.new("Egg", :PIKACHU, egg: true, firstItem: :SOULDEW)
    errors = ruleset.pokemonInvalidReasons(egg)
    assert_includes errors, "Egg is an egg, which isn't allowed."
    assert_includes errors, "Egg is holding Soul Dew, which isn't allowed."
    assert_equal 2, errors.length
  end

  def test_not_able_does_not_stop_other_pokemon_rules_from_also_being_reported
    ruleset = PokemonRuleSet.new(1)
    ruleset.addPokemonRule(BannedItemRestriction.new(:SOULDEW))
    fainted = Pkmn.new("Fainted", :PIKACHU, able: false, firstItem: :SOULDEW)
    errors = ruleset.pokemonInvalidReasons(fainted)
    assert_includes errors, "Fainted isn't able to battle."
    assert_includes errors, "Fainted is holding Soul Dew, which isn't allowed."
    assert_equal 2, errors.length
  end
end
