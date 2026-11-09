BattleHandlers::DamageCalcTargetAllyAbility.add(:FRIENDGUARD,
  proc { |ability, _user, target, _owner, _move, mults, _baseDmg, _types, aiCheck|
      mults[:final_damage_multiplier] *= 3 / 4.0
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAllyAbility.add(:MOONBLANKET,
  proc { |ability, user, target, _owner, _move, mults, _baseDmg, _types, aiCheck|
      if user.battle.moonGlowing?
          mults[:final_damage_multiplier] *= 3 / 4.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAllyAbility.add(:PROTECTIVEINSTINCT,
  proc { |ability, _user, target, _owner, _move, mults, _baseDmg, _types, aiCheck|
      if target.notFullyEvolved?
          mults[:final_damage_multiplier] *= 2 / 3.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcTargetAllyAbility.add(:RAINBOWGUARDIAN,
  proc { |ability, _user, target, owner, _move, mults, _baseDmg, _types, aiCheck|
      if owner.effectActive?(:ChoseStatus)
          mults[:final_damage_multiplier] *= 2 / 3.0
          target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)
