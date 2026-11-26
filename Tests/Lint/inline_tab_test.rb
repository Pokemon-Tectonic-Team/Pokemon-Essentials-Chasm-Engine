require_relative "../support/test_helper"
require "json"
require "open3"
require "tmpdir"

# RuboCop runs in a subprocess, through the repo's .rubocop.yml: loading it here would replace the
# game's String#blank? with its own for every test.
class InlineTabTest < Minitest::Test
    REPO = File.expand_path("../..", __dir__)

    SOURCES = {
        after_indentation: "    @is_spike\t= 1\n",
        tab_width_4: "@is_screen\t\t\t\t= 1\n@is_spike\t\t\t\t= 2\n",
        tab_in_indentation: "\t@a\t= 1\n",
        mixed_run: "@expire_proc \t\t\t= 1\n",
        two_runs: "x\t= 1\t# note\n",
        indentation_only: "if true\n\tx = 1\nend\n",
        no_tabs: "x   = 1\n",
        strings: "x = \"a\tb\"\ny = 'a\tb'\n",
        interpolated_symbol_regexp: "x = \"\#{1}\ta\"\ny = :\"a\tb\"\nz = /a\tb/\n",
        heredoc: "x = <<~TEXT\n    a\tb\nTEXT\n",
        after_string: "x = \"a\"\t# note\n"
    }.freeze

    # Each source's offenses, as [line, column] pairs counted from 1, and its auto-corrected text,
    # from one RuboCop run over all of them.
    def self.results
        @results ||= Dir.mktmpdir do |dir|
            SOURCES.each { |name, source| File.binwrite(File.join(dir, "#{name}.rb"), source) }
            command = ["bundle", "exec", "rubocop", "--config", File.join(REPO, ".rubocop.yml"), "--only", "Chasm/InlineTab",
                       "--autocorrect", "--cache", "false", "--format", "json", dir]
            stdout, stderr, status = Open3.capture3(*command, chdir: REPO)
            raise "RuboCop exited #{status.exitstatus}: #{stderr}" if status.exitstatus > 1

            JSON.parse(stdout)["files"].to_h do |file|
                name = File.basename(file["path"], ".rb").to_sym
                offenses = file["offenses"].map { |offense| [offense["location"]["line"], offense["location"]["column"]] }
                # Text mode, since RuboCop writes corrections with the platform's line endings
                [name, { offenses: offenses, corrected: File.read(File.join(dir, "#{name}.rb")) }]
            end
        end
    end

    def offenses(name) = self.class.results.fetch(name)[:offenses]
    def corrected(name) = self.class.results.fetch(name)[:corrected]

    def test_flags_a_tab_after_indentation
        assert_equal [[1, 14]], offenses(:after_indentation)
        assert_equal "    @is_spike   = 1\n", corrected(:after_indentation)
    end

    def test_correction_keeps_the_column_at_tab_width_4
        assert_equal "@is_screen#{' ' * 14}= 1\n@is_spike#{' ' * 15}= 2\n", corrected(:tab_width_4)
    end

    def test_counts_tabs_in_the_indentation_towards_the_column
        assert_equal "\t@a  = 1\n", corrected(:tab_in_indentation)
    end

    def test_replaces_a_run_mixing_spaces_and_tabs_as_one_offense
        assert_equal [[1, 13]], offenses(:mixed_run)
        assert_equal "@expire_proc#{' ' * 12}= 1\n", corrected(:mixed_run)
    end

    def test_flags_each_run_on_a_line
        assert_equal [[1, 2], [1, 6]], offenses(:two_runs)
        assert_equal "x   = 1 # note\n", corrected(:two_runs)
    end

    def test_leaves_indentation_to_indentation_style
        assert_empty offenses(:indentation_only)
    end

    def test_leaves_a_line_without_tabs
        assert_empty offenses(:no_tabs)
    end

    def test_leaves_tabs_in_strings
        assert_empty offenses(:strings)
    end

    def test_leaves_tabs_in_interpolated_strings_symbols_and_regexps
        assert_empty offenses(:interpolated_symbol_regexp)
    end

    def test_leaves_tabs_in_heredoc_bodies
        assert_empty offenses(:heredoc)
    end

    def test_flags_a_tab_after_a_string
        assert_equal [[1, 8]], offenses(:after_string)
    end
end
