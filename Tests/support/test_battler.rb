# A real PokeBattle_Battler whose state is set from keywords and whose queries that reach the
# battle, the Pokémon or the effect registry answer from those keywords instead. Each override
# takes the arguments of the game's method of that name, so callers reach it unchanged; most of
# those methods aren't loaded by the harness, so keep each signature in step with the game's
# source by hand. The ones that act on the
# battle (aiLearnsItem, applyEffect) record their calls in order.
class TestBattler < PokeBattle_Battler
    attr_reader :learned_items, :applied_effects

    def initialize(hp: 1, totalhp: 1, index: 0, effects: {}, boss: false, speed: 1, name: "Test", # rubocop:disable Lint/MissingSuper -- a fake: sets only its own state, skipping the real initializer by design
                   hp_resistance: 1.0, fainted: false, moved: false, abilities: [])
        @hp = hp
        @totalhp = totalhp
        @index = index
        @effects = effects
        @boss = boss
        @speed = speed
        @name = name
        @hp_resistance = hp_resistance
        @fainted = fainted
        @moved = moved
        @abilities = abilities
        @learned_items = []
        @applied_effects = []
    end

    def pbSpeed(_aiCheck = false, _step = nil, afterSwitching: false, move: nil) # rubocop:disable Lint/UnusedMethodArgument -- keyword names match the game's signature
        @speed
    end

    def pbThis(_lowerCase = false)
        @name
    end

    def hpBasedEffectResistance
        @hp_resistance
    end

    def fainted?
        @fainted
    end

    def movedThisRound?
        @moved
    end

    def hasActiveAbility?(ability, _ignore_fainted = false, _checkingForAI = false, ignoreGas: false) # rubocop:disable Lint/UnusedMethodArgument -- keyword names match the game's signature
        @abilities.include?(ability)
    end

    def aiLearnsItem(item)
        @learned_items << item
    end

    def applyEffect(effect, value = nil, _ignoreFainted = false)
        @applied_effects << [effect, value]
    end
end
