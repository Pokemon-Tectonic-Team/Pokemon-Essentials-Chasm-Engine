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
end
