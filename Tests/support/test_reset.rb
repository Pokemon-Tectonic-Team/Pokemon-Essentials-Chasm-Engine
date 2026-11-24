require_relative "state_snapshot"

# Before every test, puts game state back to the baseline the harness took once game code loaded.
module TestReset
    class << self
        attr_accessor :baseline
    end

    def before_setup
        super
        StateSnapshot.restore(TestReset.baseline)
    end
end
