BattleHandlers::FieldEffectStatLossItem.add(:ROOMSERVICE,
    proc { |item, battler, battle|
        next false unless battle.field.effectActive?(:TrickstersDomain)
        next battler.tryLowerStat(:SPEED, battler, increment: 4, item: item)
    }
)
