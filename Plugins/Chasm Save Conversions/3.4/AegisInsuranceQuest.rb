SaveData.register_conversion(:aegis_insurance_switches) do
  game_version '3.4.0'
  display_title 'Initializing the Aegis Insurance quest global switches.'
  to_all do |save_data|
    globalSwitches = save_data[:switches]
    globalVariables = save_data[:variables]
    selfSwitches = save_data[:self_switches]

    globalVariables[264] = selfSwitches[[171,2,'A']] # CEO beatrice gone
    globalVariables[265] = selfSwitches[[155,11,'C']] # Chose to spare CEO Beatrice
    globalVariables[266] = selfSwitches[[155,11,'B']] # Chose to battle Ceo Beatrice
  end
end