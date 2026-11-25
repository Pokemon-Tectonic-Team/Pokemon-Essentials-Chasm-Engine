require_relative "error"

module PrReport
    # Reads RuboCop's `--format offenses` output: one `<count>  <Cop/Name>` line per cop, with
    # ` [Safe Correctable]`, ` [Unsafe Correctable]` or nothing after it, then `--` and a total.
    module OffenseCounts
        module_function

        ROW = /\A(\d+)\s+(\S+)(?: \[(Safe|Unsafe) Correctable\])?\z/
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

        # Names of the cops with exactly one offense.
        def once(rows)
            rows.select { |row| row[:count] == 1 }.map { |row| row[:cop] }
        end
    end
end
