require_relative "../support/test_helper"

class GameDataSnapshotTest < Minitest::Test
    PLANTED = :SNAPSHOT_TEST_PLANTED

    # Plants a constant on GameData::Stat for the block and removes it afterwards.
    def with_planted(value)
        GameData::Stat.const_set(PLANTED, value)
        yield value
    ensure
        GameData::Stat.send(:remove_const, PLANTED) if GameData::Stat.const_defined?(PLANTED, false)
    end

    def test_restore_undoes_a_record_registered_through_register
        snapshot = GameDataSnapshot.take
        GameData::Stat.register({ id: :SNAPSHOT_TEST_STAT, id_number: 99, name: "Planted" })
        assert GameData::Stat::DATA.key?(:SNAPSHOT_TEST_STAT)

        GameDataSnapshot.restore(snapshot)

        refute GameData::Stat::DATA.key?(:SNAPSHOT_TEST_STAT)
        assert GameData::Stat::DATA.key?(:ATTACK)
    end

    def test_restore_undoes_an_entry_added_to_a_flag_index
        assert_empty GameData::Ability::FLAG_INDEX
        snapshot = GameDataSnapshot.take
        GameData::Ability.register({ id: :SNAPSHOT_TEST_ABILITY, id_number: 99, flags: ["SnapshotFlag"] })
        assert_equal [:SNAPSHOT_TEST_ABILITY], GameData::Ability::FLAG_INDEX["SnapshotFlag"]

        GameDataSnapshot.restore(snapshot)

        assert_empty GameData::Ability::FLAG_INDEX
    end

    def test_restore_undoes_a_push_onto_an_array_inside_a_flag_index
        GameData::Ability::FLAG_INDEX["SnapshotFlag"] = [:ONE]
        snapshot = GameDataSnapshot.take
        GameData::Ability::FLAG_INDEX["SnapshotFlag"].push(:TWO)

        GameDataSnapshot.restore(snapshot)

        assert_equal [:ONE], GameData::Ability::FLAG_INDEX["SnapshotFlag"]
    end

    def test_restore_undoes_a_change_to_a_constant_no_list_names
        with_planted({ a: 1 }) do |planted|
            snapshot = GameDataSnapshot.take
            planted[:b] = 2
            planted[:a] = 10

            GameDataSnapshot.restore(snapshot)

            assert_equal({ a: 1 }, planted)
        end
    end

    def test_restore_restores_a_hash_nested_in_a_constants_hash
        inner = { x: 1 }
        with_planted({ inner: inner }) do |planted|
            snapshot = GameDataSnapshot.take
            inner[:x] = 2
            inner[:y] = 3

            GameDataSnapshot.restore(snapshot)

            assert_equal({ x: 1 }, inner)
            assert_same inner, planted[:inner]
        end
    end

    def test_a_frozen_constant_is_not_copied
        with_planted({ a: 1 }.freeze) do |planted|
            refute GameDataSnapshot.take.key?(planted)
        end
    end

    def test_an_unfrozen_constant_is_copied
        with_planted({ a: 1 }) do |planted|
            copy = GameDataSnapshot.take[planted]
            assert_equal({ a: 1 }, copy)
            refute_same planted, copy
        end
    end
end
