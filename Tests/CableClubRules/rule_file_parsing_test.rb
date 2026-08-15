# Covers the .rules file format (CableClub.parse_rule_file/parse_rule_clause/
# load_rule_file, 002_CableClub.rb) against the real example files in
# OnlinePresets/.
require_relative "test_helper"

class RuleFileParsingTest < Minitest::Test
  def test_singles_rules_example
    name, desc, rules = CableClub.load_rule_file(File.join(REPO_ROOT, "OnlinePresets", "singles.rules"))
    assert_equal "Restricted Singles", name
    assert_equal "Single battle w/ no legendaries @ Lv 70", desc
    assert_equal 30, rules.team_preview
    assert_nil rules.battle_mode
    assert_equal 1, rules.rules_hash[:pokemon].length
    assert_instance_of FixedLevelAdjustment, rules.levelAdjustment
  end

  def test_doubles_rules_example
    name, _desc, rules = CableClub.load_rule_file(File.join(REPO_ROOT, "OnlinePresets", "doubles.rules"))
    assert_equal "Restricted Doubles", name
    assert_equal "double", rules.battle_mode
    assert_equal 1, rules.rules_hash[:team].length
  end

  def test_repeated_keys_accumulate_into_a_list
    Tempfile.create(["multi_rule", ".rules"]) do |f|
      f.write(<<~RULE)
        [Light Cup]
        Description = Max level 50, max weight 99kg, baby Pokemon only
        PartySize = 3,3
        PokemonRules = MaximumLevelRestriction,50
        PokemonRules = BannedSpeciesRestriction,MEWTWO,MEW
        PokemonRules = NoLegendaryRestriction
      RULE
      f.flush
      name, _desc, rules = CableClub.load_rule_file(f.path)
      assert_equal "Light Cup", name
      assert_equal 3, rules.rules_hash[:pokemon].length
    end
  end

  def test_parse_rule_clause_with_one_arg
    assert_equal ["FixedLevelAdjustment", [70]], CableClub.parse_rule_clause("FixedLevelAdjustment,70")
  end

  def test_parse_rule_clause_with_multiple_symbol_args
    assert_equal ["BannedSpeciesRestriction", [:MEWTWO, :MEW]], CableClub.parse_rule_clause("BannedSpeciesRestriction,MEWTWO,MEW")
  end

  def test_parse_rule_clause_with_no_args
    assert_equal ["NoLegendaryRestriction", []], CableClub.parse_rule_clause("NoLegendaryRestriction")
  end
end
