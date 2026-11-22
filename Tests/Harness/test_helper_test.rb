require_relative "../support/test_helper"

class TestHelperTest < Minitest::Test
    def test_core_scripts_are_the_real_ones
        refute " ".blank?
        assert "".blank?
        assert_raises(ArgumentError) { validate(1 => String) }
        assert_equal 32, MessageTypes::BattleEffects
    end

    def test_static_stat_status_and_target_records_are_present
        assert_equal "Attack", GameData::Stat::DATA[:ATTACK].real_name
        assert_equal :SLEEP, GameData::Status::DATA[:SLEEP].id
        assert GameData::Target::DATA.key?(:NearAlly)
    end

    def test_no_type_is_registered
        assert_empty GameData::Type::DATA
    end

    def test_requiring_the_helper_again_returns_false
        assert_equal false, require_relative("../support/test_helper")
    end
end
