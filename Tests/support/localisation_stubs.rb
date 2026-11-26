require_relative "harness_error"

# Core's localisation (Intl_Messages) with no translations loaded: every message is the text
# the code or record gives. Loaded after core Intl_Messages, so these replace its definitions.

# Substitutes {n} with the n-th argument after the string.
def _INTL(*args)
    (1...args.length).reduce(args[0].dup) { |string, i| string.gsub("{#{i}}") { args[i].to_s } }
end

# A registered type's own name; "" when no type has that number, as the engine gives.
def pbGetMessage(type, id)
    raise HarnessError, "pbGetMessage has no stub for message type #{type}" unless type == MessageTypes::Types

    GameData::Type.try_get(id)&.real_name || ""
end

def pbGetMessageFromHash(_type, text)
    text
end
