# The one file every test requires. Sets up gems and coverage, loads the core scripts and plugin
# files tests use and the battle fakes over them, and resets game state before every test.
repo_root = File.expand_path("../..", __dir__)

ENV["BUNDLE_GEMFILE"] = File.join(repo_root, "Gemfile")
require "bundler/setup"

# Started before anything it measures is loaded.
if %w[1 all].include?(ENV["COVERAGE"])
    require "simplecov"
    SimpleCov.start do
        root repo_root
        enable_coverage :branch
        # SimpleCov's default hidden_filter drops every path under a dot folder, .github/ included.
        remove_filter(/\A\..*/) or raise "SimpleCov's hidden-folder filter has changed; update this line"
        skip "Tests/Harness/"
        skip(/_test\.rb\z/)
        formats :html, :json
        cover "Plugins/**/*.rb" if ENV["COVERAGE"] == "all"
    end
end

require "minitest/autorun"
require_relative "harness_error"
require_relative "runtime_stubs"
require_relative "core_scripts"
require_relative "plugin_files"
require_relative "plugin_loader"
require_relative "test_reset"
require_relative "record_factories"
require_relative "move_factory"

CoreScripts.load(File.join(repo_root, "Data", "Scripts.rxdata"), PluginFiles::CORE_SCRIPTS)
require_relative "localisation_stubs"
PluginLoader.load(repo_root, PluginFiles::PLUGIN_FILES)
require_relative "test_battler"
require_relative "test_battle"

TestReset.baseline = StateSnapshot.take
Minitest::Test.include(TestReset)
Minitest::Test.include(RecordFactories)
Minitest::Test.include(MoveFactory)
