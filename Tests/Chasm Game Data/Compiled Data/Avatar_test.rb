require "stringio"
require_relative "../../support/test_helper"

class AvatarTest < Minitest::Test
    def setup
        create_move(id: :EMBER)
    end

    # The pit avatar list is a class instance variable, which the per-test reset doesn't restore. No
    # avatar is registered at load, so the list starts empty.
    def teardown
        GameData::Avatar.pit_avatars.clear
    end

    def register_avatar(version, moves: [:EMBER], pit_avatar: true)
        return GameData::Avatar.register({
            id: [:BASE, version], id_number: version + 1, species: :BASE, version: version, moves1: moves,
            aggression: 1, pit_avatar: pit_avatar
        })
    end

    def test_registering_a_pit_avatar_adds_it_to_the_pit_avatars
        first = register_avatar(0)
        second = register_avatar(1)

        assert_equal [first, second], GameData::Avatar.getPitAvatars
    end

    def test_an_avatar_registered_over_another_takes_its_place_among_the_pit_avatars
        register_avatar(0)
        create_move(id: :TACKLE)

        replacement = register_avatar(0, moves: [:TACKLE])

        assert_equal [replacement], GameData::Avatar.getPitAvatars
    end

    def test_a_replaced_pit_avatar_that_is_no_longer_one_leaves_the_pit_avatars
        register_avatar(0)

        register_avatar(0, pit_avatar: false)

        assert_empty GameData::Avatar.pit_avatars
    end

    def test_get_refuses_an_unknown_avatar
        error = assert_raises(RuntimeError) { GameData::Avatar.get(:BASE, 3) }

        assert_equal "Unknown avatar BASE 3.", error.message
    end

    def test_try_get_finds_a_registered_avatar_and_is_nil_for_an_unknown_one
        avatar = register_avatar(0)

        assert_equal avatar, GameData::Avatar.try_get("BASE")
        assert_nil GameData::Avatar.try_get(:BASE, 1)
    end

    def test_get_pit_avatars_gathers_the_registered_pit_avatars_when_the_list_is_empty
        pit = register_avatar(0)
        register_avatar(1, pit_avatar: false)
        GameData::Avatar.pit_avatars.clear

        assert_equal [pit], GameData::Avatar.getPitAvatars
        assert_equal pit, GameData::Avatar.randomPitAvatar
    end

    def avatar_with_move_sets(count, **attributes)
        move_sets = (1..count).to_h { |n| [:"moves#{n}", [:EMBER]] }
        return GameData::Avatar.new({ id: [:BASE, 0], id_number: 1, species: :BASE, aggression: 1 }.merge(move_sets, attributes))
    end

    def test_each_further_move_set_adds_a_phase_and_a_health_bar
        (1..5).each do |count|
            avatar = avatar_with_move_sets(count)

            assert_equal count, avatar.num_phases
            assert_equal count, avatar.num_health_bars
        end
    end

    def test_a_move_set_after_an_empty_one_adds_no_phase
        assert_equal 1, avatar_with_move_sets(1, moves3: [:EMBER]).num_phases
        assert_equal 3, avatar_with_move_sets(3, moves5: [:EMBER]).num_phases
    end

    # write_avatar_to_file

    def written_avatar(avatar)
        io = StringIO.new
        Compiler.write_avatar_to_file(avatar, io)
        return io.string
    end

    def test_write_avatar_writes_only_what_differs_from_the_defaults
        avatar = GameData::Avatar.new({ id: [:BASE, 0], id_number: 1, species: :BASE, moves1: [:EMBER] })

        assert_equal "#-------------------------------\r\n[BASE]\r\nMoves1 = EMBER\r\n", written_avatar(avatar)
    end

    def test_write_avatar_writes_every_property_set
        create_ability(id: :BLAZE)
        avatar = avatar_with_move_sets(5, id: [:BASE, 2], version: 2, abilities: [:BLAZE], turns: 9, hp_mult: 7,
                                          health_bars: 2, items: [:ORB], dmg_mult: 3, dmg_resist: 0.5, form: 1, aggression: 5)

        expected = "#-------------------------------\r\n[BASE,2]\r\nAbility = BLAZE\r\nMoves1 = EMBER\r\nMoves2 = EMBER\r\n" \
                   "Moves3 = EMBER\r\nMoves4 = EMBER\r\nMoves5 = EMBER\r\nTurns = 9\r\nHPMult = 7\r\nHealthBars = 2\r\n" \
                   "Item = ORB\r\nDMGMult = 3\r\nDMGResist = 0.5\r\nForm = 1\r\nAggression = 5\r\n"
        assert_equal expected, written_avatar(avatar)
    end

    # pbEachAvatarFileSection

    def test_each_avatar_file_section_yields_each_sections_species_and_version
        sections = []
        file = StringIO.new("[BASE]\r\nMoves1 = EMBER\r\n[BASE,2]\r\nTurns = 3\r\n[not, valid!]\r\nTurns = 4\r\n")

        Compiler.pbEachAvatarFileSection(file) { |section, species, version| sections.push([species, version, section]) }

        assert_equal [[:BASE, 0, { "Moves1" => "EMBER" }], [:BASE, 2, { "Turns" => "3" }]], sections
    end
end
