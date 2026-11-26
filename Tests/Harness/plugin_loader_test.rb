require_relative "../support/test_helper"
require "tmpdir"
require "fileutils"

class PluginLoaderTest < Minitest::Test
    # With no dependencies the engine loads folders in reverse bytewise order, Beta (B) first.
    # Beta requiring Alpha swaps them. Alpha's meta names z.rb, which loads before its folder's
    # own files and then its subfolder's.
    def with_fixture(beta_meta = "Name = Beta\n")
        Dir.mktmpdir("plugin loader") do |root|
            write_plugin(root, "A", "Name = Alpha\nScripts = z.rb\n", %w[z.rb a.rb sub/s.rb])
            write_plugin(root, "B", beta_meta, %w[b.rb])
            yield File.expand_path(root)
        end
    end

    def plugin_paths(root, paths)
        paths.map { |path| "#{root}/Plugins/#{path}" }
    end

    def write_plugin(root, dir, meta, files)
        files.each do |file|
            path = File.join(root, "Plugins", dir, file)
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, "$plugin_loader_test_log << #{file.inspect}\n")
        end
        File.write(File.join(root, "Plugins", dir, "meta.txt"), meta)
    end

    def setup
        $plugin_loader_test_log = []
    end

    def test_order_is_the_engine_order_as_absolute_paths
        with_fixture do |root|
            assert_equal plugin_paths(root, %w[B/b.rb A/z.rb A/a.rb A/sub/s.rb]), PluginLoader.order(root)
        end
    end

    def test_order_loads_a_dependency_first
        with_fixture("Name = Beta\nRequires = Alpha\n") do |root|
            assert_equal plugin_paths(root, %w[A/z.rb A/a.rb A/sub/s.rb B/b.rb]), PluginLoader.order(root)
        end
    end

    def test_order_restores_cwd_and_debug
        with_fixture do |root|
            cwd = Dir.pwd
            PluginLoader.order(root)

            assert_equal cwd, Dir.pwd
            assert_equal false, $DEBUG
        end
    end

    def test_order_restores_a_debug_flag_that_was_set
        with_fixture do |root|
            $DEBUG = true
            PluginLoader.order(root)

            assert_equal true, $DEBUG
        ensure
            $DEBUG = false
        end
    end

    def test_order_restores_cwd_and_debug_after_an_error
        Dir.mktmpdir("no plugins") do |root|
            cwd = Dir.pwd
            capture_io { assert_raises(Errno::ENOENT) { PluginLoader.order(root) } }

            assert_equal cwd, Dir.pwd
            assert_equal false, $DEBUG
        end
    end

    def test_a_plugin_error_raises_instead_of_exiting
        with_fixture("Name = Beta\nRequires = Gamma\n") do |root|
            capture_io do
                error = assert_raises(HarnessError) { PluginLoader.order(root) }
                assert_includes error.message, "meta.txt"
            end
        end
    end

    def test_it_is_ordering_only_while_order_runs
        refute PluginLoader.ordering?
        with_fixture { |root| PluginLoader.order(root) }
        refute PluginLoader.ordering?
    end

    def test_ordering_ends_after_an_error
        with_fixture("Name = Beta\nRequires = Gamma\n") do |root|
            capture_io { assert_raises(HarnessError) { PluginLoader.order(root) } }
        end
        refute PluginLoader.ordering?
    end

    def test_load_requires_the_named_files_in_engine_order
        with_fixture do |root|
            PluginLoader.load(root, ["A/sub/s.rb", "B/b.rb", "A/z.rb"])

            assert_equal %w[b.rb z.rb sub/s.rb], $plugin_loader_test_log
        end
    end

    def test_load_loads_each_file_once
        with_fixture do |root|
            PluginLoader.load(root, ["B/b.rb", "B/b.rb"])
            PluginLoader.load(root, ["B/b.rb"])

            assert_equal %w[b.rb], $plugin_loader_test_log
        end
    end

    def test_load_refuses_a_path_the_engine_would_not_load_before_loading_any
        with_fixture do |root|
            File.write(File.join(root, "Plugins", "stray.rb"), "")
            error = assert_raises(HarnessError) { PluginLoader.load(root, ["B/b.rb", "stray.rb"]) }

            assert_includes error.message, plugin_paths(root, ["stray.rb"]).first
            assert_empty $plugin_loader_test_log
        end
    end
end
