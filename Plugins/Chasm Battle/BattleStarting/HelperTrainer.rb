# A class for a type of ally trainer that does not appear in the battle directly
# but occasionally assists by using moves of their own from outside
# Can do so for the player or for opposing trainers
class HelperTrainer
    attr_reader :trainer
	attr_reader :turnsPerAction

    DEFAULT_TURNS_PER_ACTION = 5

    def initialize(trainer, turnsPerAction: DEFAULT_TURNS_PER_ACTION)
      	@trainer = trainer
		@turnsPerAction = turnsPerAction
		@turnTimer = 0
		@moveToUse = nil
		@partyIndex = 0
    end

	def full_name
		return trainer.full_name
	end

	# Returns nil, or the move to use this turn
	def pickActionStartOfRound
		@turnTimer += 1
		if @turnTimer > @turnsPerAction
			@turnTimer = 0
			@pokemonToUseMove = trainer.party[@partyIndex]
			@moveToUse = @pokemonToUseMove.moves[0] # TO DO will want more complex logic here in the future
		else
			@pokemonToUseMove = nil
			@moveToUse = nil
		end
	end

	def announceSelectedMove(battle, forOpponent: false)
		if @moveToUse
			if forOpponent
				battle.pbDisplayBossNarration(_INTL("{1} is ready to help your foe!", full_name))
				battle.pbDisplayBossNarration(_INTL("Their {1} will use {2}!",@pokemonToUseMove.name,@moveToUse.name))
			else
				battle.pbDisplayBossNarration(_INTL("{1} is ready to help you this turn!", full_name))
				battle.pbDisplayBossNarration(_INTL("Their {1} will use {2}!",@pokemonToUseMove.name,@moveToUse.name))
			end
		end
	end

	def useSelectedMove(battle,sideIndex)
		moveUser = PokeBattle_Battler.new(battle, sideIndex)
		moveUser.pbInitDummyPokemon(@pokemonToUseMove, @partyIndex, true)
		moveUser.pbUseMoveSimple(@moveToUse.id)
	end
end