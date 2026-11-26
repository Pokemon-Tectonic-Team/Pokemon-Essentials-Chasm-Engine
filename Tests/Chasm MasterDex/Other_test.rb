require_relative "../support/test_helper"

class OtherTest < Minitest::Test
    # catchDifficultyFromRareness

    def tiers(*rates)
        return rates.map { |rate| catchDifficultyFromRareness(rate) }
    end

    def test_each_default_catch_rate_has_its_own_tier
        assert_equal %w[S A+ A B C D F], tiers(5, 25, 35, 60, 95, 145, 195)
    end

    def test_every_rate_in_the_species_tables_has_a_tier
        tables = [GameData::Species::DEFAULT_CATCH_RATES, GameData::Species::UB_CATCH_RATES, GameData::Species::LEGENDARY_CATCH_RATES]

        tables.flatten.uniq.each do |rate|
            refute_equal "F-", catchDifficultyFromRareness(rate), "catch rate #{rate}"
        end
    end

    def test_each_tier_includes_its_upper_bound
        assert_equal %w[S A+ A B C D F], tiers(20, 30, 40, 70, 100, 150, 200)
        assert_equal %w[A+ A B C D F], tiers(21, 31, 41, 71, 101, 151)
    end

    def test_a_rate_easier_than_every_tier_is_f_minus
        assert_equal %w[F- F-], tiers(201, 255)
    end
end
