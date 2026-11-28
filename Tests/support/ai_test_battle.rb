# A real PokeBattle_Battle holding only the state the AI's knowledge of the player's side reads: a
# real field, one player trainer on the even side and one opposing trainer with the given policies
# on the odd side, the AI's known moves, its predictions and the battle AI. pbDisplay records each
# message, and initializeKnownMoves seeds the moves the AI knows of a Pokémon from the start from
# auto_known_moves (personalID => move IDs), rather than working them out from move data.
class AITestBattle < PokeBattle_Battle
    Trainer = Struct.new(:policies)

    attr_reader :field, :battlers, :messages

    def initialize(auto_known_moves: {}, opponent_policies: [], battle_ai: nil, predicted_actions: []) # rubocop:disable Lint/MissingSuper -- a fake: sets only its own state, skipping the real initializer by design
        @battlers = []
        @player = [Trainer.new([])]
        @opponent = [Trainer.new(opponent_policies)]
        @knownMoves = {}
        @auto_known_moves = auto_known_moves
        @battleAI = battle_ai
        @predictedActions = predicted_actions
        @messages = []
        @field = PokeBattle_ActiveField.new(self)
    end

    # A TestBattler in this battle, placed at its index.
    def add_battler(index: 0, **keywords)
        @battlers[index] = TestBattler.new(battle: self, index: index, **keywords)
    end

    def initializeKnownMoves(pokemon)
        @knownMoves[pokemon.personalID] = @auto_known_moves.fetch(pokemon.personalID, []).dup
    end

    def pbDisplay(message, no_highlighting: false) # rubocop:disable Lint/UnusedMethodArgument -- keyword name matches the game's signature
        @messages << message
    end
end
