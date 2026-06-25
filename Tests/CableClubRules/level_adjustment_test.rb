# Covers Cable Club's own (always-symmetric) LevelAdjustment subclasses -
# FixedLevelAdjustment, CappedLevelAdjustment, LevelBalanceAdjustment - which
# apply identically to both teams, since Cable Club has no concept of "the
# enemy" the way Battle Frontier's asymmetric extension does (see
# loading_test.rb for that side instead).
require_relative "test_helper"

class LevelAdjustmentTest < Minitest::Test
  def test_fixed_level_adjustment_sets_every_pokemon_on_both_teams
    team1 = [Pkmn.new("A", :PIKACHU, level: 10), Pkmn.new("B", :CHARMANDER, level: 20)]
    team2 = [Pkmn.new("C", :PIKACHU, level: 30)]
    FixedLevelAdjustment.new(70).adjustLevels(team1, team2)
    assert_equal [70, 70], team1.map(&:level)
    assert_equal [70], team2.map(&:level)
  end

  def test_capped_level_adjustment_only_lowers_pokemon_above_the_cap
    team1 = [Pkmn.new("A", :PIKACHU, level: 80)]
    team2 = [Pkmn.new("B", :CHARMANDER, level: 40)]
    CappedLevelAdjustment.new(50).adjustLevels(team1, team2)
    assert_equal 50, team1[0].level
    assert_equal 40, team2[0].level
  end

  def test_level_balance_adjustment_boosts_weak_species_and_handicaps_strong_ones
    weak = Pkmn.new("Weak", :PIKACHU,
                     base_stats: { HP: 33, ATTACK: 33, DEFENSE: 33, SPEED: 33, SPECIAL_ATTACK: 33, SPECIAL_DEFENSE: 30 }) # BST 195
    strong = Pkmn.new("Strong", :MEWTWO,
                       base_stats: { HP: 120, ATTACK: 120, DEFENSE: 120, SPEED: 120, SPECIAL_ATTACK: 120, SPECIAL_DEFENSE: 120 }) # BST 720
    LevelBalanceAdjustment.new.adjustLevels([weak], [strong])
    maxLevel = GameData::GrowthRate.max_level
    assert_equal maxLevel, weak.level
    assert_equal maxLevel - LevelBalanceAdjustment::LEVEL_SPREAD, strong.level
  end

  def test_level_balance_adjustment_clamps_within_the_level_spread
    impossiblyWeak = Pkmn.new("Tiny", :PIKACHU,
                               base_stats: { HP: 1, ATTACK: 1, DEFENSE: 1, SPEED: 1, SPECIAL_ATTACK: 1, SPECIAL_DEFENSE: 1 }) # BST 6
    LevelBalanceAdjustment.new.adjustLevels([impossiblyWeak], [Pkmn.new("Other", :CHARMANDER)])
    assert_equal GameData::GrowthRate.max_level, impossiblyWeak.level
  end
end
