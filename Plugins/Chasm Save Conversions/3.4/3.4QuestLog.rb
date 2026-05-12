SaveData.register_conversion(:quest_log_3_4_0) do
  game_version '3.4.0'
  display_title 'Fixing some uncompletable quests from 3.3'
  to_all do |save_data|
      globalSwitches = save_data[:switches]
      globalVariables = save_data[:variables]
      selfSwitches = save_data[:self_switches]
      itemBag = save_data[:bag]

      questLog = save_data[:global_metadata].quests

      questLog.completeQuest(:QUEST_LEGEND_DRAGON_ISLE, skipAlert: true) if globalSwitches[89] # "Dragon Master Defeated"
      questLog.completeQuest(:QUEST_LEGEND_CLONE, skipAlert: true) if globalVariables[37] >= 3 # "Legend Cloning Quest Stage"
      questLog.completeQuest(:QUEST_LEGEND_VOLCANION2, skipAlert: true) if globalVariables[41] >= 8 # "Volcanion Quest Stage"
      questLog.completeQuest(:QUEST_GYM_AVATARS_3, skipAlert: true) if globalSwitches[128] # "Chamber 3 Cleared"
  end
end