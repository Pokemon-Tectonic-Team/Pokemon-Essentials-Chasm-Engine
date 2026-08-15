#===============================================================================
# Attacks 2 rounds in the future. (Future Sight, etc.)
#===============================================================================
class PokeBattle_Move_AttackTwoTurnsLater < PokeBattle_ForetoldMove
end

# Empowered Future Sight
class PokeBattle_Move_EmpoweredFutureSight < PokeBattle_Move_AttackTwoTurnsLater
    include EmpoweredMove
end

#===============================================================================
# Choose between Ice, Fire, and Electric. This move attacks 1 turn in
# the future with an attack of that type. (Fire for Effect)
#===============================================================================
class PokeBattle_Move_AttackOneTurnLaterChooseIceFireElectricType < PokeBattle_ForetoldMove
    def initialize(battle, move)
        super
        @turnCount = 2
    end

    def resolutionChoice(user, replayed_choice)
        return nil if damagingMove?
        validTypes = %i[FIRE ELECTRIC ICE]
        validTypeNames = validTypes.map { |typeID| GameData::Type.get(typeID).name }
        @chosenType = pbChooseOption(user, validTypes, validTypeNames,
                                      _INTL("Which type should {1} launch?", user.pbThis(true)), replayed_choice)
    end

    def pbEffectAgainstTarget(user, target)
        super
        unless @battle.foretoldMove
            target.position.applyEffect(:ForetoldMoveType, @chosenType)
        end
    end

    def pbDisplayUseMessage(user, targets)
        super
        if @battle.foretoldMove
            @battle.pbDisplay(_INTL("It's an explosion of pure {1}!", GameData::Type.get(@calcType).name))
        end
    end
end