require_relative "../support/test_helper"
require "json"
require "open3"
require "tmpdir"

# RuboCop runs in a subprocess, through the repo's .rubocop.yml: loading it here would replace the
# game's String#blank? with its own for every test.
class MutableConstantTest < Minitest::Test
    REPO = File.expand_path("../..", __dir__)

    SOURCES = {
        registry: "class A\n    DATA = {}\nend\n",
        or_assigned_registry: "DATA ||= {}\n",
        namespaced_registry: "A::DATA = {}\n",
        multiple_assignment: "DATA, X = {}, 1\n",
        filled_data: "DATA = { a: 1 }\n",
        other_hash: "TABLE = {}\n",
        string: "DATA_FILENAME = \"a.dat\"\n",
        frozen: "TABLE = {}.freeze\n"
    }.freeze

    # Each source's offenses, as [line, column] pairs counted from 1, from one RuboCop run over all
    # of them.
    def self.results
        @results ||= Dir.mktmpdir do |dir|
            SOURCES.each { |name, source| File.binwrite(File.join(dir, "#{name}.rb"), source) }
            command = ["bundle", "exec", "rubocop", "--config", File.join(REPO, ".rubocop.yml"), "--only", "Chasm/MutableConstant",
                       "--cache", "false", "--format", "json", dir]
            stdout, stderr, status = Open3.capture3(*command, chdir: REPO)
            raise "RuboCop exited #{status.exitstatus}: #{stderr}" if status.exitstatus > 1

            JSON.parse(stdout)["files"].to_h do |file|
                name = File.basename(file["path"], ".rb").to_sym
                [name, file["offenses"].map { |offense| [offense["location"]["line"], offense["location"]["column"]] }]
            end
        end
    end

    def offenses(name) = self.class.results.fetch(name)

    def test_leaves_an_empty_data_registry
        assert_empty offenses(:registry)
    end

    def test_leaves_an_or_assigned_registry
        assert_empty offenses(:or_assigned_registry)
    end

    def test_leaves_a_namespaced_registry
        assert_empty offenses(:namespaced_registry)
    end

    def test_handles_a_multiple_assignment
        assert_empty offenses(:multiple_assignment)
    end

    def test_flags_data_with_contents
        assert_equal [[1, 8]], offenses(:filled_data)
    end

    def test_flags_an_empty_hash_under_another_name
        assert_equal [[1, 9]], offenses(:other_hash)
    end

    def test_flags_a_string
        assert_equal [[1, 17]], offenses(:string)
    end

    def test_leaves_a_frozen_hash
        assert_empty offenses(:frozen)
    end
end
