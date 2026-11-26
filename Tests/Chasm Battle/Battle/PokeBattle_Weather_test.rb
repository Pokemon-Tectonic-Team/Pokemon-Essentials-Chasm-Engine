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

    def test_eclipse_helpers_split_on_the_special_weather_effect
        FAMILIES[:eclipsed?].each do |weather|
            total = battle(weather, special: true)
            assert total.totalEclipse?, weather.to_s
            refute total.partialEclipse?, weather.to_s
            partial = battle(weather, special: false)
            assert partial.partialEclipse?, weather.to_s
            refute partial.totalEclipse?, weather.to_s
        end
    end

    def test_moon_helpers_split_on_the_special_weather_effect
        FAMILIES[:moonGlowing?].each do |weather|
            full = battle(weather, special: true)
            assert full.fullMoon?, weather.to_s
            refute full.waxingMoon?, weather.to_s
            waxing = battle(weather, special: false)
            assert waxing.waxingMoon?, weather.to_s
            refute waxing.fullMoon?, weather.to_s
        end
    end

    def test_special_helpers_are_false_outside_their_family
        [:Sunshine, :Rainstorm, :Sandstorm, :Hail, :None].each do |weather|
            [true, false].each do |special|
                b = battle(weather, special: special)
                refute b.partialEclipse?, "#{weather} #{special}"
                refute b.totalEclipse?, "#{weather} #{special}"
                refute b.waxingMoon?, "#{weather} #{special}"
                refute b.fullMoon?, "#{weather} #{special}"
            end
        end
        [true, false].each do |special|
            refute battle(:Moonglow, special: special).partialEclipse?
            refute battle(:Moonglow, special: special).totalEclipse?
            refute battle(:Eclipse, special: special).waxingMoon?
            refute battle(:Eclipse, special: special).fullMoon?
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
        refute b.icy?
    end

    def test_a_fainted_airlock_battler_does_not_suppress
        b = battle(:Hail, battlers: [airlock_battler(fainted: true), TestBattler.new])
        assert_equal :Hail, b.pbWeather
        assert b.icy?
    end

    def test_a_nil_battler_slot_is_skipped
        assert_equal :Hail, battle(:Hail, battlers: [nil, TestBattler.new]).pbWeather
    end

    def test_weather_suppressed_with_and_without_airlock
        assert battle(:Hail, battlers: [airlock_battler]).weatherSuppressed?
        refute battle(:Hail, battlers: [TestBattler.new]).weatherSuppressed?
        refute battle(:Hail).weatherSuppressed?
    end

    def test_weather_suppressed_ignores_a_fainted_airlock_battler
        refute battle(:Hail, battlers: [airlock_battler(fainted: true)]).weatherSuppressed?
    end
end
