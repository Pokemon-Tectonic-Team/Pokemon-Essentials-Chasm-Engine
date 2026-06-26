# Tells PokemonPartyShowcase_Scene how much of a single Pokémon to draw: everything (the
# original full-info X-Ray, and every offline use of the showcase), or only what's actually
# been revealed so far in an online Cable Club match (the Poké X-Ray's note-taking mode). 
# Keeping this as its own small object - rather than threading battle/knowledge
# lookups directly into PartyShowcase.rb's drawing code - lets renderShowcaseInfo stay a single
# code path for both modes, just asking "is this known?" instead of branching on "are we
# online?" everywhere.
class PokeXRayRevealState
    attr_reader :pokemon

    def initialize(pokemon, known:, seen:, not_brought:, known_move_ids:, known_ability_ids:, known_item_ids:)
        @pokemon = pokemon
        @known = known
        @seen = seen
        @not_brought = not_brought
        @known_move_ids = known_move_ids
        @known_ability_ids = known_ability_ids
        @known_item_ids = known_item_ids
    end

    # Whether anything at all is known about this Pokémon (it's been previewed and/or sent
    # out) - if not, its row is skipped entirely, the same way PartyShowcase.rb already skips
    # an empty party slot.
    def known?; @known; end

    # Whether this Pokémon has actually been sent out at least once. Style Points are shown
    # once this is true (they're arithmetically derivable from the in-battle stat screen once
    # a Pokémon's level and stats have actually been seen), but not before.
    def seen?; @seen; end

    # True once it's certain this previewed Pokémon was never picked for the battle - i.e.
    # every slot of the trainer's actual battle roster has already been confirmed by being
    # sent out at least once, and this one wasn't among them.
    def not_brought?; @not_brought; end

    def move_known?(move_id); @known_move_ids.include?(move_id); end
    def ability_known?(ability_id); @known_ability_ids.include?(ability_id); end
    def item_known?(item_id); @known_item_ids.include?(item_id); end

    # Everything about pokemon is visible - used for offline trainer battles and the overworld
    # Poké X-Ray, where the showcase has always shown full info.
    def self.full(pokemon)
        moveIDs = pokemon.moves.map { |move| move.id }
        moveIDs += pokemon.extraMoves if pokemon.hasExtraMoves?
        abilityIDs = pokemon.ability_id ? [pokemon.ability_id] : []
        abilityIDs += pokemon.extraAbilities if pokemon.hasExtraAbilities?
        return new(pokemon, known: true, seen: true, not_brought: false,
            known_move_ids: moveIDs, known_ability_ids: abilityIDs, known_item_ids: pokemon.items)
    end

    # One state per Pokémon there's any knowledge of for the given opponent trainer in an
    # online battle - every previewed Pokémon if team preview revealed the trainer's full
    # roster, otherwise just the trainer's actual battle roster (filtered down to whichever of
    # those have been sent out, since with no preview there's nothing else to show).
    #
    # The opponent's Pokémon always live on side 1 (PokeBattle_CableClub.new always assigns
    # the opponent's party to party2/side 1, regardless of which client is "us") - this is only
    # ever used for the X-Ray's online mode, which only ever scouts @battle.opponent, so that's
    # hardcoded rather than threaded through as a parameter.
    def self.compute_all(trainer, battle)
        sideIndex = 1
        battleRoster = trainer.party
        previewedRoster = battle.previewed_opponent_party
        sentOutCount = battle.usedInBattle[sideIndex].count(true)
        capReached = sentOutCount >= battleRoster.length
        roster = previewedRoster || battleRoster.select { |pkmn| battle.usedInBattle[sideIndex][battleRoster.index(pkmn)] }
        return roster.map { |pokemon| compute(pokemon, battle, sideIndex, battleRoster, capReached) }
    end

    def self.compute(pokemon, battle, sideIndex, battleRoster, capReached)
        partyIndex = battleRoster.index { |pkmn| pkmn.personalID == pokemon.personalID }
        seen = !partyIndex.nil? && battle.usedInBattle[sideIndex][partyIndex]
        notBrought = !seen && capReached
        return new(pokemon, known: true, seen: seen, not_brought: notBrought,
            known_move_ids: battle.aiKnownMoves(pokemon),
            known_ability_ids: battle.aiKnownAbilities(pokemon),
            known_item_ids: battle.aiKnownItems(pokemon))
    end
end
