require "stringio"
require_relative "../../support/test_helper"

class TrainerTest < Minitest::Test
    # The monument trainer list is a class instance variable, which the per-test reset doesn't
    # restore. No trainer is registered at load, so the list starts empty.
    def teardown
        GameData::Trainer.monumentTrainers.clear
    end

    def register_trainer(name, monument_trainer: true, lose_text: "...")
        return GameData::Trainer.register({
            id: [:LEADER, name, 0], id_number: name.length, trainer_type: :LEADER, name: name, version: 0,
            lose_text: lose_text, monument_trainer: monument_trainer
        })
    end

    def test_registering_a_monument_trainer_adds_it_to_the_monument_trainers
        ann = register_trainer("Ann")
        bert = register_trainer("Bert")

        assert_equal [ann, bert], GameData::Trainer.getMonumentTrainers
    end

    def test_a_trainer_registered_over_another_takes_its_place_among_the_monument_trainers
        register_trainer("Ann")

        replacement = register_trainer("Ann", lose_text: "Again!")

        assert_equal [replacement], GameData::Trainer.getMonumentTrainers
    end

    def test_a_replaced_monument_trainer_that_is_no_longer_one_leaves_the_monument_trainers
        register_trainer("Ann")

        register_trainer("Ann", monument_trainer: false)

        assert_empty GameData::Trainer.monumentTrainers
    end

    # Version `version` of Ann, with the given party
    def register_party(version, pokemon, extends_version: -1)
        return GameData::Trainer.register({
            id: [:LEADER, "Ann", version], id_number: 10 + version, trainer_type: :LEADER, name: "Ann",
            version: version, pokemon: pokemon, extends_version: extends_version
        })
    end

    def written_trainer(trainer)
        io = StringIO.new
        Compiler.write_trainer_to_file(trainer, io)
        return io.string
    end

    def party_member(level, name: nil, happiness: 100, species: :GARCHOMP)
        return { species: species, level: level, name: name, happiness: happiness }
    end

    # What the child's party member is written as, after the header and ExtendsVersion lines
    def written_child_of(parent_pokemon, child_pokemon)
        [parent_pokemon, child_pokemon].map { |pkmn| pkmn[:species] }.uniq.each do |species|
            create_species(id: species)
            without_form_moves(species)
        end
        register_party(0, [parent_pokemon])
        written = written_trainer(register_party(1, [child_pokemon], extends_version: 0))
        return written.delete_prefix("#-------------------------------\r\n[LEADER,Ann,1]\r\nExtendsVersion = 0\r\n")
    end

    def test_a_party_member_matching_no_parent_member_writes_every_field
        written = written_child_of(party_member(50, name: "Chompy"), party_member(60, name: "Rex"))

        assert_equal "Pokemon = GARCHOMP,60\r\n    Name = Rex\r\n    Happiness = 100\r\n", written
    end

    def test_unnamed_party_members_at_different_levels_dont_match
        written = written_child_of(party_member(50), party_member(60))

        assert_equal "Pokemon = GARCHOMP,60\r\n    Happiness = 100\r\n", written
    end

    def test_a_party_member_of_another_species_at_the_same_level_doesnt_match
        written = written_child_of(party_member(50, species: :GIBLE), party_member(50))

        assert_equal "Pokemon = GARCHOMP,50\r\n    Happiness = 100\r\n", written
    end

    def test_a_party_member_at_a_parent_members_level_omits_what_it_inherits
        written = written_child_of(party_member(50), party_member(50))

        assert_equal "Pokemon = GARCHOMP,50\r\n", written
    end

    def test_a_party_member_sharing_a_parent_members_nickname_omits_what_it_inherits
        written = written_child_of(party_member(50, name: "Chompy"), party_member(60, name: "Chompy"))

        assert_equal "Pokemon = GARCHOMP,60\r\n    Name = Chompy\r\n", written
    end

    def test_an_inherited_field_that_differs_is_still_written
        written = written_child_of(party_member(50), party_member(50, happiness: 200))

        assert_equal "Pokemon = GARCHOMP,50\r\n    Happiness = 200\r\n", written
    end

    def test_write_trainer_writes_the_header_and_what_it_extends
        register_party(0, [])
        written = written_trainer(register_party(1, [], extends_version: 0))

        assert_includes written, "[LEADER,Ann,1]\r\nExtendsVersion = 0\r\n"
    end

    def test_write_trainer_names_a_parent_of_another_name_in_full
        GameData::Trainer.register({
            id: [:LEADER, "Bea", 0], id_number: 20, trainer_type: :LEADER, name: "Bea", version: 0
        })
        trainer = GameData::Trainer.register({
            id: [:LEADER, "Ann", 0], id_number: 21, trainer_type: :LEADER, name: "Ann", version: 0,
            extends_class: :LEADER, extends_name: "Bea", extends_version: 0
        })

        assert_includes written_trainer(trainer), "[LEADER,Ann]\r\nExtends = LEADER,Bea,0\r\n"
    end

    def test_get_refuses_an_unknown_trainer
        error = assert_raises(RuntimeError) { GameData::Trainer.get(:LEADER, "Ann", 2) }

        assert_equal "Unknown trainer LEADER Ann 2.", error.message
    end

    def test_try_get_finds_a_registered_trainer_and_is_nil_for_an_unknown_one
        ann = register_trainer("Ann")

        assert_equal ann, GameData::Trainer.try_get("LEADER", "Ann")
        assert_nil GameData::Trainer.try_get(:LEADER, "Ann", 1)
    end

    def test_get_monument_trainers_gathers_the_registered_monument_trainers_when_the_list_is_empty
        ann = register_trainer("Ann")
        register_trainer("Bert", monument_trainer: false)
        GameData::Trainer.monumentTrainers.clear

        assert_equal [ann], GameData::Trainer.getMonumentTrainers
        assert_equal ann, GameData::Trainer.randomMonumentTrainer
    end

    def test_write_trainer_writes_the_trainers_own_properties
        trainer = GameData::Trainer.register({
            id: [:LEADER, "Ann", 0], id_number: 1, trainer_type: :LEADER, name: "Ann", version: 0,
            name_for_hashing: "Annie", trainer_type_label: :ACE, policies: [:CAREFUL], flags: ["Rematch"],
            items: [:POTION, :REVIVE]
        })

        assert_equal "#-------------------------------\r\n[LEADER,Ann]\r\nNameForHashing = Annie\r\nTrainerTypeLabel = ACE\r\n" \
                     "Policies = CAREFUL\r\nFlags = Rematch\r\nItems = POTION,REVIVE\r\n", written_trainer(trainer)
    end

    def test_write_trainer_leaves_out_the_policies_and_flags_it_inherits
        register_trainer_version(0, policies: [:CAREFUL], flags: ["Rematch"])
        trainer = register_trainer_version(1, extends_version: 0, policies: [:CAREFUL, :AGGRO], flags: ["Rematch", "Hard"])

        assert_includes written_trainer(trainer), "Policies = AGGRO\r\nFlags = Hard\r\n"
    end

    def test_write_trainer_writes_a_party_with_no_parent_and_its_removed_members
        create_species(id: :GARCHOMP)
        without_form_moves(:GARCHOMP)
        trainer = register_trainer_version(0, pokemon: [party_member(50)], removed_pokemon: [party_member(40, happiness: nil)])

        assert_equal "#-------------------------------\r\n[LEADER,Ann]\r\nPokemon = GARCHOMP,50\r\n    Happiness = 100\r\n" \
                     "RemovePokemon = GARCHOMP,40\r\n", written_trainer(trainer)
    end

    def register_trainer_version(version, **attributes)
        return GameData::Trainer.register({
            id: [:LEADER, "Ann", version], id_number: 30 + version, trainer_type: :LEADER, name: "Ann", version: version
        }.merge(attributes))
    end

    # writePartyMember

    def written_party_member(pkmn, inheriting_pkmn = nil)
        io = StringIO.new
        Compiler.writePartyMember(io, pkmn, inheriting_pkmn)
        return io.string
    end

    # A party member with every field set, and the line each writes, in the order they are written
    def full_party_member
        create_ability(id: :BLAZE)
        create_ability(id: :SOLAR)
        create_species(id: :BASE, abilities: [:BLAZE, :SOLAR])
        create_species(id: :BASE_1, species: :BASE, form: 1, form_name: "Alt", abilities: [:BLAZE, :SOLAR])
        pkmn = {
            species: :BASE, level: 50, assigned_position: 2, name: "Bob", form: 1, gender: 1, shininess: true,
            extra_types: [:FIRE], moves: [:EMBER, :SURF], ability: :BLAZE, ability_index: 1,
            extra_abilities: [:SOLAR], extra_moves: [:TACKLE], item: [:POTION, :REVIVE], extra_items: [:ORB],
            item_type: :WATER, nature: :BOLD,
            ev: { HP: 1, ATTACK: 2, DEFENSE: 3, SPECIAL_ATTACK: 4, SPECIAL_DEFENSE: 5, SPEED: 6 },
            happiness: 70, poke_ball: :GREATBALL
        }
        lines = [
            "    Position = 2\r\n", "    Name = Bob\r\n", "    Form = 1 # Alt Form\r\n", "    Gender = female\r\n",
            "    Shiny = yes\r\n", "    ExtraTypes = FIRE\r\n", "    Moves = EMBER,SURF\r\n", "    Ability = BLAZE\r\n",
            "    AbilityIndex = 1 # Solar\r\n", "    ExtraAbilities = SOLAR\r\n", "    ExtraMoves = TACKLE\r\n",
            "    Item = POTION,REVIVE\r\n", "    ExtraItems = ORB\r\n", "    ItemType = WATER\r\n", "    Nature = BOLD\r\n",
            "    # HP, Attack, Defense, Speed, Sp. Atk, Sp. Def\r\n    EV = 1,2,3,6,4,5\r\n", "    Happiness = 70\r\n",
            "    Ball = GREATBALL\r\n"
        ]
        return [pkmn, lines]
    end

    def test_write_party_member_writes_every_field_set
        pkmn, lines = full_party_member

        assert_equal lines.join, written_party_member(pkmn)
    end

    def test_write_party_member_leaves_out_every_inherited_field_matching_the_parent_member
        pkmn, lines = full_party_member

        # Position and Name are always written
        assert_equal lines.first(2).join, written_party_member(pkmn, pkmn.dup)
    end

    def test_write_party_member_writes_a_lone_item_a_male_gender_and_a_base_forms_abilities
        create_ability(id: :BLAZE)
        create_species(id: :BASE, abilities: [:BLAZE])

        written = written_party_member({ species: :BASE, gender: 0, item: :POTION, ability_index: 3 })

        assert_equal "    Gender = male\r\n    AbilityIndex = 3 # Blaze\r\n    Item = POTION\r\n", written
    end

    def test_write_party_member_leaves_out_empty_lists_and_names
        written = written_party_member({ species: :BASE, name: "", extra_types: [], moves: [], extra_abilities: [], extra_moves: [], extra_items: [] })

        assert_equal "", written
    end
end
