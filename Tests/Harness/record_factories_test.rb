require_relative "../support/test_helper"

class RecordFactoriesTest < Minitest::Test
    def test_each_helper_returns_the_record_get_finds_of_the_real_class
        {
            GameData::Type => create_type(id: :FIRE),
            GameData::Ability => create_ability(id: :BLAZE),
            GameData::Item => create_item(id: :POTION),
            GameData::Move => create_move(id: :EMBER),
            GameData::Species => create_species(id: :CHARMANDER),
        }.each do |klass, record|
            assert_instance_of klass, record
            assert_same klass.get(record.id), record
        end
    end

    def test_name_is_the_capitalised_id
        assert_equal "Fire", create_type(id: :FIRE).real_name
        assert_equal "Blaze", create_ability(id: :BLAZE).real_name
        assert_equal "Potion", create_item(id: :POTION).real_name
        assert_equal "Ember", create_move(id: :EMBER).real_name
        assert_equal "Charmander", create_species(id: :CHARMANDER).real_name
    end

    def test_a_given_name_replaces_the_default
        assert_equal "Flame", create_type(id: :FIRE, name: "Flame").real_name
    end

    def test_the_first_type_gets_id_number_zero_and_the_next_follows
        assert_equal 0, create_type(id: :FIRE).id_number
        assert_equal 1, create_type(id: :WATER).id_number
    end

    def test_the_next_type_id_number_is_one_above_the_highest_taken
        assert_equal 5, create_type(id: :FIRE, id_number: 5).id_number
        assert_equal 2, create_type(id: :WATER, id_number: 2).id_number
        assert_equal 6, create_type(id: :GRASS).id_number
    end

    def test_two_records_without_an_id_number_are_both_registered
        {
            GameData::Move => %i[create_move EMBER SPARK],
            GameData::Item => %i[create_item POTION ETHER],
            GameData::Species => %i[create_species CHARMANDER RATTATA],
        }.each do |klass, (helper, first, second)|
            send(helper, id: first)
            send(helper, id: second)

            assert klass::DATA.key?(first), "#{klass} lost #{first}"
            assert klass::DATA.key?(second), "#{klass} lost #{second}"
        end
    end

    def test_a_move_defaults_to_normal_type_category_zero_and_no_damage
        move = create_move(id: :TACKLE)

        assert_equal :NORMAL, move.type
        assert_equal 0, move.category
        assert_equal 0, move.base_damage
    end

    def test_a_passed_move_type_overrides_the_default
        assert_equal :FIRE, create_move(id: :EMBER, type: :FIRE).type
    end

    def test_a_species_defaults_to_normal_type1
        assert_equal :NORMAL, create_species(id: :RATTATA).type1
    end

    def test_a_passed_species_type1_overrides_the_default
        assert_equal :FIRE, create_species(id: :CHARMANDER, type1: :FIRE).type1
    end

    def test_extra_keys_reach_the_record
        assert_equal [:WATER], create_type(id: :FIRE, weaknesses: [:WATER]).weaknesses
    end

    def test_ability_flags_reach_flag_index_once
        create_ability(id: :BLAZE, flags: ["X"])

        assert_equal [:BLAZE], GameData::Ability::FLAG_INDEX["X"]
    end

    def test_register_without_an_id_number_registers_the_record
        record = RecordFactories.register(GameData::Ability, {}, { id: :BLAZE })

        assert_same GameData::Ability::DATA[:BLAZE], record
    end

    def test_register_refuses_a_missing_id
        error = assert_raises(HarnessError) { create_move(base_damage: 40) }

        assert_includes error.message, "needs an id"
    end

    def test_register_refuses_an_id_already_registered_and_keeps_the_first
        first = create_move(id: :EMBER)

        assert_raises(HarnessError) { create_move(id: :EMBER, base_damage: 40) }

        assert_same first, GameData::Move.get(:EMBER)
    end

    def test_register_refuses_a_type_id_number_already_taken
        first = create_type(id: :FIRE, id_number: 3)

        error = assert_raises(HarnessError) { create_type(id: :WATER, id_number: 3) }

        assert_includes error.message, "3"
        assert_same first, GameData::Type.get(:FIRE)
        refute GameData::Type::DATA.key?(:WATER)
    end

    def test_register_refuses_an_id_number_already_taken_for_each_class_keyed_by_it
        {
            GameData::Move => [:create_move, :EMBER, :SPARK],
            GameData::Item => [:create_item, :POTION, :ETHER],
            GameData::Species => [:create_species, :CHARMANDER, :RATTATA],
        }.each do |klass, (helper, first_id, second_id)|
            first = send(helper, id: first_id, id_number: 3)

            error = assert_raises(HarnessError) { send(helper, id: second_id, id_number: 3) }

            assert_includes error.message, "3"
            assert_same first, klass.get(first_id)
            refute klass::DATA.key?(second_id), "#{klass} kept the refused record"
        end
    end

    def test_next_id_number_is_zero_for_an_empty_class
        assert_equal 0, RecordFactories.next_id_number(GameData::Type)
    end

    def test_next_id_number_ignores_keys_that_are_not_integers
        create_type(id: :FIRE, id_number: 2)

        assert_equal 3, RecordFactories.next_id_number(GameData::Type)
    end

    def test_without_form_moves_lets_a_species_learnable_moves_be_worked_out
        create_move(id: :TACKLE)
        species = create_species(id: :SOLO, moves: [[1, :TACKLE]], flags: ["NoStaples"])

        without_form_moves(:SOLO)

        assert_equal [:TACKLE], species.learnable_moves
    end
end
