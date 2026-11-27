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

    def test_methods_name_their_move_type_or_species
        create_move(id: :ROLLOUT)
        create_type(id: :FAIRY)
        create_species(id: :REMORAID)

        assert_equal "when leveled up while it knows the move Rollout", describeEvolutionMethod(:HasMove, :ROLLOUT)
        assert_equal "when leveled up while it knows a move of the Fairy type", describeEvolutionMethod(:HasMoveType, :FAIRY)
        assert_equal "when leveled up while a Remoraid is also in the party", describeEvolutionMethod(:HasInParty, :REMORAID)
    end

    def test_item_methods_name_their_item_with_its_article
        create_item(id: :FIRESTONE, name: "Fire Stone")
        create_item(id: :ICESTONE, name: "Ice Stone")

        assert_equal "by using a Fire Stone", describeEvolutionMethod(:Item, :FIRESTONE)
        assert_equal "by using an Ice Stone", describeEvolutionMethod(:Item, :ICESTONE)
        assert_equal "by using an Ice Stone if it's male", describeEvolutionMethod(:ItemMale, :ICESTONE)
        assert_equal "by using a Fire Stone if it's female", describeEvolutionMethod(:ItemFemale, :FIRESTONE)
    end

    def test_trade_item_names_its_item_with_its_article
        create_item(id: :METALCOAT, name: "Metal Coat")
        create_item(id: :UPGRADE, name: "Upgrade")

        assert_equal "when traded holding a Metal Coat", describeEvolutionMethod(:TradeItem, :METALCOAT)
        assert_equal "when traded holding an Upgrade", describeEvolutionMethod(:TradeItem, :UPGRADE)
    end

    # withIndefiniteArticle

    def test_a_name_starting_with_a_vowel_takes_an_whatever_its_case
        assert_equal "an Orb", withIndefiniteArticle("Orb")
        assert_equal "an eviolite", withIndefiniteArticle("eviolite")
    end

    def test_a_name_starting_with_a_consonant_takes_a
        assert_equal "a King's Rock", withIndefiniteArticle("King's Rock")
    end

    def test_originize_names_the_ore_it_spends_with_its_article
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
        $dex_cross_link = nil
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

    # openPartyDexScreen

    # The dex screens fade in through this, which resolves to the test's own when a test calls the
    # helpers. It counts each screen opened instead of opening it, and the first one opened leaves
    # behind the cross link a test gives.
    def pbFadeOutIn
        @screens_opened = screens_opened + 1
        $dex_cross_link = @cross_link if @screens_opened == 1
    end

    def screens_opened
        return @screens_opened || 0
    end

    def test_the_party_dex_screen_registers_the_pokemon_as_last_seen_and_opens_once
        pokemon = FakePokemon.new(:BASE)
        $dex_cross_link = { type: :move, id: :EMBER }

        openPartyDexScreen(pokemon, 0)

        assert_equal [[:register_last_seen, pokemon]], $Trainer.pokedex.calls
        assert_equal 1, screens_opened
        assert_nil $dex_cross_link
    end

    def test_the_party_dex_screen_follows_a_cross_link_left_by_the_screen
        pokemon = FakePokemon.new(:BASE)
        create_species(id: :TOP)
        @cross_link = { type: :species, id: :TOP }

        openPartyDexScreen(pokemon, 0)

        assert_equal [[:register_last_seen, pokemon], [:set_last_form_seen, :TOP, 0, 0]], $Trainer.pokedex.calls
        assert_equal 2, screens_opened
        assert_nil $dex_cross_link
    end

    # unlockDex

    def test_unlock_dex_gives_the_dex_and_unlocks_every_region
        unlockDex

        assert $Trainer.has_pokedex
        assert_equal [[:unlock, -1], [:refresh_accessible_dexes]], $Trainer.pokedex.calls
    end
end
