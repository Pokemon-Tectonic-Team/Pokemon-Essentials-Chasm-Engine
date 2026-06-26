# Covers the .rules file writer (CableClub.format_rule_arg/format_rule_clause/
# write_rule_file_to_path, 002_CableClub.rb) - the inverse of the parsing
# covered by rule_file_parsing_test.rb.
require_relative "test_helper"

class RuleFileWritingTest < Minitest::Test
  def test_format_rule_arg_integer
    assert_equal "70", CableClub.format_rule_arg(70)
  end

  def test_format_rule_arg_booleans
    assert_equal "true", CableClub.format_rule_arg(true)
    assert_equal "false", CableClub.format_rule_arg(false)
  end

  def test_format_rule_arg_symbol
    assert_equal "MEWTWO", CableClub.format_rule_arg(:MEWTWO)
  end

  def test_format_rule_arg_string_gets_quoted
    assert_equal "\"some text\"", CableClub.format_rule_arg("some text")
  end

  def test_format_rule_clause_with_one_arg
    assert_equal "FixedLevelAdjustment,70", CableClub.format_rule_clause(FixedLevelAdjustment, 70)
  end

  def test_format_rule_clause_with_multiple_symbol_args
    assert_equal "BannedSpeciesRestriction,MEWTWO,MEW", CableClub.format_rule_clause(BannedSpeciesRestriction, :MEWTWO, :MEW)
  end

  def test_format_rule_clause_with_no_args
    assert_equal "NoLegendaryRestriction", CableClub.format_rule_clause(NoLegendaryRestriction)
  end

  # Round-trips a fully-populated PokemonOnlineRules through the real
  # writer and the real reader, so the writer is validated against the
  # already-tested parser rather than a hand-written expected string.
  def test_write_then_read_round_trip
    rules = PokemonOnlineRules.new
    rules.setTeamPreview(30)
    rules.setNumberRange(2, 4)
    rules.setBattleMode("double")
    rules.setLevelAdjustment(FixedLevelAdjustment, 70)
    rules.addPokemonRule(MinimumLevelRestriction, 10)
    rules.addPokemonRule(BannedSpeciesRestriction, :MEWTWO, :MEW)
    rules.addTeamRule(SpeciesClause)
    rules.addTeamRule(TotalLevelRestriction, 200)

    Tempfile.create(["roundtrip", ".rules"]) do |f|
      CableClub.write_rule_file_to_path(f.path, ["Round Trip Cup", "A round-trip test ruleset", rules])
      name, desc, reloaded = CableClub.load_rule_file(f.path)

      assert_equal "Round Trip Cup", name
      assert_equal "A round-trip test ruleset", desc
      assert_equal 30, reloaded.team_preview
      assert_equal 2, reloaded.ruleset.minLength
      assert_equal 4, reloaded.ruleset.maxLength
      assert_equal "double", reloaded.battle_mode
      assert_instance_of FixedLevelAdjustment, reloaded.levelAdjustment
      assert_equal 2, reloaded.rules_hash[:pokemon].length
      assert_equal 2, reloaded.rules_hash[:team].length
    end
  end

  def test_team_preview_omitted_when_zero
    rules = PokemonOnlineRules.new
    rules.setNumberRange(1, 1)
    Tempfile.create(["no_preview", ".rules"]) do |f|
      CableClub.write_rule_file_to_path(f.path, ["No Preview", "desc", rules])
      refute_includes File.read(f.path), "TeamPreview"
    end
  end

  def test_level_adjustment_and_battle_mode_omitted_when_unset
    rules = PokemonOnlineRules.new
    rules.setNumberRange(1, 1)
    Tempfile.create(["no_extras", ".rules"]) do |f|
      CableClub.write_rule_file_to_path(f.path, ["No Extras", "desc", rules])
      contents = File.read(f.path)
      refute_includes contents, "LevelAdjustment"
      refute_includes contents, "BattleMode"
    end
  end

  def test_multiple_pokemon_and_team_rules_each_get_their_own_line
    rules = PokemonOnlineRules.new
    rules.setNumberRange(1, 1)
    rules.addPokemonRule(NoLegendaryRestriction)
    rules.addPokemonRule(MaximumLevelRestriction, 50)
    rules.addTeamRule(ItemClause)
    Tempfile.create(["multi", ".rules"]) do |f|
      CableClub.write_rule_file_to_path(f.path, ["Multi", "desc", rules])
      _name, _desc, reloaded = CableClub.load_rule_file(f.path)
      assert_equal 2, reloaded.rules_hash[:pokemon].length
      assert_equal 1, reloaded.rules_hash[:team].length
    end
  end
end
