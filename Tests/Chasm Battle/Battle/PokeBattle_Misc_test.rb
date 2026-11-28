require_relative "../../support/test_helper"

# The battle AI's calls, recorded in order, answering with the values given.
class RecordingBattleAI
    attr_reader :calls

    def initialize(score: 0, choice: nil, moves_first: false)
        @score = score
        @choice = choice
        @moves_first = moves_first
        @calls = []
    end

    def pbGetMoveScore(move, user, target, policies)
        @calls << [:pbGetMoveScore, move, user, target, policies]
        @score
    end

    def pbEvaluateMoveTrainer(user, move, random: false)
        @calls << [:pbEvaluateMoveTrainer, user, move, random]
        [@choice, nil]
    end

    def userMovesFirst?(move, user, target, killInfo: nil, targetPriority: nil) # rubocop:disable Lint/UnusedMethodArgument -- keyword names match the game's signature
        @calls << [:userMovesFirst?, move, user, target]
        @moves_first
    end
end

class SwitchOutTestMove < PokeBattle_Move
    def switchOutMove? = true
end

# aiSeesMove and aiKnownMoves (what the AI knows of a player Pokémon's moves), forceUseMove's AI
# check, and aiPredictsSwitch?.
class PokeBattleMiscTest < Minitest::Test
    PLAYER = 0
    FOE = 1

    def setup
        %i[TACKLE BITE].each { |id| create_move(id: id, total_pp: 1) }
        @auto_known = {}
    end

    def battle(**keywords)
        @battle = AITestBattle.new(auto_known_moves: @auto_known, **keywords)
    end

    # A battler whose Pokémon's personalID is its index. auto_known: the moves the AI knows of it
    # from the start.
    def battler(index: PLAYER, moves: [], auto_known: [], **keywords)
        battle if @battle.nil?
        @auto_known[index] = auto_known
        @battle.add_battler(index: index, pokemon: TestPokemon.new(personal_id: index),
                            moves: moves.map { |id| @battle.getBattleMoveInstanceFromID(id) }, **keywords)
    end

    def known(battler)
        @battle.aiKnownMoves(battler.pokemon)
    end

    def stored
        @battle.instance_variable_get(:@knownMoves)
    end

    # aiKnownMoves

    def test_known_moves_start_from_the_moves_the_ai_knows_from_the_start
        assert_equal %i[TACKLE], known(battler(auto_known: %i[TACKLE]))
    end

    def test_known_moves_are_set_up_once_and_kept
        b = battler(auto_known: %i[TACKLE])
        first = known(b)
        first.push(:BITE)

        assert_same first, known(b)
        assert_equal %i[TACKLE BITE], known(b)
    end

    # aiSeesMove

    def test_a_move_seen_before_the_ai_reads_the_pokemon_is_added_to_the_moves_it_starts_with
        b = battler(auto_known: %i[TACKLE])
        @battle.aiSeesMove(b, :BITE)

        assert_equal %i[TACKLE BITE], known(b)
    end

    def test_a_move_is_recorded_once
        b = battler
        2.times { @battle.aiSeesMove(b, :TACKLE) }

        assert_equal %i[TACKLE], known(b)
    end

    def test_a_move_object_is_recorded_by_id
        b = battler
        @battle.aiSeesMove(b, @battle.getBattleMoveInstanceFromID(:BITE))

        assert_equal %i[BITE], known(b)
    end

    def test_nothing_is_recorded_for_the_ai_side_or_a_boss
        foe = battler(index: FOE)
        boss = battler(index: 2, boss: true)
        @battle.aiSeesMove(foe, :TACKLE)
        @battle.aiSeesMove(boss, :TACKLE)

        assert_empty stored
    end

    def test_a_nil_move_is_ignored
        b = battler
        @battle.aiSeesMove(b, nil)

        assert_empty known(b)
    end

    # forceUseMove with aiCheck

    def test_ai_check_on_a_target_returns_the_move_score
        ai = RecordingBattleAI.new(score: 75)
        battle(battle_ai: ai)
        user = battler(moves: %i[TACKLE])
        target = battler(index: FOE)

        assert_equal 75, @battle.forceUseMove(user, 0, FOE, aiCheck: true)
        assert_equal [[:pbGetMoveScore, user.moves[0], user, target, []]], ai.calls
    end

    def test_ai_check_on_a_target_scores_a_move_given_by_id
        ai = RecordingBattleAI.new(score: 40)
        battle(battle_ai: ai)
        user = battler
        battler(index: FOE)

        assert_equal 40, @battle.forceUseMove(user, :BITE, FOE, aiCheck: true)
        assert_equal :BITE, ai.calls[0][1].id
    end

    def test_ai_check_passes_the_users_owners_policies
        ai = RecordingBattleAI.new
        battle(battle_ai: ai, opponent_policies: [:PREDICTS_PLAYER])
        user = battler(index: FOE, moves: %i[TACKLE])
        battler

        @battle.forceUseMove(user, 0, PLAYER, aiCheck: true)

        assert_equal [:PREDICTS_PLAYER], ai.calls[0][4]
    end

    def test_ai_check_without_a_target_returns_the_chosen_moves_score
        ai = RecordingBattleAI.new(choice: [60, FOE])
        battle(battle_ai: ai)
        user = battler(moves: %i[TACKLE])

        assert_equal 60, @battle.forceUseMove(user, 0, aiCheck: true)
        assert_equal [[:pbEvaluateMoveTrainer, user, user.moves[0], true]], ai.calls
    end

    def test_ai_check_without_a_target_is_zero_with_no_valid_targets
        battle(battle_ai: RecordingBattleAI.new(choice: nil))
        user = battler(moves: %i[TACKLE])

        assert_equal 0, @battle.forceUseMove(user, 0, aiCheck: true)
    end

    # aiPredictsSwitch?

    # The foe predicts the player's battler will take action.
    def predicting_battle(action, policies: [:PREDICTS_PLAYER], moves_first: false)
        @ai = RecordingBattleAI.new(moves_first: moves_first)
        battle(battle_ai: @ai, opponent_policies: policies, predicted_actions: [action])
        @player = battler
        @predictor = battler(index: FOE)
    end

    def use_move(move)
        [:UseMove, 0, move, FOE]
    end

    def switch_out_move
        make_move(SwitchOutTestMove, id: :SWITCHMOVE)
    end

    def test_predicts_a_switch_for_a_predicted_switch_out
        predicting_battle([:SwitchOut, 1])

        assert @battle.aiPredictsSwitch?(@predictor, PLAYER)
        assert @battle.aiPredictsSwitch?(@predictor, PLAYER, true)
    end

    def test_predicts_a_switch_for_a_predicted_switch_out_move
        predicting_battle(use_move(switch_out_move))

        assert @battle.aiPredictsSwitch?(@predictor, PLAYER)
        assert_empty @ai.calls
    end

    def test_only_before_predictor_counts_a_switch_out_move_that_goes_first
        move = switch_out_move
        predicting_battle(use_move(move), moves_first: true)

        assert @battle.aiPredictsSwitch?(@predictor, PLAYER, true)
        assert_equal [[:userMovesFirst?, move, @player, @predictor]], @ai.calls
    end

    def test_only_before_predictor_ignores_a_switch_out_move_that_goes_second
        predicting_battle(use_move(switch_out_move), moves_first: false)

        refute @battle.aiPredictsSwitch?(@predictor, PLAYER, true)
    end

    def test_predicts_no_switch_for_a_predicted_move_that_doesnt_switch
        predicting_battle(use_move(make_move(id: :STAYMOVE)))

        refute @battle.aiPredictsSwitch?(@predictor, PLAYER)
        refute @battle.aiPredictsSwitch?(@predictor, PLAYER, true)
    end

    def test_predicts_no_switch_for_another_action
        predicting_battle([:UseItem, :POTION])

        refute @battle.aiPredictsSwitch?(@predictor, PLAYER)
    end

    def test_predicts_no_switch_without_the_predicting_policy
        predicting_battle([:SwitchOut, 1], policies: [])

        refute @battle.aiPredictsSwitch?(@predictor, PLAYER)
    end

    def test_predicts_no_switch_without_a_prediction
        predicting_battle(nil)

        refute @battle.aiPredictsSwitch?(@predictor, PLAYER)
    end

    def test_predicts_no_switch_for_a_battler_the_player_doesnt_own
        @ai = RecordingBattleAI.new
        battle(battle_ai: @ai, opponent_policies: [:PREDICTS_PLAYER], predicted_actions: [nil, nil, nil, [:SwitchOut, 1]])
        predictor = battler(index: FOE)
        battler(index: 3)

        refute @battle.aiPredictsSwitch?(predictor, 3)
    end
end
