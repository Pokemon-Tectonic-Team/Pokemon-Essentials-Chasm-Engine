BattleHandlers::StatusCureAbility.add(:MENTALBLOCK,
  proc { |ability, battler|
      battle = battler.battle

      activate = battler.hasMentalEffect? || battler.dizzy?

      if activate
          battle.pbShowAbilitySplash(battler, ability)
          battler.disableMentalEffects
          battler.pbCureStatus(true, :DIZZY) if battler.dizzy?
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::StatusCureAbility.add(:MINDLESS,
  proc { |ability, battler|
      battle = battler.battle

      if battler.hasMentalEffect?
          battle.pbShowAbilitySplash(battler, ability)
          battler.disableMentalEffects
          battle.pbHideAbilitySplash(battler)
      end
  }
)