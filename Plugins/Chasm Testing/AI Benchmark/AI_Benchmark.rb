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
#   :current              - This branch's signature > STAB > highest-level guess
#   :current_with_others  - Same, but fills remaining slots with highest non-STAB moves
#   :baseline             - Peeks at the opponent's real STAB moves (simulates pre-branch
#                           "cheat knowledge" where the AI knew STAB damaging moves)
#   :empty                - No initial guess; AI learns only from observed moves
#   :lut_cap              - Precomputed LUT, one entry per level-cap step (coarse)
#   :lut_move             - Precomputed LUT, one entry per STAB/signature learn level (fine)
#
# The two LUT heuristics also report their memory footprint in the results.
#==============================================================================

#==============================================================================
# Suppress debug output during benchmark battles
# echoln is a built-in that triggers screen refreshes; silencing it is
# essential for benchmark speed.
#==============================================================================
$aiBenchmarkRunning = false

unless respond_to?(:echoln_preBenchmark, true)
    alias :echoln_preBenchmark :echoln
    def echoln(msg)
        return if $aiBenchmarkRunning
        echoln_preBenchmark(msg)
    end
end

# The global pbLearnMove (used by form-change handlers) shows UI and waits for
# input when a pokemon is at max moves. Silence it during benchmark battles by
# auto-replacing slot 0 instead.
unless respond_to?(:pbMessage_preBenchmark, true)
    alias :pbMessage_preBenchmark :pbMessage
    def pbMessage(msg, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
        return cmdIfCancel if $aiBenchmarkRunning
        pbMessage_preBenchmark(msg, commands, cmdIfCancel, skin, defaultCmd, &block)
    end
end

unless respond_to?(:showPartyHealing_preBenchmark, true)
    alias :showPartyHealing_preBenchmark :showPartyHealing
    def showPartyHealing(party, previousHealthValues, previousStatusIndices = nil)
        return if $aiBenchmarkRunning
        showPartyHealing_preBenchmark(party, previousHealthValues, previousStatusIndices)
    end
end

unless respond_to?(:pbLearnMove_preBenchmark, true)
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

    # STAB-only: like current but ignores signature moves entirely.
    HEURISTIC_STAB_ONLY = ->(pokemon, _battle) {
        stab_by_type = {}
        pokemon.getMoveList.each do |lv, moveID|
            next if lv > pokemon.level
            moveData = GameData::Move.get(moveID)
            next if moveData.is_signature?
            stab_by_type[moveData.type] = moveID if pokemon.likelyHasSTAB?(moveData.type)
        end
        stab_by_type.values.take(4)
    }

    # Current + aiAutoKnows: current guess plus any level-up move that
    # aiAutoKnowsMove? considers automatically known (FLEX type, move-defined
    # overrides, etc.), up to the 4-move cap.
    HEURISTIC_CURRENT_WITH_AUTOKNOW = ->(pokemon, battle) {
        guess = battle.buildInitialMoveGuess_preHeuristic(pokemon).dup
        pokemon.getMoveList.each do |lv, moveID|
            break if guess.length >= 4
            next if lv > pokemon.level
            next if guess.include?(moveID)
            moveData = GameData::Move.get(moveID)
            guess.push(moveID) if battle.aiAutoKnowsMove?(moveData, pokemon)
        end
        guess.take(4)
    }

    # LUT heuristic (coarse): one precomputed entry per level-cap step.
    # Lookup snaps the pokemon's level down to the nearest cap boundary.
    HEURISTIC_LUT_CAP = ->(pokemon, _battle) {
        AIBenchmark.lookupLUT_cap(AIBenchmark.getLUT_cap, pokemon)
    }

    # LUT heuristic (fine): one precomputed entry per level where the guess
    # changes due to a new STAB/signature move.  Direct array-index lookup.
    HEURISTIC_LUT_MOVE = ->(pokemon, _battle) {
        AIBenchmark.lookupLUT_move(AIBenchmark.getLUT_move, pokemon)
    }

    HEURISTICS = {
        current:                   HEURISTIC_CURRENT,
        current_with_others:       HEURISTIC_CURRENT_WITH_OTHERS,
        current_with_autoknow:     HEURISTIC_CURRENT_WITH_AUTOKNOW,
        stab_only:                 HEURISTIC_STAB_ONLY,
        baseline:                  HEURISTIC_BASELINE,
        empty:                     HEURISTIC_EMPTY,
        lut_cap:                   HEURISTIC_LUT_CAP,
        lut_move:                  HEURISTIC_LUT_MOVE,
    }

    #--------------------------------------------------------------------------
    # Result type
    #--------------------------------------------------------------------------
    BenchmarkResult = Struct.new(
        :test_heuristic, :baseline_heuristic,
        :test_swings, :baseline_swings, :unchanged, :total_experiment,
        :newly_run_ctrl, :cached_ctrl,
        :total_time_s, :exp_time_s, :avg_rounds, :seed,
        :swings,
        :lut_bytes  # Hash { heuristic_key => serialized_bytes } for LUT heuristics, else nil
    )

    SwingRecord = Struct.new(:t1_label, :t2_label, :ctrl_result, :exp_result, :test_side, :for_test)

    #--------------------------------------------------------------------------
    # Team sampling
    #--------------------------------------------------------------------------
    def self.trainerLabel(td)
        label = "#{td.name} (#{td.trainer_type})"
        label += " \##{td.version}" if td.version > 0
        label
    end

    def self.buildTrainerPool
        pool = []
        GameData::Trainer.each do |td|
            trainer = td.to_trainer
            next if trainer.party.length != 6
            next if trainer.party.any? { |p| p.level != 70 }
            next if trainer.policies.any? { |p| p.to_s.start_with?("CURSE_") }
            pool.push(td)
        end
        pool
    end

    #--------------------------------------------------------------------------
    # Control-result cache
    #
    # Baseline-vs-baseline results are expensive and reusable across benchmark
    # runs. They are cached on disk keyed by [seed, pool fingerprint] so
    # subsequent runs only add new control battles when n_pairs exceeds what
    # was previously cached.
    #--------------------------------------------------------------------------
    CTRL_CACHE_PATH = "Analysis/benchmark_ctrl_cache.dat"

    # Stable integer fingerprint for the ordered pool (DJB2 hash, process-safe).
    # Order matters because it determines which trainers the seeded RNG selects.
    def self.poolFingerprint(pool)
        str = pool.map { |td| "#{td.trainer_type}:#{td.name}:#{td.version}" }.join("|")
        str.bytes.reduce(5381) { |h, b| ((h << 5) + h) ^ b }
    end

    def self.loadCtrlCache
        return {} unless File.exist?(CTRL_CACHE_PATH)
        Marshal.load(File.binread(CTRL_CACHE_PATH))
    rescue
        {}
    end

    def self.saveCtrlCache(cache)
        File.binwrite(CTRL_CACHE_PATH, Marshal.dump(cache))
    end

    # Deterministic per-pair RNG seed derived from the global seed and pair index.
    # All three battles for a pair (ctrl, exp A, exp B) use the same value so
    # they experience identical random events — Common Random Numbers technique.
    def self.battleSeed(seed, pair_index)
        seed * 100_000 + pair_index
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
    # Uses a control + paired design: each matchup is run three times.
    # A control battle (baseline vs baseline) establishes the "natural"
    # outcome for the teams involved. Two experiment battles (test vs baseline,
    # sides swapped) are then each compared to the control to measure how
    # often the test heuristic changed the outcome, and in which direction.
    # This isolates the AI's contribution from team-quality effects.
    # n_battles controls the number of experiment battles and is rounded
    # down to the nearest even number; one additional control battle is run
    # per matched pair.
    #--------------------------------------------------------------------------
    def self.run(test_key, baseline_key, n_battles: 100, seed: 0)
        test_heuristic     = HEURISTICS[test_key]     or raise "Unknown heuristic: #{test_key}"
        baseline_heuristic = HEURISTICS[baseline_key] or raise "Unknown heuristic: #{baseline_key}"

        # Pre-build any LUT-based heuristics before battles start so that build
        # time is separate from per-battle timing, and so we can measure memory.
        lut_bytes = {}
        [test_key, baseline_key].uniq.each do |key|
            case key
            when :lut_cap
                lut = getLUT_cap
                lut_bytes[key] = Marshal.dump(lut).bytesize
            when :lut_move
                lut = getLUT_move
                lut_bytes[key] = Marshal.dump(lut).bytesize
            end
        end
        lut_bytes = nil if lut_bytes.empty?

        echoln("[BENCHMARK] Building trainer pool...")
        pool = buildTrainerPool
        if pool.length < 2
            echoln("[BENCHMARK] Not enough trainers in pool (need >= 2). Aborting.")
            return nil
        end

        n_pairs          = n_battles / 2
        total_experiment = n_pairs * 2
        rng              = Random.new(seed)
        echoln("[BENCHMARK] Pool has #{pool.length} trainers. Seed: #{seed}")

        # Pre-generate all trainer pairs from the seed. The same sequence is
        # used for both control lookups and the experiment battles.
        pairs = Array.new(n_pairs) { pool.sample(2, random: rng) }

        # Load control cache and run any entries missing for this seed + pool.
        ctrl_cache   = loadCtrlCache
        cache_key    = [seed, baseline_key, poolFingerprint(pool)]
        ctrl_results = (ctrl_cache[cache_key] || []).first(n_pairs)
        cached_ctrl  = ctrl_results.length
        newly_run_ctrl = 0
        ctrl_time      = 0.0
        ctrl_rounds    = 0

        if ctrl_results.length < n_pairs
            missing = n_pairs - ctrl_results.length
            echoln("[BENCHMARK] Running #{missing} control battles (#{cached_ctrl} already cached)...")
            start_idx = ctrl_results.length
            pairs[start_idx...n_pairs].each_with_index do |(t1, t2), j|
                srand(battleSeed(seed, start_idx + j))
                ctrl = runBattle(t1, t2, baseline_heuristic, baseline_heuristic)
                ctrl_results   << ctrl[:result]
                ctrl_time      += ctrl[:time_s]
                ctrl_rounds    += ctrl[:rounds]
                newly_run_ctrl += 1
            end
            ctrl_cache[cache_key] = ctrl_results
            saveCtrlCache(ctrl_cache)
        else
            echoln("[BENCHMARK] Using #{n_pairs} cached control results.")
        end

        echoln("[BENCHMARK] Starting #{n_pairs} matchups " \
               "(#{total_experiment} experiment battles): #{test_key} vs #{baseline_key}")

        test_swings     = 0
        baseline_swings = 0
        unchanged       = 0
        exp_time        = 0.0
        exp_rounds      = 0
        swing_records   = []

        n_pairs.times do |i|
            t1, t2      = pairs[i]
            ctrl_result = ctrl_results[i]
            t1_label    = trainerLabel(t1)
            t2_label    = trainerLabel(t2)
            b_seed      = battleSeed(seed, i)

            # Experiment A: test on side 0, baseline on side 1
            srand(b_seed)
            a = runBattle(t1, t2, test_heuristic,     baseline_heuristic)
            # Experiment B: sides swapped — cancels positional bias
            srand(b_seed)
            b = runBattle(t1, t2, baseline_heuristic, test_heuristic)

            exp_time   += a[:time_s] + b[:time_s]
            exp_rounds += a[:rounds] + b[:rounds]

            # Compare experiment A to control (test is on side 0)
            if a[:result] == ctrl_result
                unchanged += 1
            elsif a[:result] == 1   # test side won
                test_swings += 1
                swing_records << SwingRecord.new(t1_label, t2_label, ctrl_result, a[:result], 0, true)
            elsif a[:result] == 2   # baseline side won
                baseline_swings += 1
                swing_records << SwingRecord.new(t1_label, t2_label, ctrl_result, a[:result], 0, false)
            elsif ctrl_result == 1  # draw; test had been winning — regressed
                baseline_swings += 1
                swing_records << SwingRecord.new(t1_label, t2_label, ctrl_result, a[:result], 0, false)
            else                    # draw; baseline had been winning — improved
                test_swings += 1
                swing_records << SwingRecord.new(t1_label, t2_label, ctrl_result, a[:result], 0, true)
            end

            # Compare experiment B to control (test is on side 1)
            if b[:result] == ctrl_result
                unchanged += 1
            elsif b[:result] == 2   # test side won
                test_swings += 1
                swing_records << SwingRecord.new(t1_label, t2_label, ctrl_result, b[:result], 1, true)
            elsif b[:result] == 1   # baseline side won
                baseline_swings += 1
                swing_records << SwingRecord.new(t1_label, t2_label, ctrl_result, b[:result], 1, false)
            elsif ctrl_result == 2  # draw; test had been winning — regressed
                baseline_swings += 1
                swing_records << SwingRecord.new(t1_label, t2_label, ctrl_result, b[:result], 1, false)
            else                    # draw; baseline had been winning — improved
                test_swings += 1
                swing_records << SwingRecord.new(t1_label, t2_label, ctrl_result, b[:result], 1, true)
            end

            battles_done = (i + 1) * 2
            interval = [2, (total_experiment / 10.0).ceil].max
            if battles_done % interval == 0 || battles_done == total_experiment
                echoln("[BENCHMARK] #{battles_done}/#{total_experiment} experiment battles done " \
                       "(test swings: #{test_swings}, baseline swings: #{baseline_swings}, unchanged: #{unchanged})")
                $stdout.flush
            end
        end

        result = BenchmarkResult.new(
            test_key, baseline_key,
            test_swings, baseline_swings, unchanged, total_experiment,
            newly_run_ctrl, cached_ctrl,
            exp_time + ctrl_time, exp_time,
            (exp_rounds.to_f / total_experiment).round(1), seed,
            swing_records,
            lut_bytes
        )
        printResults(result)
        result
    end

    #--------------------------------------------------------------------------
    # LUT helpers
    #
    # Replicates the core of PokeBattle_Battle#buildInitialMoveGuess (others=false)
    # using only species_data + level, so we can precompute without a real Pokemon.
    #--------------------------------------------------------------------------
    def self.computeGuessForSpecies(species_data, level)
        moveset  = species_data.level_moves
        sp_types = [species_data.type1]
        sp_types.push(species_data.type2) if species_data.type2 && species_data.type2 != species_data.type1

        signature_moves   = []
        stab_moves_by_type = {}

        moveset.each do |m|
            next if m[0] > level
            moveID   = m[1]
            moveData = GameData::Move.get(moveID)
            if moveData.is_signature?
                signature_moves.push(moveID)
            elsif sp_types.include?(moveData.type)
                stab_moves_by_type[moveData.type] = moveID
            end
        end

        guess = signature_moves.clone
        signature_damaging_types = signature_moves.filter_map { |id|
            data = GameData::Move.get(id)
            data.type unless data.category == 2
        }.uniq
        remaining = 4 - guess.length
        if remaining > 0
            stab_moves = stab_moves_by_type.reject { |type, _| signature_damaging_types.include?(type) }.values
            guess.concat(stab_moves.take(remaining))
        end
        guess.take(4)
    end

    # One entry per level-cap boundary.
    # Stores every cap value so lookup can be a direct hash key computed
    # arithmetically — no scanning required.
    def self.buildLUT_cap
        lut  = {}
        caps = []
        cap  = STARTING_LEVEL_CAP
        while cap <= MAX_LEVEL_CAP
            caps << cap
            cap += LEVEL_CAP_INCREASE
        end
        GameData::Species.each do |sp|
            sp_lut = {}
            caps.each { |c| sp_lut[c] = computeGuessForSpecies(sp, c) }
            lut[sp.id] = sp_lut
        end
        lut
    end

    # One entry per level where the guess changes (new STAB/signature).
    # Stored as a flat Array indexed by level so lookup is a direct index
    # operation. Slots that share the same guess hold the same Array reference —
    # no data is duplicated despite covering every level from 1..MAX_LEVEL_CAP.
    def self.buildLUT_move
        lut = {}
        GameData::Species.each do |sp|
            sp_types = [sp.type1]
            sp_types.push(sp.type2) if sp.type2 && sp.type2 != sp.type1

            relevant_levels = sp.level_moves.filter_map { |lv, move_id|
                next if lv > MAX_LEVEL_CAP
                md = GameData::Move.get(move_id)
                lv if md.is_signature? || sp_types.include?(md.type)
            }.uniq.sort

            next if relevant_levels.empty?

            # Build compressed (threshold, guess) pairs first to deduplicate.
            thresholds = []
            prev_guess = nil
            relevant_levels.each do |lv|
                guess = computeGuessForSpecies(sp, lv)
                next if guess == prev_guess
                thresholds << [lv, guess]
                prev_guess = guess
            end
            next if thresholds.empty?

            # Fill a level-indexed array. Each range shares the same Array
            # reference, so there is no duplication of the guess data itself.
            level_array = Array.new(MAX_LEVEL_CAP + 1, nil)
            thresholds.each_with_index do |(lv, guess), i|
                next_lv = i + 1 < thresholds.length ? thresholds[i + 1][0] : MAX_LEVEL_CAP + 1
                level_array.fill(guess, lv, next_lv - lv)
            end
            lut[sp.id] = level_array
        end
        lut
    end

    # Lazy accessors — build once, cache for the session.
    def self.getLUT_cap
        return @lut_cap if @lut_cap
        echoln("[BENCHMARK] Building LUT (per level cap)...")
        t = Time.now.to_f
        @lut_cap = buildLUT_cap
        echoln("[BENCHMARK] LUT (cap) ready in #{(Time.now.to_f - t).round(2)}s")
        @lut_cap
    end

    def self.getLUT_move
        return @lut_move if @lut_move
        echoln("[BENCHMARK] Building LUT (per move change)...")
        t = Time.now.to_f
        @lut_move = buildLUT_move
        echoln("[BENCHMARK] LUT (move) ready in #{(Time.now.to_f - t).round(2)}s")
        @lut_move
    end

    # LUT_CAP: snap level down to the nearest cap multiple arithmetically,
    # then do a single direct hash lookup — no loop.
    def self.lookupLUT_cap(lut, pokemon)
        sp_lut = lut[pokemon.species_data.id]
        return [] unless sp_lut
        cap = (pokemon.level / LEVEL_CAP_INCREASE * LEVEL_CAP_INCREASE)
              .clamp(STARTING_LEVEL_CAP, MAX_LEVEL_CAP)
        sp_lut[cap] || []
    end

    # LUT_MOVE: direct index into the level array — O(1), no loop.
    def self.lookupLUT_move(lut, pokemon)
        level_array = lut[pokemon.species_data.id]
        return [] unless level_array
        level_array[[pokemon.level, MAX_LEVEL_CAP].min] || []
    end

    #--------------------------------------------------------------------------
    # Output
    #--------------------------------------------------------------------------
    def self.printResults(r)
        bar = "=" * 52
        total_changed = r.test_swings + r.baseline_swings
        pct = ->(n) { "#{n} (#{(n * 100.0 / r.total_experiment).round(1)}%)" }
        ctrl_note = r.newly_run_ctrl > 0 ?
            "#{r.newly_run_ctrl} newly run, #{r.cached_ctrl} from cache" :
            "all #{r.cached_ctrl} from cache"
        summary = [
            bar,
            "  AI BENCHMARK RESULTS",
            "  Test:     #{r.test_heuristic}",
            "  Baseline: #{r.baseline_heuristic}",
            "  Seed:     #{r.seed}",
            bar,
            "  Experiment battles:      #{r.total_experiment}",
            "  Control battles:         #{r.newly_run_ctrl + r.cached_ctrl} (#{ctrl_note})",
            "  Outcomes changed:        #{pct.(total_changed)}",
            "    -> For test:           #{pct.(r.test_swings)}",
            "    -> For baseline:       #{pct.(r.baseline_swings)}",
            "  Outcomes unchanged:      #{pct.(r.unchanged)}",
            "  Avg rounds/battle:       #{r.avg_rounds}",
            "  Total time:              #{r.total_time_s.round(1)}s",
            "  Avg ms/battle:           #{(r.exp_time_s / r.total_experiment * 1000).round(1)}",
        ]
        if r.lut_bytes
            r.lut_bytes.each do |key, bytes|
                kb = (bytes / 1024.0).round(1)
                summary << "  LUT memory (#{key}): #{kb} KB (#{bytes} B)"
            end
        end
        summary << bar
        summary.each { |line| echoln(line.gsub("%", "%%")) }

        file_lines = summary.dup
        unless r.swings.empty?
            file_lines << ""
            file_lines << "  SWING DETAILS"
            file_lines << bar
            [true, false].each do |for_test|
                group = r.swings.select { |s| s.for_test == for_test }
                next if group.empty?
                file_lines << (for_test ? "  For test (#{group.length}):" : "  For baseline (#{group.length}):")
                group.each do |s|
                    test_trainer = s.test_side == 0 ? s.t1_label : s.t2_label
                    exp_id       = s.test_side == 0 ? "A" : "B"
                    ctrl_str     = resultLabel(s.ctrl_result, s.t1_label, s.t2_label)
                    exp_str      = resultLabel(s.exp_result,  s.t1_label, s.t2_label)
                    file_lines << "    #{s.t1_label} vs #{s.t2_label}"
                    file_lines << "      ctrl: #{ctrl_str}  |  exp #{exp_id} (test=#{test_trainer}): #{exp_str}"
                end
            end
        end

        path = "Analysis/benchmark_#{r.test_heuristic}_#{r.baseline_heuristic}.txt"
        File.open(path, "w") { |f| f.puts(file_lines) }
    end

    def self.resultLabel(result, t1, t2)
        case result
        when 0 then "draw"
        when 1 then "#{t1} wins"
        when 2 then "#{t2} wins"
        end
    end
end

#==============================================================================
# Global entry point
#==============================================================================
def pbRunAIBenchmark(test = :current, baseline = :baseline, n_battles: 100, seed: 0)
    AIBenchmark.run(test, baseline, n_battles: n_battles, seed: seed)
end
