# Builds a real battle move for a test, over a registered move record. Included into every test,
# so a test calls make_move(PokeBattle_Move_TargetActsLast, battle: battle) and gets the move.
module MoveFactory
    # Registers a move record from id and attrs (create_move's defaults apply), then returns
    # move_class built for battle over a Pokemon::Move of that record.
    def make_move(move_class = PokeBattle_Move, battle: nil, id: :TESTMOVE, **attrs)
        create_move(id: id, total_pp: 1, **attrs)
        move_class.new(battle, Pokemon::Move.new(id))
    end
end
