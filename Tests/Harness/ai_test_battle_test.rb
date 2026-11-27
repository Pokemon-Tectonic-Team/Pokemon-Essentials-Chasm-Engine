require_relative "../support/test_helper"

class AITestBattleTest < Minitest::Test
    def test_is_a_real_battle_with_a_real_field
        battle = AITestBattle.new

        assert_kind_of PokeBattle_Battle, battle
        assert_kind_of PokeBattle_ActiveField, battle.field
        refute battle.field.effectActive?(:InsightRoom)
    end

    def test_field_effects_apply_through_the_battle
        battle = AITestBattle.new
        battle.field.applyEffect(:InsightRoom, 5)

        assert battle.field.effectActive?(:InsightRoom)
        assert_equal ["An insightful area appeared! Everyone gets a 5th move!"], battle.messages
    end

    def test_add_battler_places_a_test_battler_in_this_battle_at_its_index
        battle = AITestBattle.new
        battler = battle.add_battler(index: 2, level: 30)

        assert_kind_of TestBattler, battler
        assert_attributes({ index: 2, level: 30 }, battler)
        assert_same battler, battle.battlers[2]
    end

    def test_add_battler_links_the_battler_to_this_battle
        battle = AITestBattle.new

        assert_same battle, battle.add_battler.battle
    end

    def test_the_player_owns_the_even_side_only
        battle = AITestBattle.new

        owned = (0..3).map { |index| battle.pbOwnedByPlayer?(index) }

        assert_equal [true, false, true, false], owned
    end

    def test_the_opposing_trainer_has_the_policies_given
        battle = AITestBattle.new(opponent_policies: [:PREDICTS_PLAYER])

        assert_equal [:PREDICTS_PLAYER], battle.add_battler(index: 1).ownersPolicies
        assert_empty battle.add_battler(index: 0).ownersPolicies
    end

    def test_known_moves_start_from_auto_known_moves_as_a_copy
        auto_known = { 4 => [:TACKLE] }
        battle = AITestBattle.new(auto_known_moves: auto_known)
        known = battle.aiKnownMoves(TestPokemon.new(personal_id: 4))
        known.push(:BITE)

        assert_equal %i[TACKLE BITE], known
        assert_equal [:TACKLE], auto_known[4]
    end

    def test_known_moves_start_empty_for_a_pokemon_not_given
        assert_empty AITestBattle.new.aiKnownMoves(TestPokemon.new(personal_id: 9))
    end

    def test_battle_ai_and_predictions_are_what_was_given
        ai = Object.new
        predictions = [[:SwitchOut, 1]]
        battle = AITestBattle.new(battle_ai: ai, predicted_actions: predictions)

        assert_same ai, battle.instance_variable_get(:@battleAI)
        assert_same predictions, battle.instance_variable_get(:@predictedActions)
    end

    def test_display_records_messages_in_order
        battle = AITestBattle.new
        battle.pbDisplay("one")
        battle.pbDisplay("two", no_highlighting: true)

        assert_equal %w[one two], battle.messages
    end
end
