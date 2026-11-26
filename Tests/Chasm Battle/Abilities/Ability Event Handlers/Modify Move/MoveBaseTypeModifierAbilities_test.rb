require_relative "../../../../support/test_helper"

class MoveBaseTypeModifierAbilitiesTest < Minitest::Test
    def trigger(ability, move, type)
        BattleHandlers.triggerMoveBaseTypeModifierAbility(ability, nil, move, type)
    end

    def plain_move
        make_move
    end

    def sound_move
        make_move(flags: ["Sound"])
    end

    # GALVANIZE

    def test_galvanize_turns_normal_into_electric_with_a_power_boost
        create_type(id: :ELECTRIC)
        move = plain_move
        assert_equal :ELECTRIC, trigger(:GALVANIZE, move, :NORMAL)
        assert move.powerBoost
    end

    def test_galvanize_leaves_another_type
        create_type(id: :ELECTRIC)
        move = plain_move
        assert_equal :FIRE, trigger(:GALVANIZE, move, :FIRE)
        refute move.powerBoost
    end

    def test_galvanize_leaves_normal_without_an_electric_record
        move = plain_move
        assert_equal :NORMAL, trigger(:GALVANIZE, move, :NORMAL)
        refute move.powerBoost
    end

    # NORMALIZE

    def test_normalize_turns_any_type_into_normal_with_a_power_boost
        create_type(id: :NORMAL)
        [:FIRE, :WATER, :NORMAL].each do |type|
            move = make_move(id: :"MOVE#{type}")
            assert_equal :NORMAL, trigger(:NORMALIZE, move, type), type.to_s
            assert move.powerBoost, type.to_s
        end
    end

    def test_normalize_leaves_the_type_without_a_normal_record
        move = plain_move
        assert_equal :FIRE, trigger(:NORMALIZE, move, :FIRE)
        refute move.powerBoost
    end

    # ARCTICARIETTE

    def test_arcticariette_turns_a_sound_move_into_ice_with_a_power_boost
        create_type(id: :ICE)
        move = sound_move
        assert_equal :ICE, trigger(:ARCTICARIETTE, move, :WATER)
        assert move.powerBoost
    end

    def test_arcticariette_leaves_a_non_sound_move
        create_type(id: :ICE)
        move = plain_move
        assert_equal :WATER, trigger(:ARCTICARIETTE, move, :WATER)
        refute move.powerBoost
    end

    def test_arcticariette_leaves_a_sound_move_without_an_ice_record
        move = sound_move
        assert_equal :NORMAL, trigger(:ARCTICARIETTE, move, :NORMAL)
        refute move.powerBoost
    end
end
