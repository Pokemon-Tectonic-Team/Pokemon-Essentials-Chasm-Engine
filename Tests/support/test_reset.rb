require_relative "game_data_snapshot"

# Before every test, puts GameData back to the baseline the harness took once game code loaded.
module TestReset
    class << self
        attr_accessor :baseline
    end

    def before_setup
        super
        GameDataSnapshot.restore(TestReset.baseline)
    end
end
