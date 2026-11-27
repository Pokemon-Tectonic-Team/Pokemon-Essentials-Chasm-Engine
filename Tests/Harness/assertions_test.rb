require_relative "../support/test_helper"

class AssertionsTest < Minitest::Test
    Record = Struct.new(:id, :flag, :list)

    def test_assert_attributes_passes_when_every_reader_matches
        assert_attributes({ id: :FIRE, list: [] }, Record.new(:FIRE, true, []))
    end

    def test_assert_attributes_failure_names_every_reader_that_differs
        error = assert_raises(Minitest::Assertion) do
            assert_attributes({ id: :FIRE, flag: true, list: [] }, Record.new(:WATER, true, [1]))
        end

        assert_match(/:WATER.*\[1\]/m, error.message)
    end

    def test_assert_attributes_compares_with_equality_not_truthiness
        assert_raises(Minitest::Assertion) { assert_attributes({ flag: true }, Record.new(:FIRE, 1, [])) }
    end

    def test_assert_attributes_failure_carries_the_message
        error = assert_raises(Minitest::Assertion) { assert_attributes({ id: :FIRE }, Record.new(:WATER), "the record") }

        assert_match(/\Athe record/, error.message)
    end
end
