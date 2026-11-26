require_relative "markdown"
require_relative "offense_counts"

module PrReport
    # The comment's lint section, from RuboCop's outputs: the full Markdown report when it is
    # short, otherwise a summary of the counts per cop and the offenses of the detailed cops.
    module LintReport
        module_function

        LIMIT = 200
        FILE_HEADING = "### ".freeze
        TITLE = /\A# RuboCop Inspection Report\n\n/
        CUT_NOTE = "_Cut at #{LIMIT} lines. The full report is in this run's job summary._".freeze

        def summarise?(full)
            full.lines.length > LIMIT
        end

        # The report without RuboCop's title, which would outrank the comment's own headings.
        def full_section(full)
            full.sub(TITLE, "")
        end

        # counts is the `--format offenses` output, safe the number of its offenses whose cops are
        # safe-correctable, and unique the `--only` Markdown run of the detailed cops (nil when
        # there are none).
        def summary(counts:, safe:, unique:)
            parts = [Markdown.code_block(OffenseCounts.plain(counts))]
            parts << "...and #{safe} safely auto-correctable offenses.\n" if safe.positive?
            parts << Markdown.cut_lines(offenses(unique), limit: LIMIT, note: CUT_NOTE) if unique
            parts.join("\n")
        end

        def none_changed
            "No Ruby files changed.\n"
        end

        def error(message)
            "RuboCop couldn't run:\n\n#{Markdown.code_block(headline(message))}"
        end

        # An error's first line: the rest of RuboCop's stderr is a stack trace.
        def headline(message)
            message.lines.first.to_s.chomp
        end

        # A Markdown report from its first file heading on, leaving out RuboCop's title and totals.
        def offenses(markdown)
            lines = markdown.lines
            first = lines.index { |line| line.start_with?(FILE_HEADING) }
            first ? lines[first..].join : "None.\n"
        end
    end
end
