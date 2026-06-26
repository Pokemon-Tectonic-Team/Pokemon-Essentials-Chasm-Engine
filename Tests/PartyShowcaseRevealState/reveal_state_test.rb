# Standalone test for PokeXRayRevealState (issue #475 - the online Poké X-Ray's
# note-taking mode). Runs under plain `ruby`, outside the engine: the class itself only
# touches plain methods on whatever pokemon/battle objects it's given, so it's exercised here
# with small fakes instead of the real Pokemon/PokeBattle_Battle classes.
#
# Run with `ruby reveal_state_test.rb`.

require "minitest/autorun"

REPO_ROOT = File.expand_path("../..", __dir__)
require_relative "#{REPO_ROOT}/Plugins/Chasm Graphics and UI/Menus/Party/PartyShowcaseRevealState.rb"

FakeMove = Struct.new(:id)

class FakePokemon
    attr_accessor :personalID, :moves, :extraMoves, :ability_id, :extraAbilities, :items

    def initialize(personalID, moves: [], ability_id: nil, items: [])
        @personalID = personalID
        @moves = moves.map { |id| FakeMove.new(id) }
        @extraMoves = []
        @ability_id = ability_id
        @extraAbilities = []
        @items = items
    end

    def hasExtraMoves?; return !@extraMoves.empty?; end
    def hasExtraAbilities?; return !@extraAbilities.empty?; end
end

# Side 1 only (the opponent's side) - that's all PokeXRayRevealState ever reads.
class FakeBattle
    attr_accessor :previewed_opponent_party
    attr_reader :usedInBattle

    def initialize(used_in_battle_side1)
        @usedInBattle = [[], used_in_battle_side1]
        @known_moves = Hash.new { |h, k| h[k] = [] }
        @known_abilities = Hash.new { |h, k| h[k] = [] }
        @known_items = Hash.new { |h, k| h[k] = [] }
    end

    def reveal_move(pokemon, move_id); @known_moves[pokemon.personalID] << move_id; end
    def reveal_ability(pokemon, ability_id); @known_abilities[pokemon.personalID] << ability_id; end
    def reveal_item(pokemon, item_id); @known_items[pokemon.personalID] << item_id; end

    def aiKnownMoves(pokemon); return @known_moves[pokemon.personalID]; end
    def aiKnownAbilities(pokemon); return @known_abilities[pokemon.personalID]; end
    def aiKnownItems(pokemon); return @known_items[pokemon.personalID]; end
end

class PokeXRayRevealStateTest < Minitest::Test
    def test_full_marks_everything_as_known
        pokemon = FakePokemon.new(1, moves: [:THUNDERBOLT, :QUICKATTACK], ability_id: :STATIC, items: [:LIGHTBALL])
        state = PokeXRayRevealState.full(pokemon)

        assert state.known?
        assert state.seen?
        refute state.not_brought?
        assert state.move_known?(:THUNDERBOLT)
        assert state.ability_known?(:STATIC)
        assert state.item_known?(:LIGHTBALL)
    end

    def test_no_preview_hides_unsent_pokemon_entirely
        sent = FakePokemon.new(1)
        unsent = FakePokemon.new(2)
        battle = FakeBattle.new([true, false])
        battle.previewed_opponent_party = nil
        trainer = Struct.new(:party).new([sent, unsent])

        states = PokeXRayRevealState.compute_all(trainer, battle)

        assert_equal [1], states.map { |s| s.pokemon.personalID }
        assert states[0].seen?
        refute states[0].not_brought?
    end

    def test_preview_shows_unsent_pokemon_without_marking_them_not_brought_before_the_cap
        sent = FakePokemon.new(1)
        unsent = FakePokemon.new(2)
        battle = FakeBattle.new([true, false]) # only 1 of the 2-Pokémon battle roster sent out
        battle.previewed_opponent_party = [sent, unsent]
        trainer = Struct.new(:party).new([sent, unsent])

        states = PokeXRayRevealState.compute_all(trainer, battle)
        by_id = states.map { |s| [s.pokemon.personalID, s] }.to_h

        assert by_id[1].seen?
        refute by_id[2].seen?
        refute by_id[2].not_brought?, "shouldn't be ruled out until every battle roster slot has been confirmed"
    end

    def test_preview_marks_unsent_pokemon_not_brought_once_the_pick_cap_is_reached
        # Bring 3, pick 2: previewed roster has 3, but the actual battle roster only has 2 -
        # once both of those 2 have been sent out, the 3rd previewed Pokémon is provably unused.
        picked_a = FakePokemon.new(1)
        picked_b = FakePokemon.new(2)
        never_picked = FakePokemon.new(3)
        battle = FakeBattle.new([true, true])
        battle.previewed_opponent_party = [picked_a, picked_b, never_picked]
        trainer = Struct.new(:party).new([picked_a, picked_b])

        states = PokeXRayRevealState.compute_all(trainer, battle)
        by_id = states.map { |s| [s.pokemon.personalID, s] }.to_h

        assert by_id[1].seen?
        assert by_id[2].seen?
        refute by_id[3].seen?
        assert by_id[3].not_brought?
    end

    def test_only_actually_revealed_moves_abilities_and_items_are_known
        pokemon = FakePokemon.new(1, moves: [:THUNDERBOLT, :QUICKATTACK], ability_id: :STATIC, items: [:LIGHTBALL])
        battle = FakeBattle.new([true])
        battle.reveal_move(pokemon, :THUNDERBOLT) # Quick Attack never used
        trainer = Struct.new(:party).new([pokemon])

        states = PokeXRayRevealState.compute_all(trainer, battle)
        state = states.first

        assert state.seen?
        assert state.move_known?(:THUNDERBOLT)
        refute state.move_known?(:QUICKATTACK)
        refute state.ability_known?(:STATIC), "ability never activated, so shouldn't be known yet"
        refute state.item_known?(:LIGHTBALL), "item never visibly triggered, so shouldn't be known yet"
    end
end
