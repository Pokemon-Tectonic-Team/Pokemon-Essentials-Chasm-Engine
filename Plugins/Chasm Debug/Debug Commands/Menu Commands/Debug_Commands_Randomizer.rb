DebugMenuCommands.register("startrandomizer", {
  "parent"      => "randomizer",
  "name"        => _INTL("Start the Randomizer"),
  "description" => _INTL("Starts the Randomizer"),
  "effect"      => proc { |_sprites, _viewport|
      Randomizer.start
  }
})

DebugMenuCommands.register("resetrandomizer", {
  "parent"      => "randomizer",
  "name"        => _INTL("Reset Randomizer"),
  "description" => _INTL("Reset the Randomizer"),
  "effect"      => proc { |_sprites, _viewport|
      Randomizer.reset
      pbMessage(_INTL("Randomizer was reset."))
  }
})
