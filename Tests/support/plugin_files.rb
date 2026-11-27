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
        SaveData
        SaveData_Value
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
        "Chasm Game Data/Compiled Data/Encounters.rb",
        "Chasm Game Data/Compiled Data/Avatar.rb",
        "Chasm Game Data/Compiled Data/Policies.rb",
        "Chasm Game Data/Compiled Data/Trainer.rb",
        "Chasm Game Data/Compiled Data/TrainerType.rb",
        "Chasm Game Data/Compiled Data/Tribe.rb",
        "Chasm Game Data/Compiled Data/SignatureAnalysis.rb",
        "Chasm Game Data/Static Data/Evolution.rb",
        "Chasm Game Data/Static Data/Stat.rb",
        "Chasm Game Data/Static Data/Status.rb",
        "Chasm Game Data/Static Data/Target.rb",
        "Chasm Battle/Effects/BattleEffect.rb",
        "Chasm Battle/BattleHandlers.rb",
        "Chasm Battle/AI/AI_Boss.rb",
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
        "Chasm Battle/Battle/PokeBattle_Catching.rb",
        "Chasm Battle/Battle/PokeBattle_Weather.rb",
        "Chasm Battle/Items/ItemHandlerHelpers.rb",
        "Chasm Battle/Items/BattleHandlers/Damage/DamageCalcUserItems.rb",
        "Chasm Battle/Abilities/Ability Event Handlers/Modify Move/MoveBaseTypeModifierAbilities.rb",
        "Chasm Game Processing/Scene_Map.rb",
        "Chasm Other/Event Helpers/Misc.rb",
        "Chasm Other/SpeciesMetaHelper.rb",
        "Chasm Debug/Debug Menus/Debug_MenuExtraCode.rb",
        "Chasm Debug/Debug Commands/DebugMenuCommands.rb",
        "Chasm Debug/Debug Commands/Menu Commands/Debug_Commands_Analysis.rb",
        "Chasm Debug/Debug Commands/Menu Commands/Debug_Commands_Information.rb",
        "Chasm Debug/Debug Commands/Menu Commands/Debug_Commands_Other.rb",
        "Chasm Graphics and UI/Menus/Options/Options.rb",
        "Chasm Graphics and UI/Menus/Options/OptionsHelperMethods.rb",
        "Chasm Graphics and UI/Objects and windows/Window.rb",
        "Chasm Graphics and UI/Objects and windows/Sprite Window/SpriteWindow.rb",
        "Chasm Graphics and UI/Objects and windows/Sprite Window/SpriteWindow_text.rb",
        "Chasm Graphics and UI/Objects and windows/AnimatedBitmap.rb",
        "Chasm Graphics and UI/Objects and windows/RPG_Cache.rb",
        "Chasm Graphics and UI/Objects and windows/DrawText.rb",
        "Chasm Graphics and UI/Objects and windows/MessageConfig.rb",
        "Chasm Graphics and UI/Objects and windows/Messages.rb",
        "Chasm Graphics and UI/Objects and windows/FaceSpecs.rb",
        "Chasm Graphics and UI/Objects and windows/ShinyFaces.rb",
        "Chasm Graphics and UI/Objects and windows/Dialogue Labels/DialogueLabels.rb",
        "Chasm Graphics and UI/Objects and windows/Dialogue Portraits/PortraitCommands.rb",
        "Chasm Graphics and UI/Objects and windows/Dialogue Labels/SpeakerTagPlacement.rb",
        "Chasm Graphics and UI/Objects and windows/Dialogue Portraits/DialoguePortraits.rb",
        "Chasm Graphics and UI/Objects and windows/Sprite Window/WindowskinInsets.rb",
        "Chasm Graphics and UI/Graphics Code/BitmapHueShifts.rb",
        "Chasm Graphics and UI/Menus/Move Tutoring/EggMoveTutor.rb",
        "Chasm MasterDex/Config.rb",
        "Chasm MasterDex/Other.rb",
    ].freeze
end
