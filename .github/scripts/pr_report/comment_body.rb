require_relative "markdown"

module PrReport
    # The PR comment: what the run's checks did, coverage of the changed lines, the whole-codebase
    # coverage figure and the lint section, cut to fit GitHub's comment limit.
    module CommentBody
        module_function

        # GitHub refuses a comment over 65,536 characters.
        LIMIT = 60_000
        STEPS = { syntax: "syntax check", tests: "tests" }.freeze
        CRITERIA = %w[line branch].freeze

        # syntax and tests are step outcomes ("success", "failure", "skipped", ...), patch is
        # {text:, exit:} from `simplecov patch`, totals is `simplecov status --json`'s criterion to
        # percent map or nil, and lint is LintReport's section.
        def build(syntax:, tests:, run_url:, patch:, totals:, lint:)
            body = <<~MARKDOWN
                ## Tests report

                #{status(syntax: syntax, tests: tests)} [Run details](#{run_url})

                ### Coverage of changed lines

                #{patch_section(patch)}
                Whole codebase, for reference: #{totals_line(totals)}.

                ### Lint

                #{lint}
            MARKDOWN
            note = "_Cut to fit GitHub's comment limit. The full report is in [the run](#{run_url})._"
            Markdown.cut_chars(body, limit: LIMIT, note: note)
        end

        def status(outcomes)
            failed = outcomes.reject { |_step, outcome| outcome == "success" }
            return "Syntax check and tests passed." if failed.empty?

            named = failed.map { |step, outcome| "#{STEPS.fetch(step)}: #{outcome}" }.join(", ")
            "#{named[0].upcase}#{named[1..]}. The coverage figures may come from a partial run."
        end

        def patch_section(patch)
            block = Markdown.code_block(patch[:text])
            patch[:exit].zero? ? block : "`simplecov patch` exited #{patch[:exit]}:\n\n#{block}"
        end

        def totals_line(totals)
            figures = CRITERIA.filter_map do |criterion|
                percent = totals&.[](criterion)
                format("%<name>s %<percent>.2f%%", name: criterion, percent: percent) if percent
            end
            figures.empty? ? "unavailable" : figures.join(", ")
        end
    end
end
