require_relative "harness_error"

# Loads plugin files in the order the engine runs them, as core PluginManager computes it.
# Needs core RubyUtilities, FileTests, Compiler and PluginManager loaded first.
module PluginLoader
    module_function

    # Every plugin file under repo_root/Plugins, as an absolute path, in engine order.
    # PluginManager reads "Plugins" relative to the cwd and lists nothing unless $DEBUG is set.
    def order(repo_root)
        root = File.expand_path(repo_root)
        debug = $DEBUG
        $DEBUG = true
        order, plugins = Dir.chdir(root) { PluginManager.getPluginOrder }
        order.flat_map do |name|
            plugin = plugins[name]
            plugin[:scripts].map { |script| File.join(root, plugin[:dir], script) }
        end
    ensure
        $DEBUG = debug
    end

    # Requires each of relative_paths (relative to repo_root/Plugins) once, in engine order.
    # Refuses before loading anything if a path is not a file the engine would load.
    def load(repo_root, relative_paths)
        files = order(repo_root)
        plugins_dir = File.join(File.expand_path(repo_root), "Plugins")
        wanted = relative_paths.map { |path| File.join(plugins_dir, path) }
        unknown = wanted - files
        unless unknown.empty?
            raise HarnessError, "not a plugin file the engine loads: #{unknown.join(', ')}"
        end

        (files & wanted).each { |file| require file }
    end
end
