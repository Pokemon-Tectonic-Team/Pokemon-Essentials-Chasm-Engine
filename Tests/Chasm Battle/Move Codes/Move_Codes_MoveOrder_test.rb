require_relative "../../support/test_helper"

class MoveOrderMoveCodesTest < Minitest::Test
    USE_MOVE = [:UseMove, 0, :chosen_move].freeze

    # A battle of an actor at index 0 and a target at index 1, the target not last in priority.
    # Overrides: choices (the target's is choices[1]), target / actor battler attributes, priority.
    def setup_quash(target_choice: USE_MOVE, target: {}, actor: {}, last: :actor, id: :TESTMOVE)
        actor_battler = TestBattler.new(index: 0, effects: { Quash: 0 }, name: "Actor", **actor)
        target_battler = TestBattler.new(index: 1, effects: { Quash: 0 }, name: "Target", **target)
        priority = last == :actor ? [target_battler, actor_battler] : [actor_battler, target_battler]
        battle = TestBattle.new(battlers: [actor_battler, target_battler], priority: priority,
                                choices: [USE_MOVE, target_choice])
        move = make_move(PokeBattle_Move_TargetActsLast, battle: battle, id: id)
        [move, actor_battler, target_battler, battle]
    end

    # The inherited pbMoveFailedTargetAlreadyMoved? answers already_moved, or calls it if callable.
    def fails?(move, user, target, show_message = true, already_moved: false)
        move.stub(:pbMoveFailedTargetAlreadyMoved?, already_moved) do
            move.pbFailsAgainstTarget?(user, target, show_message)
        end
    end

    # pbFailsAgainstTarget?

    def test_an_ordinary_target_does_not_fail
        move, user, target, battle = setup_quash

        refute fails?(move, user, target)
        assert_empty battle.messages
    end

    def test_the_inherited_already_moved_check_is_asked_about_the_target
        move, user, target, _battle = setup_quash
        calls = []
        record_call = lambda do |*args|
            calls.push(args)
            false
        end
        fails?(move, user, target, false, already_moved: record_call)

        assert_equal [[target, false]], calls
    end

    def test_a_target_failing_the_inherited_already_moved_check_fails
        move, user, target, battle = setup_quash

        assert fails?(move, user, target, already_moved: true)
        assert_empty battle.messages
    end

    def test_a_target_with_no_chosen_move_fails
        move, user, target, battle = setup_quash(target_choice: [:UseMove, 0, nil])

        assert fails?(move, user, target)
        assert_equal ["But it failed, since Target isn't using a move this turn!"], battle.messages
    end

    def test_a_target_holding_the_highest_quash_fails
        move, user, target, battle = setup_quash(target: { effects: { Quash: 2 } }, actor: { effects: { Quash: 1 } })

        assert fails?(move, user, target)
        assert_equal ["But it failed!"], battle.messages
    end

    def test_a_target_holding_a_lower_quash_does_not_fail
        move, user, target, battle = setup_quash(target: { effects: { Quash: 1 } }, actor: { effects: { Quash: 2 } })

        refute fails?(move, user, target)
        assert_empty battle.messages
    end

    def test_a_target_last_in_priority_with_no_quash_fails
        move, user, target, battle = setup_quash(last: :target)

        assert fails?(move, user, target)
        assert_equal ["But it failed, since Target was already forced to move last!"], battle.messages
    end

    def test_a_target_last_in_priority_does_not_fail_while_a_quash_is_active
        move, user, target, battle = setup_quash(last: :target, actor: { effects: { Quash: 1 } })

        refute fails?(move, user, target)
        assert_empty battle.messages
    end

    def test_no_failure_displays_without_show_message
        [{ target_choice: [:UseMove, 0, nil] }, { last: :target },
         { target: { effects: { Quash: 2 } }, actor: { effects: { Quash: 1 } } }].each_with_index do |attrs, i|
            move, user, target, battle = setup_quash(id: :"MOVE#{i}", **attrs)

            assert fails?(move, user, target, false), "attributes #{attrs}"
            assert_empty battle.messages, "attributes #{attrs}"
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
