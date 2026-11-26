require_relative "../support/test_helper"

class MoveFactoryTest < Minitest::Test
    def test_make_move_returns_an_instance_of_the_class_given
        move = make_move(PokeBattle_Move_TargetActsLast)

        assert_instance_of PokeBattle_Move_TargetActsLast, move
    end

    def test_make_move_defaults_to_the_base_move_class
        assert_instance_of PokeBattle_Move, make_move
    end

    def test_the_battle_given_is_the_moves_battle
        battle = TestBattle.new

        assert_same battle, make_move(battle: battle).battle
    end

    def test_a_record_field_reaches_the_move
        assert make_move(flags: ["Sound"]).soundMove?
        refute make_move(id: :OTHERMOVE).soundMove?
    end

    def test_the_record_has_one_total_pp
        assert_equal 1, make_move.total_pp
    end

    def test_attrs_reach_the_record
        assert_equal 40, make_move(base_damage: 40).baseDamage
    end

    def test_the_default_id_is_testmove
        assert_equal :TESTMOVE, make_move.id
    end

    def test_an_id_given_is_used
        assert_equal :EMBER, make_move(id: :EMBER).id
    end
end
