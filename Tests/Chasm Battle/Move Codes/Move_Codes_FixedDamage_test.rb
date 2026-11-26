require_relative "../../support/test_helper"

class FixedDamageMoveCodesTest < Minitest::Test
    # Super Fang (FixedDamageHalfTargetHP)

    def super_fang_damage(**target_attrs)
        move = make_move(PokeBattle_Move_FixedDamageHalfTargetHP)
        move.pbFixedDamage(TestBattler.new, TestBattler.new(**target_attrs))
    end

    def test_super_fang_halves_even_hp
        assert_equal 50, super_fang_damage(hp: 100)
    end

    def test_super_fang_rounds_odd_hp_half_up
        assert_equal 3, super_fang_damage(hp: 5)
    end

    def test_super_fang_applies_a_boss_resistance
        assert_equal 13, super_fang_damage(hp: 100, boss: true, hp_resistance: 0.25)
    end

    def test_super_fang_ignores_the_resistance_of_a_non_boss
        assert_equal 50, super_fang_damage(hp: 100, boss: false, hp_resistance: 0.25)
    end

    def test_super_fang_at_one_hp_is_one
        assert_equal 1, super_fang_damage(hp: 1)
    end

    # Endeavor (LowerTargetHPToUserHP)

    def endeavor(battle = TestBattle.new)
        make_move(PokeBattle_Move_LowerTargetHPToUserHP, battle: battle)
    end

    def test_endeavor_does_not_fail_against_a_higher_hp_target
        battle = TestBattle.new
        user = TestBattler.new(hp: 10)
        target = TestBattler.new(hp: 11)
        assert_equal false, endeavor(battle).pbFailsAgainstTarget?(user, target, true)
        assert_empty battle.messages
    end

    def test_endeavor_fails_when_the_user_has_more_hp
        battle = TestBattle.new
        user = TestBattler.new(hp: 20, name: "Ursa")
        target = TestBattler.new(hp: 10, name: "Foe")
        assert_equal true, endeavor(battle).pbFailsAgainstTarget?(user, target, true)
        assert_equal ["But it failed, since Ursa's health is greater than Foe's!"], battle.messages
    end

    def test_endeavor_fails_when_the_hp_is_equal
        battle = TestBattle.new
        user = TestBattler.new(hp: 10, name: "Ursa")
        target = TestBattler.new(hp: 10, name: "Foe")
        assert_equal true, endeavor(battle).pbFailsAgainstTarget?(user, target, true)
    end

    def test_endeavor_fails_against_a_boss
        battle = TestBattle.new
        user = TestBattler.new(hp: 10)
        target = TestBattler.new(hp: 50, boss: true, name: "Avatar")
        assert_equal true, endeavor(battle).pbFailsAgainstTarget?(user, target, true)
        assert_equal ["But it failed, since Avatar is an Avatar!"], battle.messages
    end

    def test_endeavor_displays_nothing_without_show_message
        battle = TestBattle.new
        move = endeavor(battle)
        assert_equal true, move.pbFailsAgainstTarget?(TestBattler.new(hp: 20), TestBattler.new(hp: 10), false)
        assert_equal true, move.pbFailsAgainstTarget?(TestBattler.new(hp: 10), TestBattler.new(hp: 50, boss: true), false)
        assert_empty battle.messages
    end

    def test_endeavor_damage_is_the_hp_difference
        assert_equal 70, endeavor.pbFixedDamage(TestBattler.new(hp: 30), TestBattler.new(hp: 100))
    end
end
