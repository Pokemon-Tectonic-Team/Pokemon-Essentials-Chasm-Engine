BattleHandlers::DamageCalcUserAllyAbility.add(:POWERSPOT,
    proc { |ability, user, _target, _move, mults, _baseDmg, _types, aiCheck|
        mults[:final_damage_multiplier] *= 13 / 10.0
        user.aiLearnsAbility(ability) unless aiCheck
    }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:STEELYSPIRIT,
  proc { |ability, user, _target, _move, mults, _baseDmg, types, aiCheck|
      if types.include?(:STEEL)
          mults[:base_damage_multiplier] *= 3 / 2.0
          user.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:VERDANT,
    proc { |ability, user, _target, _move, mults, _baseDmg, types, aiCheck|
        if types.include?(:GRASS)
            mults[:base_damage_multiplier] *= 3 / 2.0
            user.aiLearnsAbility(ability) unless aiCheck
        end
    }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:TOXICATTITUDE,
    proc { |ability, user, _target, _move, mults, _baseDmg, types, aiCheck|
        if types.include?(:POISON)
            mults[:base_damage_multiplier] *= 3 / 2.0
            user.aiLearnsAbility(ability) unless aiCheck
        end
    }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:HIVEMIND,
  proc { |ability, user, _target, _move, mults, _baseDmg, types, aiCheck|
      if types.include?(:BUG)
          mults[:base_damage_multiplier] *= 3 / 2.0
          user.aiLearnsAbility(ability) unless aiCheck
      end
  }
)
