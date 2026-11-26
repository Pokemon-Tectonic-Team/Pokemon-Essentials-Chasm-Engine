require_relative "../../../support/test_helper"

class EggMoveTutorTest < Minitest::Test
    # A Pokémon of a species knowing some moves; the harness doesn't load the rest of Pokemon
    class KnownMovesPokemon < Pokemon
        attr_reader :species

        def initialize(species, known_moves, egg: false) # rubocop:disable Lint/MissingSuper -- a fake: sets only its own state, skipping the real initializer by design
            @species = species
            @known_moves = known_moves
            @egg = egg
        end

        def egg? = @egg
        def hasMove?(move) = @known_moves.include?(move)
    end

    def setup
        super
        %i[TACKLE EMBER SURF].each { |id| create_move(id: id) }
        create_species(id: :BASE, line_moves: [:TACKLE, :EMBER], evolutions: [[:MID, :Level, 10, false]])
        create_species(id: :MID, line_moves: [:SURF], evolutions: [[:BASE, :Level, 10, true]])
    end

    # A species sorts its line moves by name
    def test_get_egg_moves_reads_the_line_start_and_skips_known_moves
        assert_equal [:EMBER, :TACKLE], getEggMoves(KnownMovesPokemon.new(:MID, []))
        assert_equal [:TACKLE], getEggMoves(KnownMovesPokemon.new(:MID, [:EMBER]))
    end

    def test_can_egg_move_while_a_line_start_move_is_unknown
        assert KnownMovesPokemon.new(:MID, [:EMBER]).can_egg_move?
        refute KnownMovesPokemon.new(:MID, [:EMBER, :TACKLE]).can_egg_move?
    end

    def test_an_egg_cannot_egg_move
        refute KnownMovesPokemon.new(:MID, [], egg: true).can_egg_move?
    end
end
