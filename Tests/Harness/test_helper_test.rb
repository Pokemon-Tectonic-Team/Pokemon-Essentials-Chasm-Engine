require_relative "../support/test_helper"

class TestHelperTest < Minitest::Test
    def test_ruby_utilities_is_the_real_one
        refute " ".blank?
        assert "".blank?
    end

    def test_validation_is_the_real_one
        assert_raises(ArgumentError) { validate(1 => String) }
    end

    def test_intl_messages_is_the_real_one
        assert_equal 32, MessageTypes::BattleEffects
    end

    def test_pbdebug_log_prints_nothing_while_debug_is_false
        out, err = capture_io { assert_nil PBDebug.log("x") }

        assert_empty out
        assert_empty err
    end

    def test_event_system_is_the_real_one
        assert_kind_of Class, Event
        assert_kind_of Class, HandlerHash2
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
