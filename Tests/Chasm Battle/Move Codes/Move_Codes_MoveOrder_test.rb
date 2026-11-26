require_relative "../../support/test_helper"

class MoveOrderMoveCodesTest < Minitest::Test
    USE_MOVE = [:UseMove, 0, :chosen_move].freeze

    # A battle of an actor at index 0 and a target at index 1, the target not last in priority.
    # Overrides: choices (the target's is choices[1]), target / actor battler attributes, priority.
    # The inherited pbMoveFailedTargetAlreadyMoved? is faked to answer already_moved and to record
    # its arguments in the move's `already_moved_calls`.
    def setup_quash(target_choice: USE_MOVE, target: {}, actor: {}, last: :actor, id: :TESTMOVE,
                    already_moved: false)
        actor_battler = TestBattler.new(index: 0, effects: { Quash: 0 }, name: "Actor", **actor)
        target_battler = TestBattler.new(index: 1, effects: { Quash: 0 }, name: "Target", **target)
        priority = last == :actor ? [target_battler, actor_battler] : [actor_battler, target_battler]
        battle = TestBattle.new(battlers: [actor_battler, target_battler], priority: priority,
                                choices: [USE_MOVE, target_choice])
        move = make_move(PokeBattle_Move_TargetActsLast, battle: battle, id: id)
        calls = []
        move.define_singleton_method(:already_moved_calls) { calls }
        move.define_singleton_method(:pbMoveFailedTargetAlreadyMoved?) do |tgt, show_message = true|
            calls << [tgt, show_message]
            already_moved
        end
        [move, actor_battler, target_battler, battle]
    end

    def fails?(move, user, target, show_message = true)
        move.pbFailsAgainstTarget?(user, target, show_message)
    end

    # pbFailsAgainstTarget?

    def test_an_ordinary_target_does_not_fail
        move, user, target, battle = setup_quash
        assert_equal false, fails?(move, user, target)
        assert_empty battle.messages
    end

    def test_the_inherited_already_moved_check_is_asked_about_the_target
        move, user, target, _battle = setup_quash
        fails?(move, user, target, false)
        assert_equal [[target, false]], move.already_moved_calls
    end

    def test_a_target_failing_the_inherited_already_moved_check_fails
        move, user, target, battle = setup_quash(already_moved: true)
        assert_equal true, fails?(move, user, target)
        assert_empty battle.messages
    end

    def test_a_target_with_no_chosen_move_fails
        move, user, target, battle = setup_quash(target_choice: [:UseMove, 0, nil])
        assert_equal true, fails?(move, user, target)
        assert_equal ["But it failed, since Target isn't using a move this turn!"], battle.messages
    end

    def test_a_target_holding_the_highest_quash_fails
        move, user, target, battle = setup_quash(target: { effects: { Quash: 2 } }, actor: { effects: { Quash: 1 } })
        assert_equal true, fails?(move, user, target)
        assert_equal ["But it failed!"], battle.messages
    end

    def test_a_target_holding_a_lower_quash_does_not_fail
        move, user, target, battle = setup_quash(target: { effects: { Quash: 1 } }, actor: { effects: { Quash: 2 } })
        assert_equal false, fails?(move, user, target)
        assert_empty battle.messages
    end

    def test_a_target_last_in_priority_with_no_quash_fails
        move, user, target, battle = setup_quash(last: :target)
        assert_equal true, fails?(move, user, target)
        assert_equal ["But it failed, since Target was already forced to move last!"], battle.messages
    end

    def test_a_target_last_in_priority_does_not_fail_while_a_quash_is_active
        move, user, target, battle = setup_quash(last: :target, actor: { effects: { Quash: 1 } })
        assert_equal false, fails?(move, user, target)
        assert_empty battle.messages
    end

    def test_no_failure_displays_without_show_message
        [{ target_choice: [:UseMove, 0, nil] }, { last: :target },
         { target: { effects: { Quash: 2 } }, actor: { effects: { Quash: 1 } } }].each_with_index do |attrs, i|
            move, user, target, battle = setup_quash(id: :"MOVE#{i}", **attrs)
            assert_equal true, fails?(move, user, target, false), attrs.to_s
            assert_empty battle.messages, attrs.to_s
        end
    end

    # pbEffectAgainstTarget

    def test_effect_applies_quash_at_1_when_no_battler_has_it
        move, user, target, _battle = setup_quash
        move.pbEffectAgainstTarget(user, target)
        assert_equal [[:Quash, 1]], target.applied_effects
    end

    def test_effect_applies_quash_one_above_the_highest_over_all_battlers
        move, user, target, _battle = setup_quash(target: { effects: { Quash: 1 } }, actor: { effects: { Quash: 3 } })
        move.pbEffectAgainstTarget(user, target)
        assert_equal [[:Quash, 4]], target.applied_effects
    end

    def test_effect_displays_the_postponed_message
        move, user, target, battle = setup_quash
        move.pbEffectAgainstTarget(user, target)
        assert_equal ["Target's move was postponed!"], battle.messages
    end
end
