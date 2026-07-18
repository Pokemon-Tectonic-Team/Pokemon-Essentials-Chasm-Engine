#===============================================================================
# Cannot be used if the same move was used last. (Flame Fist, Frost Fist, Flux Fist)
#===============================================================================
class PokeBattle_Move_CantRepeat < PokeBattle_Move
    def pbCanChooseMove?(user, commandPhase, show_message)
        if user.lastMoveUsed && @id == user.lastMoveUsed
            if show_message
                msg = _INTL("{1} can't repeat that move!", user.pbThis)
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            return false
        end
        return true
    end
end