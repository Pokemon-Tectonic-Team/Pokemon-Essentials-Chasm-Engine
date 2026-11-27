require "stringio"
require_relative "../../../support/test_helper"

class DebugCommandsAnalysisTest < Minitest::Test
    # A map event's parts, as RPG Maker XP keeps them: pages of commands, each with parameters
    FakeEvent = Struct.new(:id, :name, :pages)
    FakePage = Struct.new(:list)
    FakeCommand = Struct.new(:parameters)

    # Strings are unfrozen copies, as loaded map data holds, since the helpers edit them in place
    def event(*parameter_lists, name: "Old, Man")
        commands = parameter_lists.map do |parameters|
            FakeCommand.new(parameters.map { |parameter| parameter.is_a?(String) ? +parameter : parameter })
        end
        return FakeEvent.new(4, name, [FakePage.new(commands)])
    end

    # The helpers report through echoln, which resolves to this method when a test calls them
    def echoln(text)
        echoed.push(text.to_s)
    end

    def echoed
        return @echoed ||= []
    end

    # find_text_in_event

    def test_find_text_reports_each_matching_string_parameter_ignoring_case
        find_text_in_event(3, "Town", event(["Hello THERE", 5], ["nothing"]), "there")

        assert_equal ["Event \"Old Man\" (4) on map Town (3)", "\"Hello THERE\"\r\n"], echoed
    end

    def test_find_text_reports_nothing_without_a_match_or_an_event
        find_text_in_event(3, "Town", event(["Hello"]), "bye")
        find_text_in_event(3, "Town", nil, "bye")
        find_text_in_event(3, "Town", FakeEvent.new(4, "Empty", []), "bye")

        assert_empty echoed
    end

    # replace_text_in_event

    def test_replace_text_replaces_in_string_parameters_and_reports_the_change
        command_event = event(["Hello there", 5, "there there"])

        assert replace_text_in_event(3, "Town", command_event, "there", "you")
        assert_equal ["Hello you", 5, "you you"], command_event.pages[0].list[0].parameters
        assert_equal 4, echoed.length
    end

    def test_replace_text_also_replaces_the_lowercase_form
        command_event = event(["Hello there"])

        assert replace_text_in_event(3, "Town", command_event, "THERE", "you")
        assert_equal ["Hello you"], command_event.pages[0].list[0].parameters
    end

    def test_replace_text_is_false_when_nothing_changes
        command_event = event(["Hello"])

        refute replace_text_in_event(3, "Town", command_event, "bye", "you")
        refute replace_text_in_event(3, "Town", nil, "bye", "you")
        assert_equal ["Hello"], command_event.pages[0].list[0].parameters
    end

    # analyze_items

    def test_analyze_items_lists_every_item_given_with_its_count
        file = StringIO.new
        command_event = event(["pbReceiveItem(:POTION,3)"], ["pbItemBall(:REPEL)", "defeatBoss(:ORB)"], ["pbMessage(\"hi\")"])

        items = analyze_items(3, "Town", command_event, file)

        assert_equal %i[POTION REPEL ORB], items
        assert_equal "3,Town,4,Old Man,POTION,3\r\n3,Town,4,Old Man,REPEL,1\r\n3,Town,4,Old Man,ORB,1\r\n", file.string
    end

    def test_analyze_items_of_no_event_is_empty
        assert_empty analyze_items(3, "Town", nil, StringIO.new)
    end

    # describeCodeInstances

    def test_describe_code_instances_writes_each_match_and_what_the_block_adds
        file = StringIO.new
        regex = /pbSetSelfSwitch\((\d+)\)/

        describeCodeInstances(3, "Town", event(["pbSetSelfSwitch(12)", "other"]), file, regex) do |_e, _p, _c, _parameter, match|
            "\tswitch #{match[1]}\r\n"
        end

        assert_equal "Map \"Town\" (3), event \"Old Man\" (4)\r\n\tpbSetSelfSwitch(12)\r\n\tswitch 12\r\n", file.string
    end

    def test_describe_code_instances_without_a_block_writes_only_the_match
        file = StringIO.new

        describeCodeInstances(3, "Town", event(["pbFoo"]), file, /pbFoo/)
        describeCodeInstances(3, "Town", nil, file, /pbFoo/)

        assert_equal "Map \"Town\" (3), event \"Old Man\" (4)\r\n\tpbFoo\r\n", file.string
    end

    # replaceCodeInstances

    def test_replace_code_instances_rewrites_matching_parameters
        command_event = event(["pbOld(1)", 7, "keep"])

        assert replaceCodeInstances(3, "Town", command_event, /pbOld/, "pbNew")
        assert_equal ["pbNew(1)", 7, "keep"], command_event.pages[0].list[0].parameters
    end

    def test_replace_code_instances_is_false_when_nothing_matches
        refute replaceCodeInstances(3, "Town", event(["keep"]), /pbOld/, "pbNew")
    end

    # replaceAllCodeInstances saves a map when any of its events changed
    def test_replace_code_instances_is_false_without_an_event_or_pages
        assert_equal false, replaceCodeInstances(3, "Town", nil, /pbOld/, "pbNew")
        assert_equal false, replaceCodeInstances(3, "Town", FakeEvent.new(4, "Empty", []), /pbOld/, "pbNew")
    end

    # describeAbility

    def test_describe_ability_gives_name_and_description
        create_ability(id: :BLAZE, description: "Burns.")

        assert_equal "Blaze,\"Burns.\"", describeAbility(:BLAZE)
    end

    def test_describe_ability_adds_the_signature_wielder
        create_species(id: :CHARIZARD)
        create_ability(id: :BLAZE, description: "Burns.").signature_of = :CHARIZARD

        assert_equal "Blaze,\"Burns.\",Charizard", describeAbility(:BLAZE)
    end

    # describeMove

    def test_describe_move_lists_its_stats
        create_type(id: :FIRE)
        create_move(id: :EMBER, type: :FIRE, category: 1, base_damage: 40, accuracy: 100, total_pp: 25,
                    effect_chance: 10, target: :NearOther, priority: 1, description: "Burns.")

        assert_equal "Ember,,Fire,\"Burns.\",40,Special,100,25,NearOther,+1,10,", describeMove(:EMBER)
    end

    def test_describe_move_dashes_no_accuracy_and_a_certain_effect_and_names_the_wielder
        create_type(id: :FIRE)
        create_species(id: :CHARIZARD)
        create_move(id: :EMBER, type: :FIRE, accuracy: 0, effect_chance: 100, total_pp: 5, target: :User,
                    description: "Burns.").signature_of = :CHARIZARD

        assert_equal "Ember,Charizard,Fire,\"Burns.\",0,Status,-,5,User,0,-,", describeMove(:EMBER)
    end

    # checkTrainerPokemonLegality

    FakeMove = Struct.new(:id)
    FakeTrainerPokemon = Struct.new(:species, :form, :species_data, :moves, :name, :level)

    # The legality check reads each species' learnable moves
    def species(id, **attributes)
        without_form_moves(id)
        return create_species(id: id, flags: ["NoStaples"], **attributes)
    end

    def trainer_pokemon(species_data, level, *moves)
        return FakeTrainerPokemon.new(species_data.id, 0, species_data, moves.map { |id| FakeMove.new(id) }, species_data.real_name, level)
    end

    def test_a_move_the_species_cannot_learn_is_an_error
        %i[TACKLE SURF].each { |id| create_move(id: id) }
        solo = species(:SOLO, moves: [[1, :TACKLE]])

        checkTrainerPokemonLegality(trainer_pokemon(solo, 50, :TACKLE, :SURF), "LEADER,Ann,0")

        assert_equal ["ERROR: SURF learned illegaly on Solo on LEADER,Ann,0"], echoed
    end

    def test_a_sketcher_may_know_any_move
        create_move(id: :SKETCH, function_code: "ReplaceMoveWithTargetLastMoveUsed")
        create_move(id: :SURF)
        sketcher = species(:SKETCHER, moves: [[1, :SKETCH]])

        checkTrainerPokemonLegality(trainer_pokemon(sketcher, 50, :SURF), "LEADER,Ann,0")

        assert_empty echoed
    end

    def test_an_evolution_below_its_evolution_level_is_an_error
        species(:BASE, evolutions: [[:TOP, :Level, 30, false]])
        top = species(:TOP, evolutions: [[:BASE, :Level, 30, true]])

        checkTrainerPokemonLegality(trainer_pokemon(top, 29), "LEADER,Ann,0")
        checkTrainerPokemonLegality(trainer_pokemon(top, 30), "LEADER,Ann,0")

        assert_equal ["ERROR: Level 29 is too low to be able to aquire a Top on LEADER,Ann,0"], echoed
    end

    def test_an_item_evolution_below_level_32_is_a_warning
        species(:BASE, evolutions: [[:TOP, :Item, :FIRESTONE, false]])
        top = species(:TOP, evolutions: [[:BASE, :Item, :FIRESTONE, true]])

        checkTrainerPokemonLegality(trainer_pokemon(top, 31), "LEADER,Ann,0")
        checkTrainerPokemonLegality(trainer_pokemon(top, 32), "LEADER,Ann,0")

        assert_equal ["WARNING: Level 31 may be too low to reasonably aquire a Top on LEADER,Ann,0"], echoed
    end

    def test_an_unevolved_species_has_no_evolution_check
        base = species(:BASE, evolutions: [[:TOP, :Level, 30, false]])
        species(:TOP, evolutions: [[:BASE, :Level, 30, true]])

        checkTrainerPokemonLegality(trainer_pokemon(base, 1), "LEADER,Ann,0")

        assert_empty echoed
    end
end
