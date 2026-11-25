require_relative "error"

module PrReport
    # Reads RuboCop's `--format offenses` output: one `<count>  <Cop/Name>` line per cop, with
    # ` [Safe Correctable]`, ` [Unsafe Correctable]` or nothing after it, then `--` and a total.
    module OffenseCounts
        module_function

        ROW = /\A(\d+)\s+(\S+)(?: \[(Safe|Unsafe) Correctable\])?\z/
        LABEL = / \[(?:Safe|Unsafe) Correctable\]$/
        TOTAL = /\A\d+\s+Total in /
        SEPARATOR = "--".freeze

        # Rows of {count:, cop:, correctable: :safe | :unsafe | nil}, in RuboCop's order.
        def parse(text)
            text.each_line.filter_map do |raw|
                line = raw.strip
                next if line.empty? || line == SEPARATOR || TOTAL.match?(line)

                match = ROW.match(line) or raise Error, "unexpected line in RuboCop's offense counts: #{line}"
                { count: Integer(match[1]), cop: match[2], correctable: match[3]&.downcase&.to_sym }
            end
        end

        # The output without its surrounding blank lines and correctable labels.
        def plain(text)
            text.sub(/\A\n+/, "").sub(/\n+\z/, "\n").gsub(LABEL, "")
        end

        # Names of the cops a summary details: those with exactly one offense, unless RuboCop marks
        # them safe-correctable.
        def detailed(rows)
            rows.select { |row| row[:count] == 1 && row[:correctable] != :safe }.map { |row| row[:cop] }
        end

        # How many offenses belong to cops RuboCop marks safe-correctable.
        def safe_correctable(rows)
            rows.sum { |row| row[:correctable] == :safe ? row[:count] : 0 }
        end
    end
end
