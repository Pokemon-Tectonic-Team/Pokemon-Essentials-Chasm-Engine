BattleHandlers::AbilityOnEnemyStatGain.add(:PETTY,
    proc { |ability, battler, stat, increment, _user, _battle, _benefactor|
        battler.tryRaiseStat(stat, battler, increment: increment, ability: ability)
    }
)
