require_relative "markdown"

module PrReport
    # The comment's lint section, from RuboCop's outputs: the full Markdown report when it is
    # short, otherwise a summary of counts, the cops with one offense and the warnings and worse.
    module LintReport
        module_function

        LIMIT = 200
        FILE_HEADING = "### ".freeze
        TITLE = /\A# RuboCop Inspection Report\n\n/
        WHERE_FULL = "The full report is in this run's job summary.".freeze

        def summarise?(full)
            full.lines.length > LIMIT
        end

        # The report without RuboCop's title, which would outrank the comment's own headings.
        def full_section(full)
            full.sub(TITLE, "")
        end

        # counts is the `--format offenses` output, unique the `--only` Markdown run (nil when no
        # cop has one offense) and critical the warnings-and-worse Markdown run.
        def summary(full_lines:, counts:, unique:, critical:)
            parts = []
            parts << "#### Cops with one offense\n\n#{offenses(unique)}" if unique
            parts << "#### Warnings and worse\n\n#{offenses(critical)}"
            cut_note = "_Cut at #{LIMIT} lines. #{WHERE_FULL}_"
            detail = Markdown.cut_lines(parts.join("\n"), limit: LIMIT, note: cut_note)
            "The full RuboCop report is #{full_lines} lines, over the #{LIMIT}-line limit, so this " \
                "is a summary. #{WHERE_FULL}\n\n#{Markdown.code_block(counts.sub(/\A\n+/, ''))}\n#{detail}"
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
