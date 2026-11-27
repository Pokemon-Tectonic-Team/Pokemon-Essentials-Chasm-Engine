require_relative "../../support/test_helper"

class TypeTest < Minitest::Test
    def test_initialize_defaults
        expected = {
            id: :FIRE, id_number: -1, real_name: "Unnamed", weaknesses: [], resistances: [], immunities: [],
            pseudo_type: false, special_type: false
        }

        assert_attributes expected, GameData::Type.new({ id: :FIRE })
    end

    def test_initialize_keeps_given_values
        type = GameData::Type.new({ id: :FIRE, id_number: 3, name: "Flame", pseudo_type: true, special_type: true })

        assert_attributes({ id_number: 3, real_name: "Flame", pseudo_type: true, special_type: true }, type)
    end

    def test_initialize_keeps_lists_as_given
        type = GameData::Type.new({ id: :FIRE, weaknesses: [:WATER, :ROCK], resistances: [:GRASS, :ICE], immunities: [:GHOST, :DARK] })

        assert_equal [:WATER, :ROCK], type.weaknesses
        assert_equal [:GRASS, :ICE], type.resistances
        assert_equal [:GHOST, :DARK], type.immunities
    end

    def test_initialize_wraps_a_scalar_weakness_resistance_and_immunity_in_a_list
        type = GameData::Type.new({ id: :FIRE, weaknesses: :WATER, resistances: :GRASS, immunities: :GHOST })

        assert_equal [:WATER], type.weaknesses
        assert_equal [:GRASS], type.resistances
        assert_equal [:GHOST], type.immunities
    end

    def test_initialize_turns_colours_into_colors
        type = GameData::Type.new({ id: :FIRE, color: [10, 20, 30], dark_color: [1, 2, 3] })

        colours = [type.color, type.dark_color].map { |colour| [colour.class, colour.red, colour.green, colour.blue] }

        assert_equal [[Color, 10, 20, 30], [Color, 1, 2, 3]], colours
    end

    def test_initialize_leaves_colours_unset_when_not_given
        type = GameData::Type.new({ id: :FIRE })

        assert_nil type.color
        assert_nil type.dark_color
    end

    def test_name_is_looked_up_by_id_number
        create_type(id: :WATER, id_number: 4, name: "Registered")
        type = GameData::Type.new({ id: :FIRE, id_number: 4, name: "Own" })

        assert_equal "Registered", type.name
    end

    def test_name_of_an_unregistered_id_number_is_blank
        assert_equal "", GameData::Type.new({ id: :FIRE, id_number: 9, name: "Own" }).name
    end

    def test_a_physical_type_is_physical_and_not_special
        type = GameData::Type.new({ id: :ROCK })

        assert_predicate type, :physical?
        refute_predicate type, :special?
    end

    def test_a_special_type_is_special_and_not_physical
        type = GameData::Type.new({ id: :FIRE, special_type: true })

        assert_predicate type, :special?
        refute_predicate type, :physical?
    end

    def test_effectiveness_of_no_attacker_is_normal
        type = GameData::Type.new({ id: :FIRE, weaknesses: [:WATER] })

        assert_in_delta 1.0, type.effectiveness(nil)
    end

    def test_effectiveness_of_a_weakness_is_double
        assert_in_delta 2.0, GameData::Type.new({ id: :FIRE, weaknesses: [:WATER] }).effectiveness(:WATER)
    end

    def test_effectiveness_of_a_resistance_is_half
        assert_in_delta 0.5, GameData::Type.new({ id: :FIRE, resistances: [:GRASS] }).effectiveness(:GRASS)
    end

    def test_effectiveness_of_an_immunity_is_zero
        assert_equal 0, GameData::Type.new({ id: :NORMAL, immunities: [:GHOST] }).effectiveness(:GHOST)
    end

    def test_effectiveness_of_an_unlisted_attacker_is_normal
        type = GameData::Type.new({ id: :FIRE, weaknesses: [:WATER], resistances: [:GRASS], immunities: [:GHOST] })

        assert_in_delta 1.0, type.effectiveness(:NORMAL)
    end

    # The effectiveness values each predicate is tried on, from immune to doubly weak
    EFFECTIVENESS_VALUES = [0, 0.25, 0.5, 1.0, 2.0, 4.0].freeze

    def values_where(predicate)
        return EFFECTIVENESS_VALUES.select { |value| Effectiveness.public_send(predicate, value) }
    end

    def test_ineffective_is_only_zero
        assert_equal [0], values_where(:ineffective?)
    end

    def test_not_very_effective_is_above_zero_and_below_normal
        assert_equal [0.25, 0.5], values_where(:not_very_effective?)
    end

    def test_barely_effective_is_above_zero_and_below_half
        assert_equal [0.25], values_where(:barely_effective?)
    end

    def test_resistant_is_above_zero_and_below_normal
        assert_equal [0.25, 0.5], values_where(:resistant?)
    end

    def test_normal_is_only_one
        assert_equal [1.0], values_where(:normal?)
    end

    def test_super_effective_is_above_normal
        assert_equal [2.0, 4.0], values_where(:super_effective?)
    end

    def test_hyper_effective_is_above_double
        assert_equal [4.0], values_where(:hyper_effective?)
    end

    def test_calculate_one_reads_the_defending_types_record
        create_type(id: :FIRE, weaknesses: [:WATER], resistances: [:GRASS])
        create_type(id: :WATER, weaknesses: [:GRASS])
        expected = { [:WATER, :FIRE] => 2.0, [:GRASS, :FIRE] => 0.5, [:GRASS, :WATER] => 2.0, [:FIRE, :WATER] => 1.0 }

        calculated = expected.keys.to_h { |pair| [pair, Effectiveness.calculate_one(*pair)] }

        assert_equal expected, calculated
    end

    def test_calculate_multiplies_over_the_defending_types
        create_type(id: :FIRE, weaknesses: [:WATER])
        create_type(id: :ROCK, weaknesses: [:WATER])
        create_type(id: :GRASS, resistances: [:WATER])

        assert_in_delta 4.0, Effectiveness.calculate(:WATER, [:FIRE, :ROCK])
        assert_in_delta 1.0, Effectiveness.calculate(:WATER, [:FIRE, :GRASS])
    end

    def test_calculate_with_an_immune_defending_type_is_zero
        create_type(id: :NORMAL, immunities: [:GHOST])
        create_type(id: :FIRE)

        assert_in_delta 0.0, Effectiveness.calculate(:GHOST, [:NORMAL, :FIRE])
    end

    def test_calculate_ignores_nils
        create_type(id: :FIRE, weaknesses: [:WATER])

        assert_in_delta 2.0, Effectiveness.calculate(:WATER, [:FIRE, nil])
    end

    def test_calculate_counts_a_duplicate_type_once
        create_type(id: :FIRE, weaknesses: [:WATER])

        assert_in_delta 2.0, Effectiveness.calculate(:WATER, [:FIRE, :FIRE])
    end

    def test_calculate_of_no_types_is_one
        assert_in_delta 1.0, Effectiveness.calculate(:WATER, [])
        assert_in_delta 1.0, Effectiveness.calculate(:WATER)
        assert_in_delta 1.0, Effectiveness.calculate(:WATER, [nil])
    end

    # Registers FIRE, which GHOST is ineffective against, GRASS resisted by, NORMAL neutral against
    # and WATER super effective against, then gives the attacking types the predicate holds for
    def attackers_of_fire_where(predicate)
        create_type(id: :FIRE, weaknesses: [:WATER], resistances: [:GRASS], immunities: [:GHOST])
        return %i[GHOST GRASS NORMAL WATER].select { |attacker| Effectiveness.public_send(predicate, attacker, :FIRE) }
    end

    def test_ineffective_type_is_true_only_for_an_immunity
        assert_equal [:GHOST], attackers_of_fire_where(:ineffective_type?)
    end

    def test_not_very_effective_type_is_true_only_for_a_resistance
        assert_equal [:GRASS], attackers_of_fire_where(:not_very_effective_type?)
    end

    def test_resistant_type_is_true_only_for_a_resistance
        assert_equal [:GRASS], attackers_of_fire_where(:resistant_type?)
    end

    def test_normal_type_is_true_only_for_a_neutral_pair
        assert_equal [:NORMAL], attackers_of_fire_where(:normal_type?)
    end

    def test_super_effective_type_is_true_only_for_a_weakness
        assert_equal [:WATER], attackers_of_fire_where(:super_effective_type?)
    end

    def test_modify_boss_effectiveness_returns_the_effectiveness_unchanged_while_dilution_is_off
        [0, 0.5, 1.0, 2.0, 4.0].each do |value|
            assert_equal value, Effectiveness.modify_boss_effectiveness(value, nil, nil)
        end
    end
end
