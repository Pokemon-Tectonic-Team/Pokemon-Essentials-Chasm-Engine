SaveData.register_conversion(:converting_switches_340) do
  game_version '3.4.0'
  display_title 'Converting some event switches into global switches.'
  to_all do |save_data|
    globalSwitches = save_data[:switches]
    globalVariables = save_data[:variables]
    selfSwitches = save_data[:self_switches]

    globalSwitches[51] = selfSwitches[[26,3,'C']] # Avatar of Vigoroth defeated in Bluepoint Grotto

    globalSwitches[54] = selfSwitches[[282,3,'B']] # Catacombs Sang defeated
    globalSwitches[55] = selfSwitches[[282,4,'B']] # Catacombs Plot completed
  end
end