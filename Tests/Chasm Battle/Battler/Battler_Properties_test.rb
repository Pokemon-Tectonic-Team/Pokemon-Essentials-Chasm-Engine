require_relative "../../support/test_helper"

# Insight Room's fifth move: getMoves, getInsightRoomMove and getHighestLearnsetMoveID.
class BattlerPropertiesTest < Minitest::Test
    LEARNSET = [[1, :TACKLE], [20, :BITE], [40, :CRUNCH], [45, :SLAM], [50, :GIMMICK]].freeze

    def setup
        (LEARNSET.map(&:last) + [:JUDGMENT]).each { |id| create_move(id: id, total_pp: 1) }
        @battle = AITestBattle.new
    end

    def battler(moves, level: 60, learnset: LEARNSET, **keywords)
        @battle.add_battler(pokemon: TestPokemon.new(learnset: learnset), level: level,
                            moves: moves.map { |id| @battle.getBattleMoveInstanceFromID(id) }, **keywords)
    end

    def room_up
        @battle.field.applyEffect(:InsightRoom, 5)
    end

    def move_ids(battler)
        battler.getMoves.map(&:id)
    end

    # getMoves

    def test_no_fifth_move_without_the_room
        assert_equal %i[TACKLE], move_ids(battler(%i[TACKLE]))
    end

    def test_fifth_move_is_the_highest_at_or_below_45_never_above
        b = battler(%i[TACKLE])
        room_up

        assert_equal %i[TACKLE SLAM], move_ids(b)
    end

    def test_fifth_move_is_a_real_battle_move
        b = battler(%i[TACKLE])
        room_up

        assert_kind_of PokeBattle_Move, b.getMoves.last
    end

    def test_fifth_move_skips_a_move_the_battler_has
        b = battler(%i[SLAM])
        room_up

        assert_equal %i[SLAM CRUNCH], move_ids(b)
    end

    def test_fifth_move_skips_a_move_an_ability_adds
        b = battler(%i[TACKLE], abilities: [:HIGHJUDGE], learnset: LEARNSET + [[45, :JUDGMENT]])
        room_up

        assert_equal %i[TACKLE JUDGMENT SLAM], move_ids(b)
    end

    def test_fifth_move_below_the_cap_is_capped_at_the_battlers_level
        b = battler(%i[TACKLE], level: 30)
        room_up

        assert_equal %i[TACKLE BITE], move_ids(b)
    end

    def test_no_fifth_move_when_nothing_is_eligible
        b = battler(%i[TACKLE], level: 10)
        room_up

        assert_equal %i[TACKLE], move_ids(b)
    end

    def test_no_fifth_move_without_a_pokemon
        b = battler(%i[TACKLE])
        b.instance_variable_set(:@pokemon, nil)
        room_up

        assert_equal %i[TACKLE], move_ids(b)
    end

    def test_fifth_move_is_not_added_to_the_battlers_own_moves
        b = battler(%i[TACKLE])
        room_up
        b.getMoves

        assert_equal %i[TACKLE], b.moves.map(&:id)
    end

    def test_fifth_move_goes_when_the_room_ends
        b = battler(%i[TACKLE])
        room_up
        @battle.field.disableEffect(:InsightRoom)

        assert_equal %i[TACKLE], move_ids(b)
    end

    # getInsightRoomMove

    def test_insight_room_move_skips_the_moves_given
        b = battler(%i[TACKLE])

        assert_equal :SLAM, b.getInsightRoomMove
        assert_equal :CRUNCH, b.getInsightRoomMove(%i[SLAM])
        assert_nil b.getInsightRoomMove(LEARNSET.map(&:last))
    end

    # getHighestLearnsetMoveID

    def test_highest_learnset_move_uncapped_is_at_or_below_the_battlers_level
        assert_equal :GIMMICK, battler([]).getHighestLearnsetMoveID
        assert_equal :CRUNCH, battler([], level: 44).getHighestLearnsetMoveID
    end

    def test_highest_learnset_move_counts_a_move_at_the_threshold
        assert_equal :SLAM, battler([], level: 45).getHighestLearnsetMoveID
        assert_equal :SLAM, battler([]).getHighestLearnsetMoveID(45)
    end

    def test_highest_learnset_move_takes_the_lower_of_cap_and_level
        assert_equal :BITE, battler([], level: 30).getHighestLearnsetMoveID(45)
        assert_equal :BITE, battler([]).getHighestLearnsetMoveID(39)
    end

    def test_highest_learnset_move_skips_excluded_moves
        assert_equal :SLAM, battler([]).getHighestLearnsetMoveID(nil, %i[GIMMICK])
    end

    def test_highest_learnset_move_is_nil_when_none_qualifies
        assert_nil battler([], level: 10).getHighestLearnsetMoveID(nil, %i[TACKLE])
        assert_nil battler([], learnset: []).getHighestLearnsetMoveID
    end

    def test_highest_learnset_move_is_nil_without_a_pokemon
        b = battler([])
        b.instance_variable_set(:@pokemon, nil)

        assert_nil b.getHighestLearnsetMoveID
    end
end
