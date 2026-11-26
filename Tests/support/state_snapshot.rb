# The state game code holds in constants that tests can change, copied so it can be put back:
# every unfrozen Hash or Array held by a constant on a class under GameData or by a handler
# container under BattleHandlers (a HandlerHash2's @hash and @add_ifs, an Event's @callbacks),
# directly or nested inside other Hashes and Arrays, frozen ones included. State a handler keeps
# in its own closure is not covered.
module StateSnapshot
    HANDLER_IVARS = %i[@hash @add_ifs @callbacks].freeze

    module_function

    # Each live unfrozen Hash or Array, mapped to a shallow copy of it.
    def take
        copies = {}.compare_by_identity
        seen = {}.compare_by_identity
        GameData.constants.map { |name| GameData.const_get(name) }.grep(Class).each do |klass|
            klass.constants(false).each { |name| collect(klass.const_get(name, false), copies, seen) }
        end
        BattleHandlers.constants(false).each do |name|
            container = BattleHandlers.const_get(name, false)
            HANDLER_IVARS.each do |ivar|
                next unless container.instance_variable_defined?(ivar)

                collect(container.instance_variable_get(ivar), copies, seen)
            end
        end
        copies
    end

    # Puts each object back to its copy, in place, so every reference to it sees the reset.
    def restore(snapshot)
        snapshot.each { |object, copy| object.replace(copy) }
    end

    # Copies value if it is an unfrozen Hash or Array, then walks into it, frozen or not, so
    # state held inside a frozen container is copied too.
    def collect(value, copies, seen)
        return unless value.is_a?(Hash) || value.is_a?(Array)
        return if seen.key?(value)

        seen[value] = true
        copies[value] = value.dup unless value.frozen?
        (value.is_a?(Hash) ? value.values : value).each { |item| collect(item, copies, seen) }
    end
    private_class_method :collect
end
