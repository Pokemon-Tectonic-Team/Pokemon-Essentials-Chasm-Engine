# Covers PokemonOnlineRules#setBattleMode/#applyBattleMode (which replaced
# the BattleRule/DoubleBattle/TripleBattle class-based mechanism for Cable
# Club) and the network wire protocol round trip through
# CableClub.write_battle_rule/parse_battle_rule.
require_relative "test_helper"

class BattleModeTest < Minitest::Test
  class StubBattle
    attr_reader :mode
    def setBattleMode(mode); @mode = mode; end
  end

  def test_apply_battle_mode_sets_the_battle_s_mode
    rules = PokemonOnlineRules.new
    rules.setBattleMode("double")
    battle = StubBattle.new
    rules.applyBattleMode(battle)
    assert_equal "double", battle.mode
  end

  def test_apply_battle_mode_with_no_mode_set_leaves_battle_untouched
    rules = PokemonOnlineRules.new
    battle = StubBattle.new
    rules.applyBattleMode(battle)
    assert_nil battle.mode
  end

  def test_wire_protocol_round_trip
    rules = PokemonOnlineRules.new
    rules.setBattleMode("double")
    rules.addPokemonRule(NoLegendaryRestriction)
    rules.setLevelAdjustment(FixedLevelAdjustment, 70)

    writer = RecordWriter.new
    CableClub.write_battle_rule(writer, ["Test Ruleset", "A test ruleset", rules])
    record = RecordParser.new(writer.line!.chomp)
    name, desc, parsed = CableClub.parse_battle_rule(record)

    assert_equal "Test Ruleset", name
    assert_equal "A test ruleset", desc
    assert_equal "double", parsed.battle_mode
    assert_instance_of FixedLevelAdjustment, parsed.levelAdjustment
    assert_equal 1, parsed.rules_hash[:pokemon].length
  end

  def test_wire_protocol_round_trip_with_no_battle_mode_set
    rules = PokemonOnlineRules.new
    writer = RecordWriter.new
    CableClub.write_battle_rule(writer, ["Plain", "No special mode", rules])
    record = RecordParser.new(writer.line!.chomp)
    _name, _desc, parsed = CableClub.parse_battle_rule(record)
    assert_nil parsed.battle_mode
  end
end
