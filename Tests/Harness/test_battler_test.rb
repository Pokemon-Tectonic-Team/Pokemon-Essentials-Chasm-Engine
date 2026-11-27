require_relative "../support/test_helper"

class TestBattlerTest < Minitest::Test
    def test_defaults
        expected = {
            hp: 1, totalhp: 1, index: 0, effects: {}, boss?: false, pbSpeed: 1, pbThis: "Test", hpBasedEffectResistance: 1.0,
            fainted?: false, movedThisRound?: false, learned_items: [], applied_effects: [], battle: nil, pokemon: nil,
            moves: [], level: 1
        }

        assert_attributes expected, TestBattler.new
    end

    def test_by_default_no_ability_is_active
        refute TestBattler.new.hasActiveAbility?(:ANYTHING)
    end

    def test_each_keyword_reaches_its_reader_or_override
        battler = TestBattler.new(hp: 40, totalhp: 90, index: 2, boss: true, speed: 77, name: "Named", hp_resistance: 0.5,
                                  fainted: true, moved: true, abilities: [:STATIC], level: 30)

        expected = {
            hp: 40, totalhp: 90, index: 2, boss?: true, pbSpeed: 77, pbThis: "Named", hpBasedEffectResistance: 0.5,
            fainted?: true, movedThisRound?: true, level: 30
        }

        assert_attributes expected, battler
        assert battler.hasActiveAbility?(:STATIC)
    end

    def test_battle_and_pokemon_are_held_as_given
        battle = Object.new
        pokemon = TestPokemon.new
        battler = TestBattler.new(battle: battle, pokemon: pokemon)

        assert_same battle, battler.battle
        assert_same pokemon, battler.pokemon
    end

    def test_effects_and_moves_are_held_as_given_not_copied
        effects = { some_effect: 3 }
        moves = [:a_move]
        battler = TestBattler.new(effects: effects, moves: moves)

        assert_same effects, battler.effects
        assert_same moves, battler.moves
    end

    def test_overrides_accept_the_real_signatures_arguments
        battler = TestBattler.new(speed: 5, name: "Named", abilities: [:X])

        assert_equal 5, battler.pbSpeed(true, 2, afterSwitching: true, move: nil)
        assert_equal "Named", battler.pbThis(true)
        assert battler.hasActiveAbility?(:X, true, false, ignoreGas: true)
    end

    def test_effect_overrides_accept_the_real_signatures_arguments
        battler = TestBattler.new
        battler.applyEffect(:E, 1, true)

        assert_equal [[:E, 1]], battler.applied_effects
        refute battler.effectActive?(:E, true)
    end

    def test_effect_is_active_while_effects_holds_a_truthy_value
        battler = TestBattler.new(effects: { on: true, counted: 2, off: false, cleared: nil })
        active = %i[on counted off cleared absent].select { |id| battler.effectActive?(id) }

        assert_equal %i[on counted], active
    end

    def test_no_effect_is_active_while_fainted_unless_fainting_is_ignored
        battler = TestBattler.new(effects: { on: true }, fainted: true)

        refute battler.effectActive?(:on)
        assert battler.effectActive?(:on, true)
    end

    def test_loaded_overrides_take_the_real_methods_parameters
        %i[pbThis fainted? hpBasedEffectResistance movedThisRound? hasActiveAbility? aiLearnsItem].each do |name|
            real = PokeBattle_Battler.instance_method(name).parameters
            fake = TestBattler.instance_method(name).parameters

            assert_equal real.map(&:first), fake.map(&:first), "#{name} takes other kinds of argument"
        end
    end

    def test_has_active_ability_is_true_only_for_a_listed_ability
        battler = TestBattler.new(abilities: %i[STATIC BLAZE])

        assert battler.hasActiveAbility?(:STATIC)
        assert battler.hasActiveAbility?(:BLAZE)
        refute battler.hasActiveAbility?(:TORRENT)
    end

    def test_ai_learns_item_records_in_call_order
        battler = TestBattler.new
        battler.aiLearnsItem(:POTION)
        battler.aiLearnsItem(:CHARCOAL)

        assert_equal %i[POTION CHARCOAL], battler.learned_items
    end

    def test_apply_effect_records_effect_value_pairs_in_call_order
        battler = TestBattler.new
        battler.applyEffect(:A, 1)
        battler.applyEffect(:B)
        battler.applyEffect(:C, 3, true)

        assert_equal [[:A, 1], [:B, nil], [:C, 3]], battler.applied_effects
    end
end
