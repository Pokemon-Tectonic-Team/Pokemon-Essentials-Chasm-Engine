# Confirms the cross-plugin split (Cable Club owns the shared Rules/
# classes; Battle Frontier owns its own BattleRule hierarchy + the unused
# Cup/ChallengeRules content that still references the shared classes)
# loads cleanly and that Battle Frontier's side still works unmodified.
require_relative "test_helper"

class LoadingTest < Minitest::Test
  def test_standard_rules_subclasses_the_relocated_pokemon_rule_set
    assert StandardRules.ancestors.include?(PokemonRuleSet)
  end

  def test_standard_cup_name
    assert_equal "Standard Cup", StandardCup.new.name
  end

  def test_fancy_cup_builds_with_a_team_rule_that_used_to_be_a_dead_subset_rule
    cup = FancyCup.new
    assert_instance_of FancyCup, cup
  end

  def test_pokemon_challenge_rules_builds
    challenge = PokemonChallengeRules.new
    challenge.addPokemonRule(StandardRestriction.new)
    challenge.setDoubleBattle(true)
    assert_instance_of PokemonRuleSet, challenge.ruleset
  end

  # These pbXxxRules factory functions are themselves dead code (nothing
  # calls them), but they directly instantiate classes like SleepClause and
  # SingleBattle rather than going through Cable Club's safe by-name
  # lookup, so a NameError here would mean the Battle Frontier split broke
  # something it still depends on.
  def test_dead_but_extant_challenge_rule_factories_still_resolve
    assert_instance_of PokemonChallengeRules, pbPikaCupRules(false)
    assert_instance_of PokemonChallengeRules, pbBattleTowerRules(false, false)
    assert_instance_of PokemonChallengeRules, pbBattleFactoryRules(true, true)
  end

  def test_enemy_level_adjustment_only_changes_the_enemy_team
    player = [Pkmn.new("Player", :PIKACHU, level: 10)]
    enemy = [Pkmn.new("Enemy", :CHARMANDER, level: 20)]
    EnemyLevelAdjustment.new(50).adjustLevels(player, enemy)
    assert_equal 10, player[0].level
    assert_equal 50, enemy[0].level
  end
end
