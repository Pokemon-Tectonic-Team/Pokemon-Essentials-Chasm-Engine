require_relative "../../../support/test_helper"

class VariablePowerMoveCodesTest < Minitest::Test
    def battler(**attrs)
        TestBattler.new(**attrs)
    end

    # Flail (ScalesWithLostHP)

    def test_flail_formula_at_the_documented_ratios
        { 1.0 => 25, 0.5 => 50, 0.3 => 70, 0.2 => 100, 0.15 => 120, 0.1 => 165 }.each do |ratio, power|
            assert_equal power, flailBasePowerFormula(ratio), "ratio #{ratio}"
        end
    end

    def test_flail_formula_caps_at_200
        assert_equal 200, flailBasePowerFormula(0.075)
    end

    def test_flail_takes_the_ratio_from_hp_over_totalhp
        move = make_move(PokeBattle_Move_ScalesWithLostHP)
        assert_equal 50, move.pbBaseDamage(0, battler(hp: 50, totalhp: 100), nil)
        assert_equal 100, move.pbBaseDamage(0, battler(hp: 20, totalhp: 100), nil)
    end

    def test_flail_at_zero_hp_raises
        move = make_move(PokeBattle_Move_ScalesWithLostHP)
        assert_raises(FloatDomainError) { move.pbBaseDamage(0, battler(hp: 0, totalhp: 100), nil) }
    end

    # Eruption (ScalesWithUserHP)

    def test_eruption_at_the_documented_hp
        move = make_move(PokeBattle_Move_ScalesWithUserHP)
        { 50 => 65, 75 => 95, 100 => 130, 125 => 160, 150 => 195 }.each do |hp, power|
            assert_equal power, move.pbBaseDamage(0, battler(hp: hp, totalhp: 100), nil), "#{hp}% HP"
        end
    end

    def test_eruption_clamps_below_50_and_above_150_percent
        move = make_move(PokeBattle_Move_ScalesWithUserHP)
        assert_equal 65, move.pbBaseDamage(0, battler(hp: 10, totalhp: 100), nil)
        assert_equal 195, move.pbBaseDamage(0, battler(hp: 200, totalhp: 100), nil)
    end

    # Gyro Ball (ScalesSlowerThanTarget)

    def gyro_ball_power(user_speed, target_speed)
        @move ||= make_move(PokeBattle_Move_ScalesSlowerThanTarget)
        @move.pbBaseDamage(0, battler(speed: user_speed), battler(speed: target_speed))
    end

    def test_gyro_ball_at_the_documented_speed_fractions
        { 2 => 50, 3 => 75, 4 => 100, 5 => 125, 6 => 150 }.each do |fraction, power|
            assert_equal power, gyro_ball_power(100, 100 * fraction), "1/#{fraction} of the target's speed"
        end
    end

    def test_gyro_ball_clamps_to_150_when_slower_still
        assert_equal 150, gyro_ball_power(100, 700)
    end

    def test_gyro_ball_is_40_when_equal_or_faster
        assert_equal 40, gyro_ball_power(100, 100)
        assert_equal 40, gyro_ball_power(200, 100)
    end

    def test_gyro_ball_at_zero_user_speed_raises
        assert_raises(FloatDomainError) { gyro_ball_power(0, 100) }
    end

    # Electro Ball (ScalesFasterThanTarget)

    def electro_ball_power(user_speed, target_speed)
        @move ||= make_move(PokeBattle_Move_ScalesFasterThanTarget)
        @move.pbBaseDamage(0, battler(speed: user_speed), battler(speed: target_speed))
    end

    def test_electro_ball_at_the_documented_speed_ratios
        { [50, 100] => 40, [100, 100] => 45, [150, 100] => 60, [200, 100] => 80,
          [300, 100] => 115, [400, 100] => 150 }.each do |(user, target), power|
            assert_equal power, electro_ball_power(user, target), "speeds #{user} vs #{target}"
        end
    end

    def test_electro_ball_clamps_to_150_when_faster_than_4x
        assert_equal 150, electro_ball_power(500, 100)
    end

    def test_electro_ball_at_zero_target_speed_raises
        assert_raises(FloatDomainError) { electro_ball_power(100, 0) }
    end
end
