require_relative "../support/test_helper"

class StateSnapshotTest < Minitest::Test
    PLANTED = :SNAPSHOT_TEST_PLANTED

    # Plants a constant on GameData::Stat for the block and removes it afterwards.
    def with_planted(value)
        GameData::Stat.const_set(PLANTED, value)
        yield value
    ensure
        GameData::Stat.send(:remove_const, PLANTED) if GameData::Stat.const_defined?(PLANTED, false)
    end

    def test_restore_undoes_a_record_registered_through_register
        snapshot = StateSnapshot.take
        GameData::Stat.register({ id: :SNAPSHOT_TEST_STAT, id_number: 99, name: "Planted" })
        assert GameData::Stat::DATA.key?(:SNAPSHOT_TEST_STAT)

        StateSnapshot.restore(snapshot)

        refute GameData::Stat::DATA.key?(:SNAPSHOT_TEST_STAT)
        assert GameData::Stat::DATA.key?(:ATTACK)
    end

    def test_restore_undoes_an_entry_added_to_a_flag_index
        assert_empty GameData::Ability::FLAG_INDEX
        snapshot = StateSnapshot.take
        GameData::Ability.register({ id: :SNAPSHOT_TEST_ABILITY, id_number: 99, flags: ["SnapshotFlag"] })
        assert_equal [:SNAPSHOT_TEST_ABILITY], GameData::Ability::FLAG_INDEX["SnapshotFlag"]

        StateSnapshot.restore(snapshot)

        assert_empty GameData::Ability::FLAG_INDEX
    end

    def test_restore_undoes_a_push_onto_an_array_inside_a_flag_index
        GameData::Ability::FLAG_INDEX["SnapshotFlag"] = [:ONE]
        snapshot = StateSnapshot.take
        GameData::Ability::FLAG_INDEX["SnapshotFlag"].push(:TWO)

        StateSnapshot.restore(snapshot)

        assert_equal [:ONE], GameData::Ability::FLAG_INDEX["SnapshotFlag"]
    end

    def test_restore_undoes_a_change_to_a_constant_no_list_names
        with_planted({ a: 1 }) do |planted|
            snapshot = StateSnapshot.take
            planted[:b] = 2
            planted[:a] = 10

            StateSnapshot.restore(snapshot)

            assert_equal({ a: 1 }, planted)
        end
    end

    def test_restore_restores_a_hash_nested_in_a_constants_hash
        inner = { x: 1 }
        with_planted({ inner: inner }) do |planted|
            snapshot = StateSnapshot.take
            inner[:x] = 2
            inner[:y] = 3

            StateSnapshot.restore(snapshot)

            assert_equal({ x: 1 }, inner)
            assert_same inner, planted[:inner]
        end
    end

    def test_a_frozen_constant_is_not_copied
        with_planted({ a: 1 }.freeze) do |planted|
            refute StateSnapshot.take.key?(planted)
        end
    end

    def test_an_unfrozen_constant_is_copied
        with_planted({ a: 1 }) do |planted|
            copy = StateSnapshot.take[planted]
            assert_equal({ a: 1 }, copy)
            refute_same planted, copy
        end
    end

    def handlers
        BattleHandlers::DamageCalcUserItem
    end

    def event
        BattleHandlers::LoadDataDependentAbilityHandlers
    end

    def test_restore_removes_a_handler_added_with_add
        snapshot = StateSnapshot.take
        handlers.add(:SNAPSHOT_TEST_ITEM, proc {})
        refute_nil handlers[:SNAPSHOT_TEST_ITEM]

        StateSnapshot.restore(snapshot)

        assert_nil handlers[:SNAPSHOT_TEST_ITEM]
    end

    def test_restore_removes_a_handler_added_with_add_if
        snapshot = StateSnapshot.take
        handlers.addIf(proc { |item| item == :SNAPSHOT_TEST_IF_ITEM }, proc {})
        refute_nil handlers[:SNAPSHOT_TEST_IF_ITEM]

        StateSnapshot.restore(snapshot)

        assert_nil handlers[:SNAPSHOT_TEST_IF_ITEM]
    end

    def test_restore_removes_an_event_callback
        snapshot = StateSnapshot.take
        callback = proc {}
        event + callback
        assert_includes event.instance_variable_get(:@callbacks), callback

        StateSnapshot.restore(snapshot)

        refute_includes event.instance_variable_get(:@callbacks), callback
    end

    def test_restore_keeps_the_handler_containers_the_same_objects
        hash = handlers.instance_variable_get(:@hash)
        add_ifs = handlers.instance_variable_get(:@add_ifs)
        callbacks = event.instance_variable_get(:@callbacks)
        snapshot = StateSnapshot.take
        handlers.add(:SNAPSHOT_TEST_ITEM, proc {})
        handlers.addIf(proc { false }, proc {})
        event + proc {}

        StateSnapshot.restore(snapshot)

        assert_same hash, handlers.instance_variable_get(:@hash)
        assert_same add_ifs, handlers.instance_variable_get(:@add_ifs)
        assert_same callbacks, event.instance_variable_get(:@callbacks)
    end

    def test_restore_keeps_a_handler_registered_at_load
        snapshot = StateSnapshot.take
        handlers.add(:SNAPSHOT_TEST_ITEM, proc {})

        StateSnapshot.restore(snapshot)

        refute_nil handlers[:CHARCOAL]
    end
end