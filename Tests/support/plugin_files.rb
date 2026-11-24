# The game code the tests load for real: core script entries by archive name, and plugin files
# relative to Plugins/. Both load in the engine's order, whatever their order here.
module PluginFiles
    CORE_SCRIPTS = %w[
        RubyUtilities
        FileTests
        Intl_Messages
        PBDebug
        Validation
        Compiler
        PluginManager
    ].freeze

    PLUGIN_FILES = [
        "_Settings/GameSettings.rb",
        "Chasm Game Data/GameData.rb",
        "Chasm Game Data/AvatarConstants.rb",
        "Chasm Game Data/Compiled Data/Type.rb",
        "Chasm Game Data/Compiled Data/Ability.rb",
        "Chasm Game Data/Compiled Data/Item.rb",
        "Chasm Game Data/Compiled Data/Move.rb",
        "Chasm Game Data/Compiled Data/Species.rb",
        "Chasm Game Data/Static Data/Stat.rb",
        "Chasm Game Data/Static Data/Status.rb",
        "Chasm Game Data/Static Data/Target.rb",
        "Chasm Battle/Effects/BattleEffect.rb",
    ].freeze
end
