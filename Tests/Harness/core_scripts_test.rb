require_relative "../support/test_helper"
require "tmpdir"
require "zlib"

class CoreScriptsTest < Minitest::Test
    def setup
        $core_scripts_test_log = []
    end

    def teardown
        $core_scripts_test_log = nil
    end

    def deflated(code)
        Zlib::Deflate.deflate(code)
    end

    # Writes the dumped archive to a tmp file and yields its path.
    def with_archive(dumped)
        Dir.mktmpdir("core scripts") do |dir|
            path = File.join(dir, "Scripts.rxdata")
            File.binwrite(path, dumped)
            yield path
        end
    end

    def with_entries(entries, &)
        with_archive(Marshal.dump(entries), &)
    end

    def logging_archive
        [
            [1, "First", deflated('$core_scripts_test_log << "first"')],
            [2, "Second", deflated('$core_scripts_test_log << "second"')],
            [3, "Third", deflated('$core_scripts_test_log << "third"')]
        ]
    end

    def test_entries_are_name_and_code_pairs_in_archive_order_with_code_inflated
        with_entries([[9, "Zed", deflated("zed = 1")], [4, "Alpha", deflated("alpha = 2")]]) do |path|
            assert_equal [["Zed", "zed = 1"], ["Alpha", "alpha = 2"]], CoreScripts.entries(path)
        end
    end

    def test_entries_decode_code_as_utf_8
        with_entries([[1, "Accent", deflated("# café".b)]]) do |path|
            code = CoreScripts.entries(path).first.last
            assert_equal Encoding::UTF_8, code.encoding
            assert_equal "# café", code
        end
    end

    def test_entries_refuse_a_file_that_is_not_an_array
        with_archive(Marshal.dump({ 1 => "x" })) do |path|
            assert_raises(HarnessError) { CoreScripts.entries(path) }
        end
    end

    def test_entries_refuse_an_entry_with_two_elements
        with_entries([[1, "A", deflated("1")], [2, deflated("2")]]) do |path|
            assert_raises(HarnessError) { CoreScripts.entries(path) }
        end
    end

    def test_entries_refuse_an_entry_with_four_elements
        with_entries([[1, "A", deflated("1"), :extra]]) do |path|
            error = assert_raises(HarnessError) { CoreScripts.entries(path) }
            assert_includes error.message, "not [id, name, code]"
        end
    end

    def test_entries_refuse_an_entry_whose_name_is_not_a_string
        with_entries([[1, :A, deflated("1")]]) do |path|
            assert_raises(HarnessError) { CoreScripts.entries(path) }
        end
    end

    def test_entries_refuse_an_entry_whose_code_is_not_a_string
        with_entries([[1, "A", 5]]) do |path|
            error = assert_raises(HarnessError) { CoreScripts.entries(path) }
            assert_includes error.message, "not [id, name, code]"
        end
    end

    def test_entries_refuse_a_file_that_will_not_unmarshal
        with_archive("these bytes are not a marshal dump") do |path|
            assert_raises(HarnessError) { CoreScripts.entries(path) }
        end
    end

    def test_entries_refuse_code_that_will_not_inflate
        with_entries([[1, "A", "not deflated at all"]]) do |path|
            assert_raises(HarnessError) { CoreScripts.entries(path) }
        end
    end

    def test_load_evaluates_only_the_named_entries_in_archive_order
        with_entries(logging_archive) do |path|
            CoreScripts.load(path, %w[Third First])
            assert_equal %w[first third], $core_scripts_test_log
        end
    end

    def test_load_evaluates_each_entry_under_its_core_file_name
        with_entries([[1, "First", deflated("$core_scripts_test_log << __FILE__")]]) do |path|
            CoreScripts.load(path, ["First"])
            assert_equal ["[core] First"], $core_scripts_test_log
        end
    end

    def test_load_evaluates_at_top_level
        with_entries([[1, "Definer", deflated("def core_scripts_test_top_level_method = 42")]]) do |path|
            CoreScripts.load(path, ["Definer"])
            assert_equal 42, Object.new.send(:core_scripts_test_top_level_method)
        end
    ensure
        Object.send(:remove_method, :core_scripts_test_top_level_method) if
            Object.private_method_defined?(:core_scripts_test_top_level_method)
    end

    def test_load_refuses_a_name_not_in_the_archive_before_evaluating_anything
        with_entries(logging_archive) do |path|
            assert_raises(HarnessError) { CoreScripts.load(path, %w[First Missing]) }
            assert_empty $core_scripts_test_log
        end
    end

    def test_load_refuses_a_name_matching_more_than_one_entry_before_evaluating_anything
        entries = logging_archive + [[4, "First", deflated('$core_scripts_test_log << "again"')]]
        with_entries(entries) do |path|
            assert_raises(HarnessError) { CoreScripts.load(path, %w[Second First]) }
            assert_empty $core_scripts_test_log
        end
    end
end
