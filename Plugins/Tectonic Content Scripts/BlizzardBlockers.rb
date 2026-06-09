def blockPlayerViaBlizzard
    weather(:Blizzard,10,20)
    pbWait(20)
    pbMessage(_INTL("...The blizzard pushes you back."))
    
    # Move player backwards
    new_move_route = getNewMoveRoute()
    new_move_route.skippable = true
    new_move_route.list.push(RPG::MoveCommand.new(PBMoveRoute::Backward))
    new_move_route.list.push(RPG::MoveCommand.new(0)) # End of move route
    get_player.force_move_route(new_move_route)

    weather(:Blizzard,5,20)
end