require_relative "../support/test_helper"

class RuntimeStubsTest < Minitest::Test
    def test_color_defaults_to_opaque
        color = Color.new(1, 2, 3)
        assert_equal [1, 2, 3, 255], [color.red, color.green, color.blue, color.alpha]
    end

    def test_color_keeps_a_given_alpha
        assert_equal 40, Color.new(1, 2, 3, 40).alpha
    end

    def test_echoln_returns_nil
        assert_nil echoln("x")
    end
end
