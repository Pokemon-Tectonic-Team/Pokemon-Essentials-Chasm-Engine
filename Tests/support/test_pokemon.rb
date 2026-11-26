# A stand-in for the Pokémon behind a battler: the personalID the AI's knowledge is keyed by, and
# its species' level-up learnset, as getMoveList gives it ([level, move ID] pairs, lowest first).
class TestPokemon
    attr_reader :personalID

    def initialize(personal_id: 0, learnset: [])
        @personalID = personal_id
        @learnset = learnset
    end

    def getMoveList
        @learnset
    end
end
