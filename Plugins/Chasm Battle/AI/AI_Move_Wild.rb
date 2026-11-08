class PokeBattle_AI
    def pbChooseMovesWild(idxBattler)
        battler = @battle.battlers[idxBattler]
        # Use move 0 (the first) on turn 1
        moveIndex = (battler.turnCount - 1) % battler.getMoves.length
        unless @battle.pbRegisterMove(idxBattler, moveIndex, false)
            @battle.pbAutoChooseMove(idxBattler)
        end
    end
end
