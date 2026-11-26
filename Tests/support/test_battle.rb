# A stand-in for PokeBattle_Battle in move tests: the battlers, their chosen actions and the
# priority order are given, and pbDisplay records each message instead of showing it.
class TestBattle
    attr_reader :choices, :messages

    def initialize(battlers: [], choices: [], priority: nil)
        @battlers = battlers
        @choices = choices
        @priority = priority
        @messages = []
    end

    def eachBattler(&)
        @battlers.each(&)
    end

    # The priority order given, or the battlers in the order given when none was.
    def pbPriority
        @priority || @battlers
    end

    def pbDisplay(message)
        @messages << message
    end
end
