require_relative "../../support/test_helper"

class TypeTest < Minitest::Test
    def test_initialize_defaults
        type = GameData::Type.new({ id: :FIRE })

        assert_equal :FIRE, type.id
        assert_equal(-1, type.id_number)
        assert_equal "Unnamed", type.real_name
        assert_equal [], type.weaknesses
        assert_equal [], type.resistances
        assert_equal [], type.immunities
        assert_equal false, type.pseudo_type
        assert_equal false, type.special_type
    end

    def test_initialize_keeps_given_values
        type = GameData::Type.new({ id: :FIRE, id_number: 3, name: "Flame", pseudo_type: true, special_type: true })

        assert_equal 3, type.id_number
        assert_equal "Flame", type.real_name
        assert type.pseudo_type
        assert type.special_type
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

        assert_instance_of Color, type.color
        assert_equal [10, 20, 30], [type.color.red, type.color.green, type.color.blue]
        assert_instance_of Color, type.dark_color
        assert_equal [1, 2, 3], [type.dark_color.red, type.dark_color.green, type.dark_color.blue]
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

        assert type.physical?
        refute type.special?
    end

    def test_a_special_type_is_special_and_not_physical
        type = GameData::Type.new({ id: :FIRE, special_type: true })

        assert type.special?
        refute type.physical?
    end

    def test_effectiveness_of_no_attacker_is_normal
        type = GameData::Type.new({ id: :FIRE, weaknesses: [:WATER] })

        assert_equal 1.0, type.effectiveness(nil)
    end

    def test_effectiveness_of_a_weakness_is_double
        assert_equal 2.0, GameData::Type.new({ id: :FIRE, weaknesses: [:WATER] }).effectiveness(:WATER)
    end

    def test_effectiveness_of_a_resistance_is_half
        assert_equal 0.5, GameData::Type.new({ id: :FIRE, resistances: [:GRASS] }).effectiveness(:GRASS)
    end

    def test_effectiveness_of_an_immunity_is_zero
        assert_equal 0, GameData::Type.new({ id: :NORMAL, immunities: [:GHOST] }).effectiveness(:GHOST)
    end

    def test_effectiveness_of_an_unlisted_attacker_is_normal
        type = GameData::Type.new({ id: :FIRE, weaknesses: [:WATER], resistances: [:GRASS], immunities: [:GHOST] })

        assert_equal 1.0, type.effectiveness(:NORMAL)
    end

    def test_ineffective_is_only_zero
        assert Effectiveness.ineffective?(0)
        refute Effectiveness.ineffective?(0.25)
        refute Effectiveness.ineffective?(1.0)
    end

    def test_not_very_effective_is_above_zero_and_below_normal
        refute Effectiveness.not_very_effective?(0)
        assert Effectiveness.not_very_effective?(0.25)
        assert Effectiveness.not_very_effective?(0.5)
        refute Effectiveness.not_very_effective?(1.0)
        refute Effectiveness.not_very_effective?(2.0)
    end

    def test_barely_effective_is_above_zero_and_below_half
        refute Effectiveness.barely_effective?(0)
        assert Effectiveness.barely_effective?(0.25)
        refute Effectiveness.barely_effective?(0.5)
        refute Effectiveness.barely_effective?(1.0)
    end

    def test_resistant_is_above_zero_and_below_normal
        refute Effectiveness.resistant?(0)
        assert Effectiveness.resistant?(0.25)
        assert Effectiveness.resistant?(0.5)
        refute Effectiveness.resistant?(1.0)
        refute Effectiveness.resistant?(2.0)
    end

    def test_normal_is_only_one
        refute Effectiveness.normal?(0.5)
        assert Effectiveness.normal?(1.0)
        refute Effectiveness.normal?(2.0)
    end

    def test_super_effective_is_above_normal
        refute Effectiveness.super_effective?(0.5)
        refute Effectiveness.super_effective?(1.0)
        assert Effectiveness.super_effective?(2.0)
        assert Effectiveness.super_effective?(4.0)
    end

    def test_hyper_effective_is_above_double
        refute Effectiveness.hyper_effective?(1.0)
        refute Effectiveness.hyper_effective?(2.0)
        assert Effectiveness.hyper_effective?(4.0)
    end

    def test_calculate_one_reads_the_defending_types_record
        create_type(id: :FIRE, weaknesses: [:WATER], resistances: [:GRASS])
        create_type(id: :WATER, weaknesses: [:GRASS])

        assert_equal 2.0, Effectiveness.calculate_one(:WATER, :FIRE)
        assert_equal 0.5, Effectiveness.calculate_one(:GRASS, :FIRE)
        assert_equal 2.0, Effectiveness.calculate_one(:GRASS, :WATER)
        assert_equal 1.0, Effectiveness.calculate_one(:FIRE, :WATER)
    end

    def test_calculate_multiplies_over_the_defending_types
        create_type(id: :FIRE, weaknesses: [:WATER])
        create_type(id: :ROCK, weaknesses: [:WATER])
        create_type(id: :GRASS, resistances: [:WATER])

        assert_equal 4.0, Effectiveness.calculate(:WATER, [:FIRE, :ROCK])
        assert_equal 1.0, Effectiveness.calculate(:WATER, [:FIRE, :GRASS])
    end

    def test_calculate_with_an_immune_defending_type_is_zero
        create_type(id: :NORMAL, immunities: [:GHOST])
        create_type(id: :FIRE)

        assert_equal 0.0, Effectiveness.calculate(:GHOST, [:NORMAL, :FIRE])
    end

    def test_calculate_ignores_nils
        create_type(id: :FIRE, weaknesses: [:WATER])

        assert_equal 2.0, Effectiveness.calculate(:WATER, [:FIRE, nil])
    end

    def test_calculate_counts_a_duplicate_type_once
        create_type(id: :FIRE, weaknesses: [:WATER])

        assert_equal 2.0, Effectiveness.calculate(:WATER, [:FIRE, :FIRE])
    end

    def test_calculate_of_no_types_is_one
        assert_equal 1.0, Effectiveness.calculate(:WATER, [])
        assert_equal 1.0, Effectiveness.calculate(:WATER)
        assert_equal 1.0, Effectiveness.calculate(:WATER, [nil])
    end

    # FIRE defends: GHOST 0, GRASS 0.5, WATER 2, NORMAL 1.
    def create_defending_fire
        create_type(id: :FIRE, weaknesses: [:WATER], resistances: [:GRASS], immunities: [:GHOST])
    end

    def test_ineffective_type_is_true_only_for_an_immunity
        create_defending_fire

        assert Effectiveness.ineffective_type?(:GHOST, :FIRE)
        refute Effectiveness.ineffective_type?(:GRASS, :FIRE)
        refute Effectiveness.ineffective_type?(:NORMAL, :FIRE)
        refute Effectiveness.ineffective_type?(:WATER, :FIRE)
    end

    def test_not_very_effective_type_is_true_only_for_a_resistance
        create_defending_fire

        assert Effectiveness.not_very_effective_type?(:GRASS, :FIRE)
        refute Effectiveness.not_very_effective_type?(:GHOST, :FIRE)
        refute Effectiveness.not_very_effective_type?(:NORMAL, :FIRE)
        refute Effectiveness.not_very_effective_type?(:WATER, :FIRE)
    end

    def test_resistant_type_is_true_only_for_a_resistance
        create_defending_fire

        assert Effectiveness.resistant_type?(:GRASS, :FIRE)
        refute Effectiveness.resistant_type?(:GHOST, :FIRE)
        refute Effectiveness.resistant_type?(:NORMAL, :FIRE)
        refute Effectiveness.resistant_type?(:WATER, :FIRE)
    end

    def test_normal_type_is_true_only_for_a_neutral_pair
        create_defending_fire

        assert Effectiveness.normal_type?(:NORMAL, :FIRE)
        refute Effectiveness.normal_type?(:GHOST, :FIRE)
        refute Effectiveness.normal_type?(:GRASS, :FIRE)
        refute Effectiveness.normal_type?(:WATER, :FIRE)
    end

    def test_super_effective_type_is_true_only_for_a_weakness
        create_defending_fire

        assert Effectiveness.super_effective_type?(:WATER, :FIRE)
        refute Effectiveness.super_effective_type?(:GHOST, :FIRE)
        refute Effectiveness.super_effective_type?(:GRASS, :FIRE)
        refute Effectiveness.super_effective_type?(:NORMAL, :FIRE)
    end

    def test_modify_boss_effectiveness_returns_the_effectiveness_unchanged_while_dilution_is_off
        [0, 0.5, 1.0, 2.0, 4.0].each do |value|
            assert_equal value, Effectiveness.modify_boss_effectiveness(value, nil, nil)
        end
    end
end
