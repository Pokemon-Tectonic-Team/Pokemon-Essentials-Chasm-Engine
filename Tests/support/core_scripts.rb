require "zlib"
require_relative "harness_error"

# The RGSS core script archive (Data/Scripts.rxdata): a Marshal-dumped array of
# [id, name, zlib-deflated code], one entry per script in the game's script editor.
module CoreScripts
    module_function

    # [name, code] for every entry of the archive at path, in archive order.
    def entries(path)
        archive = Marshal.load(File.binread(path)) # rubocop:disable Security/MarshalLoad
        raise HarnessError, "#{path} is not a script archive" unless archive.is_a?(Array)

        archive.map do |entry|
            unless entry.is_a?(Array) && entry.length == 3 && entry[1].is_a?(String) && entry[2].is_a?(String)
                raise HarnessError, "#{path} has an entry that is not [id, name, code]"
            end

            [entry[1], Zlib::Inflate.inflate(entry[2]).force_encoding(Encoding::UTF_8)]
        end
    rescue TypeError, ArgumentError, Zlib::Error => e
        raise HarnessError, "#{path} is not a script archive (#{e.message})"
    end

    # Evaluates the named entries at the top level, in archive order, each with
    # "[core] <name>" as its file name. Every name must match exactly one entry.
    def load(path, names)
        all = entries(path)
        counts = all.map(&:first).tally
        missing = names.reject { |name| counts.key?(name) }
        raise HarnessError, "#{path} has no script named #{missing.join(', ')}" unless missing.empty?

        duplicated = names.select { |name| counts[name] > 1 }
        raise HarnessError, "#{path} has more than one script named #{duplicated.join(', ')}" unless duplicated.empty?

        all.each do |name, code|
            eval(code, TOPLEVEL_BINDING, "[core] #{name}") if names.include?(name) # rubocop:disable Security/Eval
        end
    end
end
