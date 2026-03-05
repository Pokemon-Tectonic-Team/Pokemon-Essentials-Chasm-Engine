#===============================================================================
# Screen class for handling game logic
#===============================================================================
class MoveLearnerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(pkmn,movesProc,addFirstMove: false, singleUse: false)
    @scene.pbStartScene(pkmn, movesProc)
    loop do
      move = @scene.pbChooseMove
      if move
        learnedMove = pbLearnMove(pkmn, move, false, false, addFirstMove)
        if learnedMove && singleUse
          @scene.pbEndScene
          return true
        else
          @scene.regenerateMoveList
          @scene.refreshMoveList
        end
      else
        @scene.pbEndScene
        return false
      end
    end
  end
end