require_relative "../../../../support/test_helper"

# Item to boosted type, from each item's description in PBS/items.txt.
class DamageCalcUserItemsTest < Minitest::Test
    TYPE_ITEMS = {
        CHARCOAL: :FIRE,
        MYSTICWATER: :WATER,
        MAGNET: :ELECTRIC,
        MIRACLESEED: :GRASS,
        NEVERMELTICE: :ICE,
        BLACKBELT: :FIGHTING,
        POISONBARB: :POISON,
        SOFTSAND: :GROUND,
        SHARPBEAK: :FLYING,
        TWISTEDSPOON: :PSYCHIC,
        SILVERPOWDER: :BUG,
        HARDSTONE: :ROCK,
        SPELLTAG: :GHOST,
        DRAGONFANG: :DRAGON,
        BLACKGLASSES: :DARK,
        METALCOAT: :STEEL,
        SILKSCARF: :NORMAL,
        FAIRYFEATHER: :FAIRY,
    }.freeze

    def boost(item, move_type)
        mults = { base_damage_multiplier: 1.0 }
        BattleHandlers.triggerDamageCalcUserItem(item, TestBattler.new, TestBattler.new, nil, mults, 40, [move_type], true)
        mults[:base_damage_multiplier]
    end

    TYPE_ITEMS.each do |item, type|
        define_method("test_#{item.to_s.downcase}_boosts_only_#{type.to_s.downcase}") do
            other = type == :NORMAL ? :FIRE : :NORMAL
            assert_in_delta 1.2, boost(item, type)
            assert_equal 1.0, boost(item, other)
        end
    end
end
