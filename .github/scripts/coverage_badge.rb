# Writes the shields.io endpoint JSON for the whole-codebase line coverage badge. Run from the
# repository root after the suite has written coverage/coverage.json:
#
#     ruby .github/scripts/coverage_badge.rb <output file>
require "json"

module CoverageBadge
    module_function

    # Lowest percent for each colour, highest first.
    COLOURS = { 90 => "brightgreen", 75 => "green", 60 => "yellowgreen", 40 => "yellow", 20 => "orange" }.freeze

    # SimpleCov's coverage.json, parsed, to the badge's endpoint JSON.
    def endpoint(coverage)
        percent = coverage.fetch("total").fetch("lines").fetch("percent")
        colour = COLOURS.find { |minimum, _colour| percent >= minimum }&.last || "red"
        { schemaVersion: 1, label: "coverage", message: format("%.1f%%", percent.floor(1)), color: colour }
    end
end

if $PROGRAM_NAME == __FILE__
    coverage = JSON.parse(File.read("coverage/coverage.json"))
    File.write(ARGV.fetch(0), JSON.generate(CoverageBadge.endpoint(coverage)))
end
