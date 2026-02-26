def openSingleMoveDexScreen(move, moveList = nil, moveIndex = nil)
  # Handle if move is passed as an array [move_id, level] or similar
  move = move[0] if move.is_a?(Array)
  
  # Use passed move list if available, otherwise build it
  if moveList.nil?
    moveList = []
    GameData::Move.each do |moveData|
      next unless moveData.learnable?
      next unless moveInfoViewable?(moveData.id)
      moveList.push({
        :move => moveData.id,
        :data => moveData
      })
    end
    moveList.sort_by! { |dex_item| dex_item[:data].name }
    moveIndex = moveList.index { |entry| entry[:move] == move } || 0
  else
    # If moveList is passed from MasterDex, convert to proper format and find index
    formattedMoveList = []
    moveList.each do |item|
      # Handle both [[level, move], ...] and [move, ...] formats
      moveSymbol = item.is_a?(Array) ? item[1] : item
      moveData = GameData::Move.get(moveSymbol)
      next unless moveInfoViewable?(moveSymbol)
      formattedMoveList.push({
        :move => moveData.id,
        :data => moveData
      })
      moveIndex = formattedMoveList.length - 1 if moveData.id == move
    end
    moveList = formattedMoveList
    moveIndex = moveIndex || 0
  end
  
  pbFadeOutIn do
    scene = MoveDex_Entry_Scene.new
    screen = MoveDex_Entry_Screen.new(scene)
    screen.pbStartScreen(moveList, moveIndex)
  end
end