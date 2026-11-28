require_relative "../support/test_helper"

class TestPokemonTest < Minitest::Test
    def test_defaults
        pokemon = TestPokemon.new

        assert_equal 0, pokemon.personalID
        assert_empty pokemon.getMoveList
    end

    def test_keywords_reach_their_readers
        learnset = [[1, :TACKLE], [20, :BITE]]
        pokemon = TestPokemon.new(personal_id: 7, learnset: learnset)

        assert_equal 7, pokemon.personalID
        assert_same learnset, pokemon.getMoveList
    end
end
