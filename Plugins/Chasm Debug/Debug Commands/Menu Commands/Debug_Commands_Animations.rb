  DebugMenuCommands.register("animeditor", {
    "parent"      => "animationsmenu",
    "name"        => _INTL("Battle Animation Editor"),
    "description" => _INTL("Edit the battle animations."),
    "always_show" => true,
    "effect"      => proc {
      pbFadeOutIn { pbAnimationEditor }
    }
  })
  
  DebugMenuCommands.register("animorganiser", {
    "parent"      => "animationsmenu",
    "name"        => _INTL("Battle Animation Organiser"),
    "description" => _INTL("Rearrange/add/delete battle animations."),
    "always_show" => true,
    "effect"      => proc {
      pbFadeOutIn { pbAnimationsOrganiser }
    }
  })
  
  DebugMenuCommands.register("importanims", {
    "parent"      => "animationsmenu",
    "name"        => _INTL("Import All Battle Animations"),
    "description" => _INTL("Import all battle animations from the \"Animations\" folder."),
    "always_show" => true,
    "effect"      => proc {
      pbImportAllAnimations
    }
  })
  
  DebugMenuCommands.register("exportanims", {
    "parent"      => "animationsmenu",
    "name"        => _INTL("Export All Battle Animations"),
    "description" => _INTL("Export all battle animations individually to the \"Animations\" folder."),
    "always_show" => true,
    "effect"      => proc {
      pbExportAllAnimations
    }
  })

  DebugMenuCommands.register("compileanims", {
    "parent"      => "animationsmenu",
    "name"        => _INTL("Compile Battle Animations"),
    "description" => _INTL("Compile the information that links moves to animations."),
    "always_show" => true,
    "effect"      => proc {
      Compiler.compile_animations
    }
  })