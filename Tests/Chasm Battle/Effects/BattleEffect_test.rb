require_relative "../../support/test_helper"

class BattleEffectTest < Minitest::Test
    Named = Struct.new(:name)
    FakeBattle = Struct.new(:battlers)

    def effect(**hash)
        GameData::BattleEffect.new({ id: :TEST }.merge(hash))
    end

    def register(location, id, **hash)
        GameData::BattleEffect.register_effect(location, { id: id }.merge(hash))
        GameData::BattleEffect.get(id)
    end

    # initialize

    def test_type_is_boolean_when_none_given
        assert_equal :Boolean, effect.type
    end

    def test_given_type_is_kept
        assert_equal :Integer, effect(type: :Integer).type
    end

    def test_default_when_none_given
        assert_equal false, effect(type: :Boolean).default
        assert_equal 0, effect(type: :Integer).default
        assert_equal(-1, effect(type: :Position).default)
        assert_equal(-1, effect(type: :PartyPosition).default)
        [:Type, :Pokemon, :Move, :Item, :Species, :Ability, :Hash, :String, :Array].each do |type|
            assert_nil effect(type: type).default, type.to_s
        end
    end

    def test_explicit_default_is_kept
        assert_equal true, effect(default: true).default
        assert_equal 5, effect(type: :Integer, default: 5).default
        assert_equal 2, effect(type: :Position, default: 2).default
        assert_equal "x", effect(type: :String, default: "x").default
    end

    def test_info_displayed_is_true_unless_given
        assert_equal true, effect.info_displayed
        assert_equal false, effect(info_displayed: false).info_displayed
    end

    def test_tick_amount_is_one_unless_given
        assert_equal 1, effect.tick_amount
        assert_equal 3, effect(type: :Integer, tick_amount: 3).tick_amount
    end

    # checkForInvalidDefinitions

    def test_non_integer_refuses_an_increment_proc
        assert_raises(RuntimeError) { effect(increment_proc: proc {}) }
    end

    def test_non_integer_refuses_an_expire_proc
        assert_raises(RuntimeError) { effect(expire_proc: proc {}) }
    end

    def test_non_integer_refuses_ticking_by_any_flag
        assert_raises(RuntimeError) { effect(ticks_down_eor: true) }
        assert_raises(RuntimeError) { effect(ticks_down_sor: true) }
        assert_raises(RuntimeError) { effect(ticks_down_proc: proc { true }) }
    end

    def test_non_integer_refuses_a_maximum
        assert_raises(RuntimeError) { effect(maximum: 3) }
    end

    def test_integer_accepts_what_non_integer_refuses
        effect(type: :Integer, increment_proc: proc {}, expire_proc: proc {}, ticks_down_eor: true,
               ticks_down_sor: true, ticks_down_proc: proc { true }, maximum: 3)
    end

    def test_entry_proc_is_refused_unless_position_or_side
        assert_raises(RuntimeError) { effect(entry_proc: proc {}, location: :Battler) }
        assert_raises(RuntimeError) { effect(entry_proc: proc {}, location: :Field) }
        assert_raises(RuntimeError) { effect(entry_proc: proc {}) }
        effect(entry_proc: proc {}, location: :Position)
        effect(entry_proc: proc {}, location: :Side)
    end

    # is_hazard? / is_protection?

    def test_is_hazard
        assert_equal true, effect(is_hazard: true).is_hazard?
        assert_equal true, effect(status_applying_hazard: :POISON).is_hazard?
        assert_equal false, effect.is_hazard?
    end

    def test_is_protection
        assert_equal true, effect(protection_info: { name: "x" }).is_protection?
        assert_equal true, effect(protection_effect: true).is_protection?
        assert_equal false, effect.is_protection?
    end

    # valid_value?

    def test_valid_value_boolean
        assert effect(type: :Boolean).valid_value?(true)
        refute effect(type: :Boolean).valid_value?(1)
    end

    def test_valid_value_integer
        assert effect(type: :Integer).valid_value?(4)
        refute effect(type: :Integer).valid_value?("4")
    end

    def test_valid_value_position_accepts_anything
        e = effect(type: :Position)
        assert e.valid_value?(1)
        assert e.valid_value?("anything")
        assert e.valid_value?(nil)
    end

    def test_valid_value_party_position
        e = effect(type: :PartyPosition)
        assert e.valid_value?(-1)
        assert e.valid_value?(3)
        refute e.valid_value?(-2)
    end

    def test_valid_value_game_data_types
        create_type(id: :FIRE)
        create_move(id: :EMBER)
        create_item(id: :POTION)
        create_ability(id: :BLAZE)
        create_species(id: :CHARMANDER)
        { Type: :FIRE, Move: :EMBER, Item: :POTION, Ability: :BLAZE, Species: :CHARMANDER }.each do |type, id|
            e = effect(type: type)
            assert e.valid_value?(id), "#{type} registered"
            refute e.valid_value?(:NOSUCHRECORD), "#{type} unregistered"
            assert e.valid_value?(nil), "#{type} nil"
        end
    end

    # Untested: a non-nil :Pokemon value, which needs the real Pokemon class. Coverage won't flag
    # it, since both cases sit on one `||` line.
    def test_valid_value_pokemon_accepts_nil
        assert effect(type: :Pokemon).valid_value?(nil)
    end

    def test_valid_value_hash_string_array
        assert effect(type: :Hash).valid_value?({ a: 1 })
        refute effect(type: :Hash).valid_value?([])
        assert effect(type: :String).valid_value?("s")
        refute effect(type: :String).valid_value?(:s)
        assert effect(type: :Array).valid_value?([1])
        refute effect(type: :Array).valid_value?({})
    end

    def test_valid_value_unknown_type_is_false
        refute effect(type: :Bogus).valid_value?(true)
        refute effect(type: :Bogus).valid_value?(nil)
    end

    # active_value?

    def test_active_value_boolean
        assert effect.active_value?(true)
        refute effect.active_value?(false)
    end

    def test_active_value_integer_is_measured_against_the_default
        e = effect(type: :Integer, default: 3)
        refute e.active_value?(3)
        assert e.active_value?(0)
        assert e.active_value?(4)
        assert effect(type: :Integer).active_value?(1)
        refute effect(type: :Integer).active_value?(0)
    end

    def test_active_value_integer_with_a_default_of_minus_one
        e = effect(type: :Integer, default: -1)
        assert e.active_value?(0)
        refute e.active_value?(-1)
    end

    def test_active_value_position_and_party_position
        [:Position, :PartyPosition].each do |type|
            e = effect(type: type)
            assert e.active_value?(0), type.to_s
            assert e.active_value?(2), type.to_s
            refute e.active_value?(-1), type.to_s
        end
    end

    def test_active_value_string
        e = effect(type: :String)
        assert e.active_value?("a")
        refute e.active_value?("")
        refute e.active_value?(nil)
    end

    def test_active_value_nilable_types
        create_type(id: :FIRE)
        create_move(id: :EMBER)
        create_item(id: :POTION)
        create_ability(id: :BLAZE)
        { Type: :FIRE, Move: :EMBER, Item: :POTION, Ability: :BLAZE }.each do |type, id|
            e = effect(type: type)
            assert e.active_value?(id), type.to_s
            refute e.active_value?(nil), type.to_s
        end
        assert effect(type: :Hash).active_value?({ a: 1 })
        refute effect(type: :Hash).active_value?(nil)
        refute effect(type: :Pokemon).active_value?(nil)
    end

    def test_active_value_array
        e = effect(type: :Array)
        assert e.active_value?([1])
        refute e.active_value?([])
        refute e.active_value?(nil)
    end

    def test_active_value_proc_overrides
        e = effect(type: :Integer, active_value_proc: proc { |value| value == 7 })
        assert e.active_value?(7)
        refute e.active_value?(1)
        e = effect(active_value_proc: proc { |_value| false })
        refute e.active_value?(true)
    end

    def test_active_value_raises_on_an_invalid_value
        assert_raises(RuntimeError) { effect(type: :Integer).active_value?("x") }
        assert_raises(RuntimeError) { effect(type: :Integer, active_value_proc: proc { true }).active_value?("x") }
    end

    # ticks_down

    def test_ticks_down_eor_and_sor_need_their_flag
        assert_equal false, effect(type: :Integer).ticks_down_eor?(nil, 1)
        assert_equal false, effect(type: :Integer).ticks_down_sor?(nil, 1)
        assert_equal false, effect(type: :Integer, ticks_down_sor: true).ticks_down_eor?(nil, 1)
        assert_equal false, effect(type: :Integer, ticks_down_eor: true).ticks_down_sor?(nil, 1)
        assert_equal true, effect(type: :Integer, ticks_down_eor: true).ticks_down_eor?(nil, 1)
        assert_equal true, effect(type: :Integer, ticks_down_sor: true).ticks_down_sor?(nil, 1)
    end

    def test_ticks_down_is_true_without_a_proc
        assert_equal true, effect(type: :Integer).ticks_down?(nil, 1)
    end

    def test_ticks_down_gives_the_procs_answer
        seen = nil
        e = effect(type: :Integer, ticks_down_eor: true, ticks_down_sor: true,
                   ticks_down_proc: proc { |battle, value|
                       seen = [battle, value]
                       value > 1
                   })
        assert_equal true, e.ticks_down?(:battle, 2)
        assert_equal [:battle, 2], seen
        assert_equal false, e.ticks_down?(:battle, 1)
        assert_equal true, e.ticks_down_eor?(:battle, 2)
        assert_equal false, e.ticks_down_eor?(:battle, 1)
        assert_equal true, e.ticks_down_sor?(:battle, 2)
        assert_equal false, e.ticks_down_sor?(:battle, 1)
    end

    # value_to_string

    def test_value_to_string_boolean_and_integer
        assert_equal "true", effect.value_to_string(true, nil)
        assert_equal "5", effect(type: :Integer).value_to_string(5, nil)
    end

    def test_value_to_string_position_is_the_battlers_name
        battle = FakeBattle.new([Named.new("Zero"), Named.new("One")])
        assert_equal "One", effect(type: :Position).value_to_string(1, battle)
    end

    def test_value_to_string_pokemon_and_string
        assert_equal "Mon", effect(type: :Pokemon).value_to_string(Named.new("Mon"), nil)
        assert_equal "text", effect(type: :String).value_to_string("text", nil)
    end

    def test_value_to_string_game_data_types
        create_type(id: :FIRE, name: "Fire")
        create_move(id: :EMBER, name: "Ember")
        create_item(id: :POTION, name: "Potion")
        create_ability(id: :BLAZE, name: "Blaze")
        create_species(id: :CHARMANDER, name: "Charmander")
        { Type: [:FIRE, "Fire"], Move: [:EMBER, "Ember"], Item: [:POTION, "Potion"],
          Ability: [:BLAZE, "Blaze"], Species: [:CHARMANDER, "Charmander"] }.each do |type, (id, name)|
            assert_equal name, effect(type: type).value_to_string(id, nil), type.to_s
        end
    end

    def test_value_to_string_is_error_when_a_lookup_raises
        [:Species, :Type, :Move, :Item, :Ability].each do |type|
            assert_equal "ERROR", effect(type: type).value_to_string(:NOSUCHRECORD, nil), type.to_s
        end
        assert_equal "ERROR", effect(type: :Position).value_to_string(0, FakeBattle.new([])), "Position"
        assert_equal "ERROR", effect(type: :Pokemon).value_to_string(nil, nil), "Pokemon"
    end

    def test_value_to_string_is_empty_for_other_types
        [:PartyPosition, :Hash, :Array, :Bogus].each do |type|
            assert_equal "", effect(type: type).value_to_string([1], nil), type.to_s
        end
    end

    # baton_pass_value

    def test_baton_pass_value_is_unchanged_without_a_proc
        assert_equal 4, effect(type: :Integer).baton_pass_value(:battler, 4)
    end

    def test_baton_pass_value_is_the_procs_answer
        seen = nil
        e = effect(type: :Integer, pass_value_proc: proc { |battler, value|
            seen = [battler, value]
            value + 10
        })
        assert_equal 14, e.baton_pass_value(:battler, 4)
        assert_equal [:battler, 4], seen
    end

    # each_sub_effect

    def test_each_sub_effect_yields_ids_in_order
        a = register(:Battler, :SUBA)
        b = register(:Battler, :SUBB)
        e = effect(sub_effects: [:SUBB, :SUBA])
        ids = []
        e.each_sub_effect { |id| ids << id }
        assert_equal [:SUBB, :SUBA], ids
        pairs = []
        e.each_sub_effect(true) { |id, data| pairs << [id, data] }
        assert_equal [[:SUBB, b], [:SUBA, a]], pairs
    end

    def test_each_sub_effect_yields_nothing_without_sub_effects
        yielded = false
        effect.each_sub_effect { yielded = true }
        refute yielded
    end

    # register_effect and iteration

    def test_register_effect_sets_the_location_and_registers
        record = register(:Side, :SIDEFX)
        assert_equal :Side, record.location
        assert_same record, GameData::BattleEffect.get(:SIDEFX)
    end

    def test_each_location_iterator_yields_only_its_locations_effects
        battler = register(:Battler, :BFX)
        position = register(:Position, :PFX)
        side = register(:Side, :SFX)
        field = register(:Field, :FFX)
        {
            each_battler_effect: battler,
            each_position_effect: position,
            each_side_effect: side,
            each_field_effect: field,
        }.each do |iterator, expected|
            yielded = []
            GameData::BattleEffect.send(iterator) { |data| yielded << data }
            assert_equal [expected], yielded, iterator.to_s
        end
    end

    def test_each_effect_yields_all
        records = [register(:Battler, :BFX), register(:Position, :PFX), register(:Side, :SFX), register(:Field, :FFX)]
        yielded = []
        GameData::BattleEffect.each_effect { |data| yielded << data }
        assert_equal records.sort_by(&:id), yielded.sort_by(&:id)
    end
end
