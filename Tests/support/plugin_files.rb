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
        EventSystem
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
        "Chasm Battle/BattleHandlers.rb",
        "Chasm Battle/Battler/Battler_Properties.rb",
        "Chasm Battle/Pokemon/Pokemon_Move.rb",
        "Chasm Battle/Move/PokeBattle_Move.rb",
        "Chasm Battle/Move/Move_Usage.rb",
        "Chasm Battle/Move Codes/ParentMoveCodes.rb",
        "Chasm Battle/Move Codes/Damage modifying/Move_Codes_VariablePower.rb",
        "Chasm Battle/Move Codes/Move_Codes_FixedDamage.rb",
        "Chasm Battle/Move Codes/Move_Codes_HelpingHand.rb",
        "Chasm Battle/Move Codes/Move_Codes_MoveOrder.rb",
        "Chasm Battle/Battle/PokeBattle_Battle.rb",
        "Chasm Battle/Battle/PokeBattle_Weather.rb",
        "Chasm Battle/Items/ItemHandlerHelpers.rb",
        "Chasm Battle/Items/BattleHandlers/Damage/DamageCalcUserItems.rb",
        "Chasm Battle/Abilities/Ability Event Handlers/Modify Move/MoveBaseTypeModifierAbilities.rb",
    ].freeze
end
