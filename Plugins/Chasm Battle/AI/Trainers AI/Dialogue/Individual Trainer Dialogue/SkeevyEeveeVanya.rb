PokeBattle_AI::PlayerSendsOutPokemonDialogue.add(:SKEEVY_EEVEE_VANYA,
  proc { |_policy, battler, trainer_speaking, dialogue_array|
      echoln("KYUREM DIALOGUE TRIGGERED")
      if battler.countsAs?(:KYUREM) && !trainer_speaking.policyStates[:PlayerKyuremDialogue]
          dialogue_array.push(_INTL("Oh, hiiii Kyurem! You being a good Pokemon for my friend?"))
          dialogue_array.push(_INTL("It's really COOL of you to bring it like I asked."))
          dialogue_array.push(_INTL("Thanks."))
          trainer_speaking.policyStates[:PlayerKyuremDialogue] = true
      end
      next dialogue_array
  }
)