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

    # theoreticalCaptureChance

    def test_capture_chance_is_the_per_shake_chance_for_all_four_shakes
        threshold = PokeBattle_Battle.captureThresholdCalcInternals(:NONE, 0, 50, 100, 60)

        expected = (threshold / 65_536.0)**4
        assert_in_delta expected, theoreticalCaptureChance(:NONE, 50, 100, 60), 1e-12
    end

    def test_capture_chance_rises_with_lower_hp_a_status_and_an_easier_rate
        base = theoreticalCaptureChance(:NONE, 100, 100, 60)

        assert_operator theoreticalCaptureChance(:NONE, 10, 100, 60), :>, base
        assert_operator theoreticalCaptureChance(:SLEEP, 100, 100, 60), :>, base
        assert_operator theoreticalCaptureChance(:NONE, 100, 100, 145), :>, base
    end

    # describeEvolutionMethod

    def test_level_methods_describe_their_level
        assert_equal "at level 16", describeEvolutionMethod(:Level, 16)
        assert_equal "at level 16", describeEvolutionMethod(:Ninjask, 16)
        assert_equal "at level 20 if it's male", describeEvolutionMethod(:LevelMale, 20)
        assert_equal "at level 20 during nighttime", describeEvolutionMethod(:LevelNight, 20)
    end

    def test_every_level_method_mentions_its_level
        methods = %i[
            LevelFemale LevelDay LevelRain LevelDarkInParty AttackGreater AtkDefEqual DefenseGreater
            Silcoon Cascoon Ability0 Ability1
        ]

        methods.each { |method| assert describeEvolutionMethod(method, 33).start_with?("at level 33"), method }
    end

    def test_methods_without_a_parameter
        assert_equal "when leveled up while it has high happiness", describeEvolutionMethod(:Happiness)
        assert_equal "when traded", describeEvolutionMethod(:Trade)
        %i[MaxHappiness Beauty Location Shedinja].each { |method| refute_empty describeEvolutionMethod(method) }
    end

    def test_methods_name_their_move_item_or_species
        create_move(id: :ROLLOUT)
        create_item(id: :FIRESTONE)
        create_species(id: :REMORAID)

        assert_equal "when leveled up while it knows the move Rollout", describeEvolutionMethod(:HasMove, :ROLLOUT)
        assert_equal "by using a Firestone", describeEvolutionMethod(:Item, :FIRESTONE)
        assert_equal "by using a Firestone if it's male", describeEvolutionMethod(:ItemMale, :FIRESTONE)
        assert_equal "by using a Firestone if it's female", describeEvolutionMethod(:ItemFemale, :FIRESTONE)
        assert_equal "when traded holding an Upgrade", describeEvolutionMethod(:TradeItem, create_item(id: :UPGRADE).id)
        assert_equal "when leveled up while a Remoraid is also in the party", describeEvolutionMethod(:HasInParty, :REMORAID)
    end

    def test_originize_names_the_ore_it_spends
        create_item(id: :ORIGINORE, name: "Origin Ore")

        assert_equal "at level 40 if you spend an Origin Ore", describeEvolutionMethod(:Originize, 40)
    end

    def test_an_undescribed_method_says_so
        assert_equal "via a method the programmer was too lazy to describe", describeEvolutionMethod(:LevelSnow, 10)
    end

    # The player's MasterDex, recording what the dex helpers ask of it
    class FakePokedex
        attr_reader :calls

        def initialize = @calls = []
        def register_last_seen(pokemon) = @calls.push([:register_last_seen, pokemon])
        def set_last_form_seen(*args) = @calls.push([:set_last_form_seen, *args])
        def unlock(dex) = @calls.push([:unlock, dex])
        def refresh_accessible_dexes = @calls.push([:refresh_accessible_dexes])
    end

    FakeTrainer = Struct.new(:pokedex, :has_pokedex)
    FakePokemon = Struct.new(:species)

    def setup
        $Trainer = FakeTrainer.new(FakePokedex.new, false)
    end

    def teardown
        $Trainer = nil
    end

    # resolveDexSpecies

    def test_resolving_a_pokemon_registers_it_as_last_seen
        pokemon = FakePokemon.new(:BASE)

        assert_equal :BASE, resolveDexSpecies(pokemon)
        assert_equal [[:register_last_seen, pokemon]], $Trainer.pokedex.calls
    end

    def test_resolving_a_species_form_records_that_form_as_last_seen
        create_species(id: :BASE)
        create_species(id: :BASE_2, species: :BASE, form: 2)

        assert_equal :BASE, resolveDexSpecies(:BASE_2)
        assert_equal [[:set_last_form_seen, :BASE, 0, 2]], $Trainer.pokedex.calls
    end

    # unlockDex

    def test_unlock_dex_gives_the_dex_and_unlocks_every_region
        unlockDex

        assert $Trainer.has_pokedex
        assert_equal [[:unlock, -1], [:refresh_accessible_dexes]], $Trainer.pokedex.calls
    end
end
