require_relative "../support/test_helper"
require_relative "../../.github/scripts/coverage_badge"

class CoverageBadgeTest < Minitest::Test
    def endpoint(percent)
        CoverageBadge.endpoint({ "total" => { "lines" => { "percent" => percent } } })
    end

    def test_endpoint_reports_line_percent_rounded_down
        assert_equal({ schemaVersion: 1, label: "coverage", message: "75.9%", color: "green" }, endpoint(75.99))
    end

    def test_endpoint_colours_a_threshold_with_its_own_colour
        assert_equal "brightgreen", endpoint(90.0)[:color]
    end

    def test_endpoint_colours_below_every_threshold_red
        assert_equal "red", endpoint(5.9)[:color]
    end
end
