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

    def test_a_frozen_constant_is_not_copied_but_is_visited
        with_planted({ a: 1, inner: { b: 2 } }.freeze) do |planted|
            snapshot = StateSnapshot.take

            refute snapshot.key?(planted)
            assert snapshot.key?(planted[:inner])
        end
    end

    def test_restore_restores_an_unfrozen_hash_inside_a_frozen_constant
        inner = { x: 1 }
        with_planted({ inner: inner }.freeze) do
            snapshot = StateSnapshot.take
            inner[:x] = 2
            inner[:y] = 3

            StateSnapshot.restore(snapshot)

            assert_equal({ x: 1 }, inner)
        end
    end

    def test_restore_restores_an_array_inside_a_frozen_array
        inner = [1]
        with_planted([inner].freeze) do
            snapshot = StateSnapshot.take
            inner << 2

            StateSnapshot.restore(snapshot)

            assert_equal [1], inner
        end
    end

    def test_restore_restores_a_hash_reachable_from_two_constants
        shared = { x: 1 }
        with_planted({ shared: shared }) do
            GameData::Stat.const_set(:SNAPSHOT_TEST_SECOND, [shared])
            snapshot = StateSnapshot.take
            shared[:y] = 2

            StateSnapshot.restore(snapshot)

            assert_equal({ x: 1 }, shared)
        ensure
            GameData::Stat.send(:remove_const, :SNAPSHOT_TEST_SECOND)
        end
    end

    def test_a_hash_holding_itself_is_snapshotted_and_restored
        cycle = {}
        cycle[:self] = cycle
        with_planted(cycle) do
            snapshot = StateSnapshot.take
            cycle[:extra] = 1

            StateSnapshot.restore(snapshot)

            assert_equal [:self], cycle.keys
        end
    end

    def test_a_constant_on_a_module_under_game_data_is_ignored
        planted = { a: 1 }
        mod = Module.new
        mod.const_set(:PLANTED, planted)
        GameData.const_set(:SnapshotTestModule, mod)

        refute StateSnapshot.take.key?(planted)
    ensure
        GameData.send(:remove_const, :SnapshotTestModule) if GameData.const_defined?(:SnapshotTestModule, false)
    end

    def test_an_unfrozen_constant_is_copied
        with_planted({ a: 1 }) do |planted|
            copy = StateSnapshot.take[planted]
            assert_equal({ a: 1 }, copy)
            refute_same planted, copy
        end
    end

    # Plants a fresh handler hash holding :KEPT and a fresh event holding one callback on
    # BattleHandlers for the block and removes both afterwards.
    def with_planted_handlers
        @kept_callback = proc {}
        handlers = HandlerHash2.new
        handlers.add(:KEPT, proc {})
        event = Event.new
        event += @kept_callback
        BattleHandlers.const_set(:SnapshotTestHandlers, handlers)
        BattleHandlers.const_set(:SnapshotTestEvent, event)
        yield handlers, event
    ensure
        %i[SnapshotTestHandlers SnapshotTestEvent].each do |name|
            BattleHandlers.send(:remove_const, name) if BattleHandlers.const_defined?(name, false)
        end
    end

    def test_restore_removes_a_handler_added_with_add
        with_planted_handlers do |handlers, _event|
            snapshot = StateSnapshot.take
            handlers.add(:ADDED, proc {})
            refute_nil handlers[:ADDED]

            StateSnapshot.restore(snapshot)

            assert_nil handlers[:ADDED]
        end
    end

    def test_restore_removes_a_handler_added_with_add_if
        with_planted_handlers do |handlers, _event|
            snapshot = StateSnapshot.take
            handlers.addIf(proc { |item| item == :ADDED_IF }, proc {})
            refute_nil handlers[:ADDED_IF]

            StateSnapshot.restore(snapshot)

            assert_nil handlers[:ADDED_IF]
        end
    end

    def test_restore_removes_an_event_callback
        with_planted_handlers do |_handlers, event|
            snapshot = StateSnapshot.take
            callback = proc {}
            event += callback
            assert_includes event.instance_variable_get(:@callbacks), callback

            StateSnapshot.restore(snapshot)

            refute_includes event.instance_variable_get(:@callbacks), callback
        end
    end

    def test_restore_keeps_the_handler_containers_the_same_objects
        with_planted_handlers do |handlers, event|
            hash = handlers.instance_variable_get(:@hash)
            add_ifs = handlers.instance_variable_get(:@add_ifs)
            callbacks = event.instance_variable_get(:@callbacks)
            snapshot = StateSnapshot.take
            handlers.add(:ADDED, proc {})
            handlers.addIf(proc { false }, proc {})
            event += proc {}

            StateSnapshot.restore(snapshot)

            assert_same hash, handlers.instance_variable_get(:@hash)
            assert_same add_ifs, handlers.instance_variable_get(:@add_ifs)
            assert_same callbacks, event.instance_variable_get(:@callbacks)
        end
    end

    def test_restore_keeps_a_handler_and_a_callback_present_when_taken
        with_planted_handlers do |handlers, event|
            snapshot = StateSnapshot.take
            handlers.add(:ADDED, proc {})

            StateSnapshot.restore(snapshot)

            refute_nil handlers[:KEPT]
            assert_includes event.instance_variable_get(:@callbacks), @kept_callback
        end
    end
end
