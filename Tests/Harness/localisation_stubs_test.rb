require_relative "../support/test_helper"

class LocalisationStubsTest < Minitest::Test
    def test_intl_substitutes_numbered_placeholders
        assert_equal "b and a", _INTL("{2} and {1}", "a", "b")
    end

    def test_intl_substitutes_every_occurrence_of_a_repeated_placeholder
        assert_equal "x-x-y", _INTL("{1}-{1}-{2}", "x", "y")
    end

    def test_intl_inserts_an_argument_with_a_backslash_sequence_literally
        assert_equal "a\\1b", _INTL("a{1}b", "\\1")
    end

    def test_intl_converts_non_string_arguments_with_to_s
        assert_equal "3 moves", _INTL("{1} moves", 3)
    end

    def test_intl_without_placeholders_returns_a_copy_of_the_text
        text = "plain"
        result = _INTL(text)

        assert_equal "plain", result
        refute_same text, result
    end

    def test_intl_substitutes_one_argument_at_a_time_as_core_does
        assert_equal "b b", _INTL("{1} {2}", "{2}", "b")
    end

    def test_get_message_returns_the_real_name_of_the_type_with_that_number
        GameData::Type.register({ id: :LOCALISATIONTEST, id_number: 77, name: "Localised" })
        GameData::Type.register({ id: :LOCALISATIONOTHER, id_number: 78, name: "Other" })
        assert_equal "Localised", pbGetMessage(MessageTypes::Types, 77)
        assert_equal "Other", pbGetMessage(MessageTypes::Types, 78)
    end

    def test_get_message_returns_an_empty_string_when_no_type_has_that_number
        assert_equal "", pbGetMessage(MessageTypes::Types, 77)
    end

    def test_get_message_raises_for_another_message_type
        assert_raises(HarnessError) { pbGetMessage(MessageTypes::Abilities, 1) }
    end

    def test_get_message_from_hash_returns_the_text
        assert_equal "the text", pbGetMessageFromHash(MessageTypes::Abilities, "the text")
    end
end
