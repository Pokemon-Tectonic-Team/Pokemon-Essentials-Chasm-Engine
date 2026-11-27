require_relative "../../support/test_helper"

# A real PokeBattle_Battle holding only the state the weather helpers read.
class WeatherTestBattle < PokeBattle_Battle
    Field = Struct.new(:weather, :specialWeatherEffect)

    def initialize(weather:, special: false, battlers: []) # rubocop:disable Lint/MissingSuper -- a fake: sets only its own state, skipping the real initializer by design
        @field = Field.new(weather, special)
        @battlers = battlers
    end
end

class PokeBattleWeatherTest < Minitest::Test
    FAMILIES = {
        sunny?: [:Sunshine, :HarshSun],
        rainy?: [:Rainstorm, :HeavyRain],
        sandy?: [:Sandstorm, :StarStorm],
        icy?: [:Hail, :IceAge],
        eclipsed?: [:Eclipse, :RingEclipse],
        moonGlowing?: [:Moonglow, :BloodMoon],
    }.freeze

    def battle(weather, **options)
        WeatherTestBattle.new(weather: weather, **options)
    end

    def airlock_battler(**options)
        TestBattler.new(abilities: [:AIRLOCK], **options)
    end

    # Family helpers

    def test_each_family_helper_is_true_for_each_of_its_weathers
        FAMILIES.each do |helper, weathers|
            weathers.each do |weather|
                assert battle(weather).public_send(helper), "#{helper} #{weather}"
            end
        end
    end

    def test_each_family_helper_is_false_for_another_weather
        FAMILIES.each_key do |helper|
            FAMILIES.each do |other_helper, other_weathers|
                next if other_helper == helper

                other_weathers.each do |weather|
                    refute battle(weather).public_send(helper), "#{helper} #{weather}"
                end
            end

            refute battle(:None).public_send(helper), "#{helper} None"
        end
    end

    # Special helpers

    SPECIAL_HELPERS = [:partialEclipse?, :totalEclipse?, :waxingMoon?, :fullMoon?].freeze

    # The special helpers true in the weather, with the special weather effect on and then off
    def special_helpers_true(weather)
        return [true, false].map do |special|
            b = battle(weather, special: special)
            SPECIAL_HELPERS.select { |helper| b.public_send(helper) }
        end
    end

    def test_eclipse_helpers_split_on_the_special_weather_effect
        FAMILIES[:eclipsed?].each do |weather|
            assert_equal [[:totalEclipse?], [:partialEclipse?]], special_helpers_true(weather), weather.to_s
        end
    end

    def test_moon_helpers_split_on_the_special_weather_effect
        FAMILIES[:moonGlowing?].each do |weather|
            assert_equal [[:fullMoon?], [:waxingMoon?]], special_helpers_true(weather), weather.to_s
        end
    end

    def test_special_helpers_are_false_outside_their_family
        [:Sunshine, :Rainstorm, :Sandstorm, :Hail, :None].each do |weather|
            assert_equal [[], []], special_helpers_true(weather), weather.to_s
        end
    end

    # pbWeather and weatherSuppressed?

    def test_pbweather_gives_the_fields_weather
        assert_equal :Hail, battle(:Hail).pbWeather
        assert_equal :None, battle(:None).pbWeather
    end

    def test_pbweather_gives_the_fields_weather_with_battlers_lacking_airlock
        assert_equal :Hail, battle(:Hail, battlers: [TestBattler.new, TestBattler.new]).pbWeather
    end

    def test_pbweather_is_none_while_a_live_battler_has_airlock
        b = battle(:Hail, battlers: [TestBattler.new, airlock_battler])

        assert_equal :None, b.pbWeather
        refute_predicate b, :icy?
    end

    def test_a_fainted_airlock_battler_does_not_suppress
        b = battle(:Hail, battlers: [airlock_battler(fainted: true), TestBattler.new])

        assert_equal :Hail, b.pbWeather
        assert_predicate b, :icy?
    end

    def test_a_nil_battler_slot_is_skipped
        assert_equal :Hail, battle(:Hail, battlers: [nil, TestBattler.new]).pbWeather
    end

    def test_weather_suppressed_with_and_without_airlock
        assert_predicate battle(:Hail, battlers: [airlock_battler]), :weatherSuppressed?
        refute_predicate battle(:Hail, battlers: [TestBattler.new]), :weatherSuppressed?
        refute_predicate battle(:Hail), :weatherSuppressed?
    end

    def test_weather_suppressed_ignores_a_fainted_airlock_battler
        refute_predicate battle(:Hail, battlers: [airlock_battler(fainted: true)]), :weatherSuppressed?
    end
end
