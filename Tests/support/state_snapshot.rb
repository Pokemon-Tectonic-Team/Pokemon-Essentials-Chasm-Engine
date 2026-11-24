# The state game code holds in constants that tests can change, copied so it can be put back:
# every unfrozen Hash or Array constant on a class under GameData, the handler containers under
# BattleHandlers (a HandlerHash2's @hash and @add_ifs, an Event's @callbacks), and any unfrozen
# Hash or Array nested inside those. State a handler keeps in its own closure is not covered.
module StateSnapshot
    HANDLER_IVARS = %i[@hash @add_ifs @callbacks].freeze

    module_function

    # Each live Hash or Array, mapped to a shallow copy of it.
    def take
        copies = {}.compare_by_identity
        GameData.constants.map { |name| GameData.const_get(name) }.grep(Class).each do |klass|
            klass.constants(false).each { |name| collect(klass.const_get(name, false), copies) }
        end
        BattleHandlers.constants(false).each do |name|
            container = BattleHandlers.const_get(name, false)
            HANDLER_IVARS.each do |ivar|
                collect(container.instance_variable_get(ivar), copies) if container.instance_variable_defined?(ivar)
            end
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
