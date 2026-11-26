require_relative "../../../support/test_helper"

# An AITestBattle with parties, recording the ability splashes shown and hidden.
class FieldEffectsTestBattle < AITestBattle
    attr_reader :party1, :party2, :splashes

    def initialize(party1: [], party2: [], **keywords)
        super(**keywords)
        @party1 = party1
        @party2 = party2
        @splashes = []
    end

    def pbShowPokemonAbilitySplash(pkmn, sideIndex, ability, _delay = false)
        @splashes << [:show, pkmn, sideIndex, ability]
    end

    def pbHidePokemonAbilitySplash(sideIndex)
        @splashes << [:hide, sideIndex]
    end
end

# A TestBattler answering whether it has stat steps to reset or can heal, and recording the
# resets and healing it is given.
class FieldEffectsTestBattler < TestBattler
    attr_reader :resets, :healing

    def initialize(altered_steps: false, can_heal: false, **keywords)
        super(**keywords)
        @altered_steps = altered_steps
        @can_heal = can_heal
        @resets = 0
        @healing = []
    end

    def hasAlteredStatSteps?
        @altered_steps
    end

    def pbResetStatSteps
        @resets += 1
    end

    def canHeal?(_overheal = false)
        @can_heal
    end

    def applyFractionalHealing(fraction, customMessage: nil, **)
        @healing << [fraction, customMessage]
    end
end

# The field effect definitions' procs.
class FieldEffectsTest < Minitest::Test
    PartyMember = Struct.new(:abilities) do
        def hasAbility?(ability) = abilities.include?(ability)
    end

    ROOMS = %i[PuzzleRoom OddRoom PolarizedRoom InsightRoom EmotionRoom WillfulRoom].freeze

    def effect(id)
        GameData::BattleEffect.get(id)
    end

    def battle_with_abilities(*abilities)
        battle = AITestBattle.new
        abilities.each_with_index { |ability, index| battle.add_battler(index: index, abilities: [ability]) }
        battle
    end

    # Ticking down

    def test_rooms_tick_down_unless_a_battler_has_room_lock
        ROOMS.each do |room|
            assert effect(room).ticks_down_eor?(battle_with_abilities(:BLAZE), 3), room.to_s
            refute effect(room).ticks_down_eor?(battle_with_abilities(:BLAZE, :ROOMLOCK), 3), room.to_s
        end
    end

    def test_gravity_ticks_down_unless_a_battler_has_distorted_gravity
        assert effect(:Gravity).ticks_down_eor?(battle_with_abilities(:ROOMLOCK), 3)
        refute effect(:Gravity).ticks_down_eor?(battle_with_abilities(:DISTORTEDGRAVITY), 3)
    end

    # Insight Room

    def test_insight_room_start_only_shows_its_message
        battle = AITestBattle.new
        player = battle.add_battler(pokemon: TestPokemon.new(learnset: [[1, :TACKLE]]), level: 50)

        battle.field.applyEffect(:InsightRoom, 5)

        assert_equal ["An insightful area appeared! Everyone gets a 5th move!"], battle.messages
        assert_empty battle.instance_variable_get(:@knownMoves)
        assert_equal [], battle.aiKnownMoves(player.pokemon)
    end

    def test_insight_room_end_messages
        battle = AITestBattle.new
        effect(:InsightRoom).disable_field(battle)
        effect(:InsightRoom).expire_field(battle)
        assert_equal ["The insightful area was dispelled!", "The insightful area fell away."], battle.messages
    end

    # Grey Mist

    def test_grey_mist_resets_only_altered_stat_steps_each_round
        battle = AITestBattle.new
        altered = FieldEffectsTestBattler.new(battle: battle, altered_steps: true, name: "Altered")
        unaltered = FieldEffectsTestBattler.new(battle: battle, index: 1)
        battle.battlers.push(altered, unaltered)

        effect(:GreyMist).eor_field(battle)

        assert_equal 1, altered.resets
        assert_equal 0, unaltered.resets
        assert_equal ["Altered's stat changes were eliminated!"], battle.messages
    end

    # Floral Gramarye

    def test_floral_gramarye_heals_an_eighth_to_each_battler_that_can_heal
        battle = AITestBattle.new
        healable = FieldEffectsTestBattler.new(battle: battle, can_heal: true, name: "Healable")
        unhealable = FieldEffectsTestBattler.new(battle: battle, index: 1)
        battle.battlers.push(healable, unhealable)

        effect(:FloralGramarye).eor_field(battle)

        assert_equal [[0.125, "Healable was healed by the field of flowers!"]], healable.healing
        assert_empty unhealable.healing
    end

    # Slumbering Shield and Sword

    def test_slumbering_effects_with_one_party_holding_the_ability
        { SlumberingShieldReady: [:SLUMBERINGSHIELD, "Shield wakes"],
          SlumberingSwordReady: [:SLUMBERINGSWORD, "Sword wakes"], }.each do |id, (ability, wakes)|
            holder = PartyMember.new([ability])
            battle = FieldEffectsTestBattle.new(party1: [PartyMember.new([]), holder], party2: [PartyMember.new([])])

            effect(id).apply_field(battle)

            assert_equal [[:show, holder, 0, ability], [:hide, 0]], battle.splashes, id.to_s
            assert_equal ["A howl can be heard in the distance! The Slumbering #{wakes}!"], battle.messages, id.to_s
        end
    end

    def test_slumbering_effects_with_both_parties_holding_the_ability_splash_once_each
        { SlumberingShieldReady: [:SLUMBERINGSHIELD, "Shields wake"],
          SlumberingSwordReady: [:SLUMBERINGSWORD, "Swords wake"], }.each do |id, (ability, wake)|
            first = PartyMember.new([ability])
            second = PartyMember.new([ability])
            other = PartyMember.new([ability])
            battle = FieldEffectsTestBattle.new(party1: [first, second], party2: [other])

            effect(id).apply_field(battle)

            assert_equal [[:show, first, 0, ability], [:show, other, 1, ability], [:hide, 0], [:hide, 1]],
                         battle.splashes, id.to_s
            assert_equal ["A howl can be heard in the distance! The Slumbering #{wake}!"], battle.messages, id.to_s
        end
    end

    def test_slumbering_effects_with_no_holder_still_wake_one
        { SlumberingShieldReady: "Shield wakes", SlumberingSwordReady: "Sword wakes" }.each do |id, wakes|
            battle = FieldEffectsTestBattle.new(party1: [PartyMember.new([])], party2: [])

            effect(id).apply_field(battle)

            assert_empty battle.splashes, id.to_s
            assert_equal ["A howl can be heard in the distance! The Slumbering #{wakes}!"], battle.messages, id.to_s
        end
    end
end
