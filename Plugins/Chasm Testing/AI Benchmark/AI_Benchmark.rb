#==============================================================================
# AI Heuristic Benchmarking Framework
#
# Runs head-to-head battles between trainers using different move-prediction
# heuristics, measuring win rate and battle timing.
#
# Usage (from debug menu or console):
#   pbRunAIBenchmark(:current, :baseline, n_battles: 200)
#
# Built-in heuristics:
#   :current  - This branch's signature > STAB > highest-level guess
#   :baseline - Peeks at the opponent's real STAB moves (simulates pre-branch
#               "cheat knowledge" where the AI knew STAB damaging moves)
#   :empty    - No initial guess; AI learns only from observed moves
#==============================================================================

#==============================================================================
# Suppress debug output during benchmark battles
# echoln is a built-in that triggers screen refreshes; silencing it is
# essential for benchmark speed.
#==============================================================================
$aiBenchmarkRunning = false

alias :echoln_preBenchmark :echoln
def echoln(msg)
    return if $aiBenchmarkRunning
    echoln_preBenchmark(msg)
end

# The global pbLearnMove (used by form-change handlers) shows UI and waits for
# input when a pokemon is at max moves. Silence it during benchmark battles by
# auto-replacing slot 0 instead.
alias :pbMessage_preBenchmark :pbMessage
def pbMessage(msg, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
    return cmdIfCancel if $aiBenchmarkRunning
    pbMessage_preBenchmark(msg, commands, cmdIfCancel, skin, defaultCmd, &block)
end

alias :showPartyHealing_preBenchmark :showPartyHealing
def showPartyHealing(party, previousHealthValues, previousStatusIndices = nil)
    return if $aiBenchmarkRunning
    showPartyHealing_preBenchmark(party, previousHealthValues, previousStatusIndices)
end

alias :pbLearnMove_preBenchmark :pbLearnMove
def pbLearnMove(pkmn, move, ignoreifknown = false, bymachine = false, addfirstmove = false, &block)
    return pbLearnMove_preBenchmark(pkmn, move, ignoreifknown, bymachine, addfirstmove, &block) unless $aiBenchmarkRunning
    return false unless pkmn
    move = GameData::Move.get(move).id
    return false if pkmn.egg?
    return false if pkmn.hasMove?(move)
    if pkmn.numMoves < Pokemon::MAX_MOVES
        pkmn.learn_move(move)
    else
        pkmn.moves[0] = Pokemon::Move.new(move)
    end
    true
end

#==============================================================================
# PokeBattle_Battle extensions for benchmark mode
#==============================================================================
class PokeBattle_Battle
    attr_accessor :benchmarkMode        # true when running a benchmark battle
    attr_accessor :moveGuessHeuristics  # { 0 => proc(pokemon, battle), 1 => proc }

    alias_method :buildInitialMoveGuess_preHeuristic, :buildInitialMoveGuess

    # In benchmark mode, delegate to the heuristic assigned to each side.
    # Called for both party1 and party2 pokemon during initializeKnownMoves.
    def buildInitialMoveGuess(pokemon, use_other_moves = false)
        if @benchmarkMode && @moveGuessHeuristics
            side = @party1.include?(pokemon) ? 0 : 1
            heuristic = @moveGuessHeuristics[side]
            return heuristic.call(pokemon, self) if heuristic
        end
        buildInitialMoveGuess_preHeuristic(pokemon, use_other_moves)
    end

    alias_method :pbSetSeen_preBenchmark, :pbSetSeen

    # pbSetSeen calls pbPlayer.pokedex, which doesn't exist on NPCTrainer.
    def pbSetSeen(battler)
        return if @benchmarkMode
        pbSetSeen_preBenchmark(battler)
    end

    alias_method :aiSeesMove_preBenchmark, :aiSeesMove

    # In benchmark mode, extend move-learning to trainer-owned battlers as well.
    # Normally gated to player-owned battlers only.
    def aiSeesMove(battler, moveID)
        if @benchmarkMode && !battler.pbOwnedByPlayer?
            moveID = moveID.id if moveID.is_a?(PokeBattle_Move)
            pokemon    = battler.pokemon
            personalID = pokemon.personalID
            initializeKnownMoves(pokemon) unless @definiteMoveKnowledge.include?(personalID)
            definiteKnowledge = @definiteMoveKnowledge[personalID]
            unless definiteKnowledge.include?(moveID)
                definiteKnowledge.push(moveID)
                rebuildCurrentBestGuess(battler)
            end
        else
            aiSeesMove_preBenchmark(battler, moveID)
        end
    end
end

#==============================================================================
# PokeBattle_Battler extensions for benchmark mode
#==============================================================================
class PokeBattle_Battler
    alias_method :eachAIKnownMove_preBenchmark, :eachAIKnownMove

    # In benchmark mode, trainer-owned battlers also iterate guessed moves
    # (i.e. the opposing side's AI sees only its guess about this battler's moves).
    def eachAIKnownMove
        if @battle.benchmarkMode && !pbOwnedByPlayer?
            return if movesHiddenByIllusion?
            eachGuessedMove { |m| yield m }
        else
            eachAIKnownMove_preBenchmark { |m| yield m }
        end
    end

    alias_method :increaseMoveUsageCount_preBenchmark, :increaseMoveUsageCount

    # Hook move-usage tracking to notify the AI about trainer-side moves in
    # benchmark mode. The normal aiSeesMove call in Battler_UseMove.rb is
    # gated to player-owned battlers, so we piggyback on the unconditional
    # usage counter to cover the trainer side.
    def increaseMoveUsageCount(moveID)
        if @battle.benchmarkMode && !pbOwnedByPlayer? && !boss? && !@battle.specialUsage
            @battle.aiSeesMove(self, moveID)
        end
        increaseMoveUsageCount_preBenchmark(moveID)
    end
end

#==============================================================================
# AIBenchmark module
#==============================================================================
module AIBenchmark
    #--------------------------------------------------------------------------
    # Heuristic definitions
    # Each is a lambda: (pokemon, battle) -> Array of move IDs
    #--------------------------------------------------------------------------

    # Current branch heuristic: signature moves > highest-level STAB > other.
    # Delegates directly to the original buildInitialMoveGuess implementation.
    HEURISTIC_CURRENT = ->(pokemon, battle) {
        battle.buildInitialMoveGuess_preHeuristic(pokemon)
    }

    # Same as HEURISTIC_CURRENT but also fills remaining slots with the
    # highest-level non-STAB level-up moves (use_other_moves: true).
    HEURISTIC_CURRENT_WITH_OTHERS = ->(pokemon, battle) {
        battle.buildInitialMoveGuess_preHeuristic(pokemon, true)
    }

    # Baseline / pre-branch: peek at the pokemon's actual moves and keep the
    # STAB-typed damaging ones that aiAutoKnowsMove? would have included.
    # This replicates the old "cheat knowledge" behaviour.
    HEURISTIC_BASELINE = ->(pokemon, battle) {
        pokemon.moves.compact.select { |m| battle.aiAutoKnowsMove?(m, pokemon) }.map(&:id)
    }

    # Null heuristic: no initial guess at all.
    HEURISTIC_EMPTY = ->(_pokemon, _battle) { [] }

    HEURISTICS = {
        current:              HEURISTIC_CURRENT,
        current_with_others:  HEURISTIC_CURRENT_WITH_OTHERS,
        baseline:             HEURISTIC_BASELINE,
        empty:                HEURISTIC_EMPTY,
    }

    #--------------------------------------------------------------------------
    # Result type
    #--------------------------------------------------------------------------
    BenchmarkResult = Struct.new(
        :test_heuristic, :baseline_heuristic,
        :test_wins, :baseline_wins, :draws, :total,
        :total_time_s, :avg_rounds, :seed
    )

    #--------------------------------------------------------------------------
    # Team sampling
    #--------------------------------------------------------------------------
    def self.buildTrainerPool
        pool = []
        GameData::Trainer.each do |td|
            trainer = td.to_trainer
            next if trainer.able_party.length < 2
            next if trainer.policies.any? { |p| p.to_s.start_with?("CURSE_") }
            pool.push(td)
        end
        pool
    end

    #--------------------------------------------------------------------------
    # Single benchmark battle
    #
    # Returns { result: 0|1|2, rounds: N, time_s: F }
    # result: 1 = test side (party1) wins, 2 = baseline side (party2) wins,
    #         0 = draw / timeout
    #--------------------------------------------------------------------------
    def self.runBattle(trainerData1, trainerData2, heuristic1, heuristic2)
        trainer1 = trainerData1.to_trainer
        trainer2 = trainerData2.to_trainer
        party1 = trainer1.party
        party2 = trainer2.party

        $aiBenchmarkRunning = true
        t_start = Time.now.to_f

        scene  = PokeBattle_DebugSceneNoLogging.new
        battle = PokeBattle_TectonicRecordedBattle.new(
            scene, party1, party2, [trainer1], [trainer2], 1
        )
        battle.party1starts    = [0]
        battle.party2starts    = [0]
        battle.autoTesting     = true
        battle.controlPlayer   = true
        battle.expGain         = false
        battle.moneyGain       = false
        battle.showAnims       = false
        battle.save_battle     = false

        battle.benchmarkMode        = true
        battle.moveGuessHeuristics  = { 0 => heuristic1, 1 => heuristic2 }

        # Re-initialise move knowledge so both parties use the assigned heuristics.
        # The constructor already called initializeKnownMoves before benchmarkMode
        # was set, so we redo it now with the correct heuristics in place.
        party1.each { |p| battle.initializeKnownMoves(p) }
        party2.each { |p| battle.initializeKnownMoves(p) }

        result  = battle.pbStartBattle
        $aiBenchmarkRunning = false
        elapsed = Time.now.to_f - t_start

        { result: result, rounds: battle.turnCount, time_s: elapsed }
    end

    #--------------------------------------------------------------------------
    # Full benchmark run
    #
    # Uses a paired design: each trainer matchup is run twice with heuristics
    # swapped across sides. This cancels both positional bias and matchup
    # variance, making the results roughly twice as informative per battle
    # compared to an unpaired design.
    # n_battles is rounded down to the nearest even number.
    #--------------------------------------------------------------------------
    def self.run(test_key, baseline_key, n_battles: 100, seed: 0)
        test_heuristic     = HEURISTICS[test_key]     or raise "Unknown heuristic: #{test_key}"
        baseline_heuristic = HEURISTICS[baseline_key] or raise "Unknown heuristic: #{baseline_key}"

        echoln("[BENCHMARK] Building trainer pool...")
        pool = buildTrainerPool
        if pool.length < 2
            echoln("[BENCHMARK] Not enough trainers in pool (need >= 2). Aborting.")
            return nil
        end

        n_pairs        = n_battles / 2
        actual_battles = n_pairs * 2
        rng            = Random.new(seed)
        echoln("[BENCHMARK] Pool has #{pool.length} trainers. Seed: #{seed}")
        echoln("[BENCHMARK] Starting #{n_pairs} paired matchups (#{actual_battles} battles): #{test_key} vs #{baseline_key}")

        test_wins     = 0
        baseline_wins = 0
        draws         = 0
        total_time    = 0.0
        total_rounds  = 0

        n_pairs.times do |i|
            t1, t2 = pool.sample(2, random: rng)

            # Battle A: test on side 0, baseline on side 1
            a = runBattle(t1, t2, test_heuristic, baseline_heuristic)
            # Battle B: same trainers, sides swapped — cancels positional bias
            b = runBattle(t1, t2, baseline_heuristic, test_heuristic)

            total_time   += a[:time_s]   + b[:time_s]
            total_rounds += a[:rounds]   + b[:rounds]

            case a[:result]
            when 1 then test_wins     += 1
            when 2 then baseline_wins += 1
            else        draws         += 1
            end
            # In battle B the sides are inverted, so result 1 = baseline wins
            case b[:result]
            when 1 then baseline_wins += 1
            when 2 then test_wins     += 1
            else        draws         += 1
            end

            battles_done = (i + 1) * 2
            interval = [2, (actual_battles / 10.0).ceil].max
            if battles_done % interval == 0 || battles_done == actual_battles
                echoln("[BENCHMARK] #{battles_done}/#{actual_battles} battles done " \
                       "(#{test_key}: #{test_wins}, #{baseline_key}: #{baseline_wins}, draws: #{draws})")
                $stdout.flush
            end
        end

        result = BenchmarkResult.new(
            test_key, baseline_key,
            test_wins, baseline_wins, draws, actual_battles,
            total_time, (total_rounds.to_f / actual_battles).round(1), seed
        )
        printResults(result)
        result
    end

    #--------------------------------------------------------------------------
    # Output
    #--------------------------------------------------------------------------
    def self.printResults(r)
        bar = "=" * 52
        pct = ->(n) { "#{n} (#{(n * 100.0 / r.total).round(1)}%)" }
        lines = [
            bar,
            "  AI BENCHMARK RESULTS",
            "  Test:     #{r.test_heuristic}",
            "  Baseline: #{r.baseline_heuristic}",
            "  Seed:     #{r.seed}",
            bar,
            "  Battles run:        #{r.total}",
            "  Test wins:          #{pct.(r.test_wins)}",
            "  Baseline wins:      #{pct.(r.baseline_wins)}",
            "  Draws / timeouts:   #{pct.(r.draws)}",
            "  Avg rounds/battle:  #{r.avg_rounds}",
            "  Total time:         #{r.total_time_s.round(1)}s",
            "  Avg ms/battle:      #{(r.total_time_s / r.total * 1000).round(1)}",
            bar,
        ]
        lines.each { |line| echoln(line.gsub("%", "%%")) }
        path = "Analysis/benchmark_#{r.test_heuristic}_#{r.baseline_heuristic}.txt"
        File.open(path, "w") { |f| f.puts(lines) }
    end
end

#==============================================================================
# Global entry point
#==============================================================================
def pbRunAIBenchmark(test = :current, baseline = :baseline, n_battles: 100, seed: 0)
    AIBenchmark.run(test, baseline, n_battles: n_battles, seed: seed)
end
