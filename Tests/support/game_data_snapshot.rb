# The state GameData classes hold in constants (DATA, FLAG_INDEX and the like), copied so it
# can be put back. Covers every unfrozen Hash or Array constant on a class under GameData, and
# any unfrozen Hash or Array nested inside one.
module GameDataSnapshot
    module_function

    # Each live Hash or Array, mapped to a shallow copy of it.
    def take
        copies = {}.compare_by_identity
        GameData.constants.map { |name| GameData.const_get(name) }.grep(Class).each do |klass|
            klass.constants(false).each { |name| collect(klass.const_get(name, false), copies) }
        end
        copies
    end

    # Puts each object back to its copy, in place, so every reference to it sees the reset.
    def restore(snapshot)
        snapshot.each { |object, copy| object.replace(copy) }
    end

    def collect(value, copies)
        return unless value.is_a?(Hash) || value.is_a?(Array)
        return if value.frozen? || copies.key?(value)

        copies[value] = value.dup
        (value.is_a?(Hash) ? value.values : value).each { |item| collect(item, copies) }
    end
    private_class_method :collect
end
