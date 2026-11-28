require_relative "../../support/test_helper"

# What the AI knows of a battler's moves, Insight Room's reveal included: aiKnowsMove?,
# eachAIKnownMove, eachAIKnownMoveWithIndex and aiSeesMove.
class BattlerAIHelpersTest < Minitest::Test
    LEARNSET = [[1, :TACKLE], [20, :BITE], [40, :CRUNCH], [45, :SLAM], [50, :GIMMICK]].freeze
    PLAYER = 0
    FOE = 1

    def setup
        LEARNSET.map(&:last).each { |id| create_move(id: id, total_pp: 1) }
        @auto_known = {}
        @battle = AITestBattle.new(auto_known_moves: @auto_known)
    end

    # A battler whose Pokémon's personalID is its index. auto_known: the moves the AI knows of it
    # from the start.
    def battler(moves, index: PLAYER, level: 60, learnset: LEARNSET, auto_known: [], **keywords)
        @auto_known[index] = auto_known
        @battle.add_battler(index: index, pokemon: TestPokemon.new(personal_id: index, learnset: learnset),
                            level: level, moves: moves.map { |id| @battle.getBattleMoveInstanceFromID(id) },
                            **keywords)
    end

    def room_up
        @battle.field.applyEffect(:InsightRoom, 5)
    end

    def room_ends
        @battle.field.disableEffect(:InsightRoom)
    end

    def known(battler)
        @battle.aiKnownMoves(battler.pokemon)
    end

    def ai_sees(battler)
        seen = []
        battler.eachAIKnownMove { |move| seen << move.id }
        seen
    end

    def hide_behind_illusion(battler, ai_knows_illusion:)
        battler.effects[:Illusion] = true
        battler.define_singleton_method(:aiKnowsIllusion?) { ai_knows_illusion }
    end

    # Without the room

    def test_ai_sees_only_the_player_moves_it_knows
        b = battler(%i[TACKLE BITE], auto_known: %i[BITE])

        assert_equal %i[BITE], ai_sees(b)
    end

    def test_ai_sees_every_move_of_its_own_side
        assert_equal %i[TACKLE BITE], ai_sees(battler(%i[TACKLE BITE], index: FOE))
    end

    def test_ai_knows_move_reads_the_known_moves
        b = battler(%i[TACKLE BITE], auto_known: %i[BITE])

        refute b.aiKnowsMove?(b.moves[0])
        assert b.aiKnowsMove?(b.moves[1])
    end

    def test_with_index_gives_each_known_moves_index
        b = battler(%i[TACKLE BITE CRUNCH], auto_known: %i[TACKLE CRUNCH])
        seen = []
        b.eachAIKnownMoveWithIndex { |move, index| seen << [move.id, index] }

        assert_equal [[:TACKLE, 0], [:CRUNCH, 2]], seen
    end

    def test_empty_move_slots_are_skipped
        b = battler(%i[TACKLE], index: FOE)
        b.moves.push(nil)

        assert_equal %i[TACKLE], ai_sees(b)
    end

    # The reveal while the room is up

    def test_reveals_the_fifth_move_without_storing_it
        b = battler(%i[TACKLE])
        room_up

        assert_equal %i[SLAM], ai_sees(b)
        assert_empty known(b)
    end

    def test_reveal_keeps_the_fifth_moves_index
        b = battler(%i[TACKLE BITE])
        room_up
        seen = []
        b.eachAIKnownMoveWithIndex { |move, index| seen << [move.id, index] }

        assert_equal [[:SLAM, 2]], seen
    end

    def test_reveals_to_a_battler_entering_while_the_room_is_up
        room_up

        assert_equal %i[SLAM], ai_sees(battler(%i[TACKLE]))
    end

    def test_reveals_a_move_the_battler_has_without_storing_it
        b = battler(%i[SLAM])
        room_up

        assert_equal %i[SLAM], ai_sees(b)
        assert_empty known(b)
    end

    def test_reveal_skips_moves_the_ai_already_knows
        b = battler(%i[TACKLE SLAM], auto_known: %i[SLAM])
        room_up

        assert_equal %i[SLAM CRUNCH], ai_sees(b)
    end

    def test_no_reveal_when_nothing_is_eligible
        b = battler(%i[TACKLE], level: 10, learnset: [[20, :BITE]])
        room_up

        assert_empty ai_sees(b)
    end

    def test_room_only_move_is_forgotten_when_the_room_ends
        b = battler(%i[TACKLE])
        room_up
        ai_sees(b)
        room_ends

        assert_empty ai_sees(b)
    end

    def test_move_the_battler_has_anyway_is_forgotten_when_the_room_ends
        b = battler(%i[SLAM])
        room_up
        ai_sees(b)
        room_ends

        assert_empty ai_sees(b)
    end

    def test_ai_side_sees_every_move_and_stores_nothing
        b = battler(%i[TACKLE], index: FOE)
        room_up

        assert_equal %i[TACKLE SLAM], ai_sees(b)
        assert_empty @battle.instance_variable_get(:@knownMoves)
    end

    def test_boss_is_shown_the_reveal_without_storing_it
        b = battler(%i[SLAM], boss: true)
        room_up

        assert_equal %i[SLAM], ai_sees(b)
        assert_empty known(b)
    end

    # Illusion

    def test_illusion_hides_every_move_while_the_ai_doesnt_know_of_it
        b = battler(%i[TACKLE], auto_known: %i[TACKLE])
        hide_behind_illusion(b, ai_knows_illusion: false)
        room_up

        assert_empty ai_sees(b)
    end

    def test_illusion_hides_nothing_once_the_ai_knows_of_it
        b = battler(%i[TACKLE], auto_known: %i[TACKLE])
        hide_behind_illusion(b, ai_knows_illusion: true)
        room_up

        assert_equal %i[TACKLE SLAM], ai_sees(b)
    end

    # aiSeesMove

    def test_ai_sees_move_records_the_move_on_the_battle
        b = battler(%i[TACKLE BITE], auto_known: %i[TACKLE])
        b.aiSeesMove(:BITE)

        assert_equal %i[TACKLE BITE], known(b)
        assert_equal %i[TACKLE BITE], ai_sees(b)
    end
end
