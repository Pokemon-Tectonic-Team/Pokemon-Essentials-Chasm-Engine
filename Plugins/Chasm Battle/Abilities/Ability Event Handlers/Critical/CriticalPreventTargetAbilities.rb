BattleHandlers::LoadDataDependentAbilityHandlers += proc {
    GameData::Ability.getByFlag("CritImmunity").each do |abilityID|
        BattleHandlers::CriticalPreventTargetAbility.add(abilityID,
          proc { |_ability, _user, _target, _battle|
              next true
          }
        )
    end
}
