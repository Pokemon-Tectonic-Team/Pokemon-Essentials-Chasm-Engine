module PrReport
    # The Markdown pieces the report is built from, and cutting it to size without leaving a code
    # block open.
    module Markdown
        module_function

        FENCE = /\A\s*```/
        # Most characters finish adds besides the note: a newline, a closing fence and the blank
        # line and newline around the note.
        FINISH_OVERHEAD = "\n```\n\n\n".length

        def code_block(text)
            "```text\n#{text.chomp}\n```\n"
        end

        # text cut to at most limit lines, followed by note, when it is longer.
        def cut_lines(text, limit:, note:)
            lines = text.lines
            return text if lines.length <= limit

            finish(lines.first(limit).join, note)
        end

        # text cut at a line end to at most limit characters, note included, when it is longer.
        def cut_chars(text, limit:, note:)
            return text if text.length <= limit

            kept = text[0, limit - note.length - FINISH_OVERHEAD]
            line_end = kept.rindex("\n")
            finish(line_end ? kept[0..line_end] : kept, note)
        end

        def finish(kept, note)
            kept += "\n" unless kept.end_with?("\n")
            kept += "```\n" if kept.lines.count { |line| FENCE.match?(line) }.odd?
            "#{kept}\n#{note}\n"
        end
    end
end
