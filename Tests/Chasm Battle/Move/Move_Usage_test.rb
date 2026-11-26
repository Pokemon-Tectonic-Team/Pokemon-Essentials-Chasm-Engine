require_relative "../../support/test_helper"

class MoveUsageTest < Minitest::Test
    # A target at index 1 with the given choice; the move's battle holds choices for both indexes.
    def setup_target(choice, id: :TESTMOVE, **battler)
        target = TestBattler.new(index: 1, name: "Target", **battler)
        battle = TestBattle.new(battlers: [target], choices: [[:UseMove, 0, :chosen_move], choice])
        [make_move(battle: battle, id: id), target, battle]
    end

    # pbMoveFailedTargetAlreadyMoved?

    def test_a_target_that_chose_a_move_and_has_not_moved_passes
        move, target, battle = setup_target([:UseMove, 0, :chosen_move])
        assert_equal false, move.pbMoveFailedTargetAlreadyMoved?(target)
        assert_empty battle.messages
    end

    def test_a_target_that_chose_shift_and_has_not_moved_passes
        move, target, battle = setup_target([:Shift, 0, nil])
        assert_equal false, move.pbMoveFailedTargetAlreadyMoved?(target)
        assert_empty battle.messages
    end

    def test_a_target_that_chose_something_else_fails_with_a_message
        [:SwitchOut, :UseItem, :Run].each do |choice|
            move, target, battle = setup_target([choice, 0, nil], id: choice)
            assert_equal true, move.pbMoveFailedTargetAlreadyMoved?(target), choice.to_s
            assert_equal ["But it failed, since Target didn't choose to use a move!"], battle.messages, choice.to_s
        end
    end

    def test_a_target_that_already_moved_fails_with_a_message
        move, target, battle = setup_target([:UseMove, 0, :chosen_move], moved: true)
        assert_equal true, move.pbMoveFailedTargetAlreadyMoved?(target)
        assert_equal ["But it failed, since Target already moved this turn!"], battle.messages
    end

    def test_a_target_that_already_moved_after_choosing_shift_fails
        move, target, battle = setup_target([:Shift, 0, nil], moved: true)
        assert_equal true, move.pbMoveFailedTargetAlreadyMoved?(target)
        assert_equal ["But it failed, since Target already moved this turn!"], battle.messages
    end

    def test_a_target_that_chose_something_else_and_already_moved_gets_the_choice_message_only
        move, target, battle = setup_target([:SwitchOut, 2, nil], moved: true)
        assert_equal true, move.pbMoveFailedTargetAlreadyMoved?(target)
        assert_equal ["But it failed, since Target didn't choose to use a move!"], battle.messages
    end

    def test_failures_display_nothing_when_show_message_is_false
        [[[:SwitchOut, 2, nil], {}], [[:UseMove, 0, :chosen_move], { moved: true }]].each_with_index do |(choice, battler), i|
            move, target, battle = setup_target(choice, id: :"MOVE#{i}", **battler)
            assert_equal true, move.pbMoveFailedTargetAlreadyMoved?(target, false), choice.to_s
            assert_empty battle.messages, choice.to_s
        end
    end

    def test_a_passing_target_returns_false_when_show_message_is_false
        move, target, battle = setup_target([:UseMove, 0, :chosen_move])
        assert_equal false, move.pbMoveFailedTargetAlreadyMoved?(target, false)
        assert_empty battle.messages
    end
end
