require_relative "../support/test_helper"

class TestBattleTest < Minitest::Test
    def test_each_battler_yields_the_given_battlers_in_order
        first = TestBattler.new(index: 0)
        second = TestBattler.new(index: 1)
        battle = TestBattle.new(battlers: [first, second])

        yielded = []
        battle.eachBattler { |battler| yielded << battler }

        assert_equal 2, yielded.length
        assert_same first, yielded[0]
        assert_same second, yielded[1]
    end

    def test_each_battler_yields_nothing_by_default
        yielded = []
        TestBattle.new.eachBattler { |battler| yielded << battler }

        assert_empty yielded
    end

    def test_priority_is_the_priority_given
        first = TestBattler.new
        second = TestBattler.new
        battle = TestBattle.new(battlers: [first, second], priority: [second, first])

        assert_equal [second, first], battle.pbPriority
    end

    def test_priority_is_the_battlers_when_none_is_given
        first = TestBattler.new
        second = TestBattler.new
        battle = TestBattle.new(battlers: [first, second])

        assert_equal [first, second], battle.pbPriority
    end

    def test_choices_are_what_was_given
        choices = [[:move, 0], [:switch, 1]]

        assert_same choices, TestBattle.new(choices: choices).choices
    end

    def test_choices_default_to_none
        assert_empty TestBattle.new.choices
    end

    def test_display_records_messages_in_order
        battle = TestBattle.new
        battle.pbDisplay("one")
        battle.pbDisplay("two")

        assert_equal %w[one two], battle.messages
    end
end
