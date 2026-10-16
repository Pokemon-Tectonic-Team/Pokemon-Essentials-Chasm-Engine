BattleHandlers::CertainSwitchingUserItem.add(:SHEDSHELL,
    proc { |item, switcher, battle, trappingProc|
        if trappingProc
            itemData = GameData::Item.get(item)
            battle.pbDisplay(_INTL("{1} can slip free with its {2}!", switcher.pbThis, itemData.real_name))
        end
        next true
    }
)
