require_relative "../support/test_helper"

class TestResetTest < Minitest::Test
    def test_before_setup_puts_back_a_changed_stat_record
        original = GameData::Stat::DATA[:SPECIAL_ATTACK]
        assert_equal "Special Attack", original.real_name
        GameData::Stat::DATA[:SPECIAL_ATTACK] = GameData::Stat.new({ id: :SPECIAL_ATTACK, name: "Changed" })

        before_setup

        assert_same original, GameData::Stat::DATA[:SPECIAL_ATTACK]
    end

    def test_before_setup_removes_a_record_added_since
        GameData::Stat::DATA[:TEST_RESET_EXTRA] = :extra

        before_setup

        refute GameData::Stat::DATA.key?(:TEST_RESET_EXTRA)
    end
end
