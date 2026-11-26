require "set"

module RuboCop
    module Cop
        module Chasm
            # Flags tabs after a line's indentation, which Layout/IndentationStyle doesn't check.
            # RuboCop counts a tab as one column, so tab-aligned code looks unaligned to
            # Layout/ExtraSpacing, whose auto-correct then strips the alignment. Auto-correct
            # replaces each run of whitespace holding a tab with the spaces it spans at a tab
            # width of 4, so the code looks the same in an editor showing tabs 4 wide. Tabs
            # inside strings, symbols, regexps and heredocs are left alone.
            #
            #     # bad
            #     @is_spike<TAB>= hash[:is_spike]
            #
            #     # good
            #     @is_spike   = hash[:is_spike]
            class InlineTab < Base
                include RangeHelp
                extend AutoCorrector

                MSG = "Use spaces, not tabs, after indentation.".freeze
                TAB_WIDTH = 4
                RUN = /[ \t]*\t[ \t]*/

                def on_new_investigation
                    literals = literal_ranges
                    processed_source.lines.each.with_index(1) do |line, number|
                        check_line(line, number, literals)
                    end
                end

                private

                def check_line(line, number, literals)
                    indentation = line[/\A[ \t]*/].length
                    line.to_enum(:scan, RUN).each do
                        match = Regexp.last_match
                        next if match.begin(0) < indentation

                        range = source_range(processed_source.buffer, number, match.begin(0)...match.end(0))
                        next if literals.any? { |literal| literal.contains?(range) }

                        add_offense(range) do |corrector|
                            corrector.replace(range, " " * spaces_spanned(line, match.begin(0), match.end(0)))
                        end
                    end
                end

                # The spaces the whitespace from column first up to last fills, tabs stopping at
                # every multiple of TAB_WIDTH.
                def spaces_spanned(line, first, last)
                    visual_column(line, last) - visual_column(line, first)
                end

                def visual_column(line, index)
                    line[0...index].each_char.reduce(0) do |column, char|
                        char == "\t" ? column + TAB_WIDTH - (column % TAB_WIDTH) : column + 1
                    end
                end

                def literal_ranges
                    ranges = Set.new
                    processed_source.ast&.each_node(:str, :dstr, :xstr, :sym, :dsym, :regexp) do |node|
                        loc = node.location
                        if node.respond_to?(:heredoc?) && node.heredoc?
                            ranges << loc.heredoc_body
                        elsif loc.respond_to?(:begin) && loc.begin
                            ranges << loc.expression
                        end
                    end
                    ranges
                end
            end
        end
    end
end
