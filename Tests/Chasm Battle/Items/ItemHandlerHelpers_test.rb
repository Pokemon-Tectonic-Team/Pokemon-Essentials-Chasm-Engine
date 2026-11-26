require_relative "../../support/test_helper"

class ItemHandlerHelpersTest < Minitest::Test
    def mults
        { base_damage_multiplier: 1.0 }
    end

    def test_a_matching_type_boosts_by_a_fifth_and_learns_the_item_once
        user = TestBattler.new
        m = mults
        typeBoostingItem(:CHARCOAL, user, :FIRE, m, [:FIRE], false)
        assert_in_delta 1.2, m[:base_damage_multiplier]
        assert_equal [:CHARCOAL], user.learned_items
    end

    def test_no_matching_type_changes_nothing_and_learns_nothing
        user = TestBattler.new
        m = mults
        typeBoostingItem(:CHARCOAL, user, :FIRE, m, [:WATER], false)
        assert_equal 1.0, m[:base_damage_multiplier]
        assert_empty user.learned_items
    end

    def test_ai_check_boosts_without_learning
        user = TestBattler.new
        m = mults
        typeBoostingItem(:CHARCOAL, user, :FIRE, m, [:FIRE], true)
        assert_in_delta 1.2, m[:base_damage_multiplier]
        assert_empty user.learned_items
    end

    def test_the_second_of_two_types_matching_counts
        user = TestBattler.new
        m = mults
        typeBoostingItem(:CHARCOAL, user, :FIRE, m, [:WATER, :FIRE], false)
        assert_in_delta 1.2, m[:base_damage_multiplier]
        assert_equal [:CHARCOAL], user.learned_items
    end

    def test_the_boost_multiplies_the_existing_multiplier
        m = { base_damage_multiplier: 2.0 }
        typeBoostingItem(:CHARCOAL, TestBattler.new, :FIRE, m, [:FIRE], true)
        assert_in_delta 2.4, m[:base_damage_multiplier]
    end
end
