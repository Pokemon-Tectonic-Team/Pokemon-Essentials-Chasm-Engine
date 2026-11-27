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

    # The debug menu commands. Each runs with the test as self, so its pbMessage and echoln calls
    # resolve to the test's own, in an empty folder holding Analysis/. checkbattlecontentlegality
    # is untested: it builds every trainer's party, which needs the game's Pokémon and trainers.

    def pbMessage(text, *)
        messages.push(text)
    end

    def messages
        return @messages ||= []
    end

    # The file the command writes to Analysis/, or nil when given none
    def run_command(option, file = nil)
        Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
                FileUtils.mkdir_p("Analysis")
                instance_exec(&DebugMenuCommands.getFunction(option, "effect"))
                return file ? File.binread("Analysis/#{file}") : nil
            end
        end
    end

    # A two-stage line, BASE into TOP, plus TOP's forms 1 and 2, which the analyses skip. Form 1's
    # name holds a "%", as the PBS form names some analyses strip do; form 2 has none.
    def two_stage_line(base: {}, top: {}, form: {})
        species(:BASE, id_number: 1, evolutions: [[:TOP, :Level, 30, false]], **base)
        species(:TOP, id_number: 2, evolutions: [[:BASE, :Level, 30, true]], **top)
        species(:TOP_1, id_number: 3, species: :TOP, form: 1, form_name: +"100% Form", **form)
        species(:TOP_2, id_number: 4, species: :TOP, form: 2, **form)
    end

    def test_analyze_distribution_counts_how_each_final_species_learns_each_move
        %i[FIRE WATER].each { |id| create_type(id: id) }
        create_move(id: :EMBER, id_number: 1, type: :FIRE)
        create_move(id: :SURF, id_number: 2, type: :WATER, category: 1)
        create_type(id: :NORMAL)
        create_move(id: :OLDMOVE, id_number: 3, cut: true)
        two_stage_line(base: { line_moves: %i[SURF EMBER] },
                       top: { type1: :FIRE, moves: [[1, :EMBER], [5, :EMBER]], tutor_moves: [:SURF] },
                       form: { moves: [[1, :SURF]] })

        written = run_command("analyzedistribution", "move_distribution.txt")

        assert_equal "Move, Type, Category, Level Up Count, Tutor Count, Same-Type Count, Off-type Count\r\n" \
                     "EMBER,FIRE,PHYSICAL,1,1,1,0\r\nSURF,WATER,SPECIAL,0,1,0,1\r\n", written
        assert_equal ["Checking the moves of Top"], echoed
    end

    def test_count_ability_use_counts_final_species_split_by_legendary
        %i[BLAZE SOLAR].each { |id| create_ability(id: id) }
        species(:BASE, id_number: 1, abilities: [:SOLAR], evolutions: [[:TOP, :Level, 30, false]])
        species(:TOP, id_number: 2, abilities: [:BLAZE], evolutions: [[:BASE, :Level, 30, true]])
        species(:LEGEND, id_number: 3, abilities: %i[BLAZE SOLAR], flags: %w[NoStaples Legendary])

        run_command("countabilityuse")

        assert_equal ["AbilityName,Total Count,Non-legend Count,Legend Count,Species List", "BLAZE,2,1,1,Top;Legend",
                      "SOLAR,1,0,1,Legend"], echoed
        assert_equal ["Printed out ability counts to the console."], messages
    end

    def test_signature_abilities_lists_each_ability_one_final_species_has_in_species_order
        %i[BLAZE SOLAR SHARED].each { |id| create_ability(id: id, description: "Does.") }
        species(:FIRST, id_number: 2, abilities: %i[SOLAR SHARED])
        species(:SECOND, id_number: 1, abilities: %i[BLAZE SHARED])

        assert_equal "Blaze,\"Does.\"\r\nSolar,\"Does.\"\r\n", run_command("getsignatureabilities", "signature_abilities.txt")
    end

    def test_canon_and_new_abilities_are_listed_by_name
        create_ability(id: :ZAP, description: "Old.")
        create_ability(id: :ARC, description: "Old.")
        create_ability(id: :NOVA, description: "New.", tectonic_new: true)
        create_ability(id: :BOLT, description: "New.", tectonic_new: true)
        create_ability(id: :GONE, cut: true)
        create_ability(id: :ANCIENT, primeval: true)

        assert_equal "Arc,\"Old.\"\r\nZap,\"Old.\"\r\n", run_command("listcanonabilities", "canon_abilities.txt")
        assert_equal "Bolt,\"New.\"\r\nNova,\"New.\"\r\n", run_command("listnewabilities", "new_abilities.txt")
    end

    def test_count_move_use_counts_final_species_split_by_legendary
        %i[EMBER SURF].each.with_index(1) { |id, number| create_move(id: id, id_number: number) }
        species(:SOLO, id_number: 1, moves: [[1, :EMBER]])
        species(:LEGEND, id_number: 2, moves: [[1, :EMBER], [1, :SURF]], flags: %w[NoStaples Legendary])

        run_command("countmoveuse")

        assert_equal ["MoveName,Non-legend Count,Legend Count", "EMBER,1,1", "SURF,0,1"], echoed
    end

    def test_signature_moves_lists_each_move_one_final_species_learns_in_species_order
        create_type(id: :NORMAL)
        %i[EMBER SURF SHARED].each.with_index(1) { |id, number| create_move(id: id, id_number: number, description: "Hits.") }
        species(:FIRST, id_number: 2, moves: [[1, :EMBER], [1, :SHARED]])
        species(:SECOND, id_number: 1, moves: [[1, :SURF], [1, :SHARED]])

        written = run_command("getsignaturemoves", "signature_moves.txt")

        assert_equal ["Surf,,Normal,\"Hits.\",0,Status,,,,0,-,\r\n", "Ember,,Normal,\"Hits.\",0,Status,,,,0,-,\r\n"], written.lines
    end

    # Two moves of each kind, out of order by type, category and power
    def moves_of_each_kind
        create_type(id: :FIRE, id_number: 1)
        create_type(id: :WATER, id_number: 0)
        { canon: {}, new: { tectonic_new: true }, primeval: { primeval: true }, cut: { cut: true } }.each do |kind, attributes|
            create_move(id: :"#{kind.upcase}FIRE", type: :FIRE, base_damage: 10, **attributes)
            create_move(id: :"#{kind.upcase}WATER", type: :WATER, base_damage: 90, category: 1, **attributes)
        end
    end

    def move_names(written)
        return written.lines.map { |line| line.split(",").first.chomp }
    end

    def test_move_lists_are_sorted_by_type_then_category_then_power
        moves_of_each_kind

        assert_equal %w[Canonwater Canonfire], move_names(run_command("listcanonmoves", "canon_moves.txt"))
        assert_equal %w[Newwater Newfire], move_names(run_command("listnewmoves", "new_moves.txt"))
        assert_equal %w[Primevalwater Primevalfire], move_names(run_command("listprimevalmoves", "primeval_moves.txt"))
    end

    def test_list_cut_moves_lists_the_cut_moves_by_name
        moves_of_each_kind

        assert_equal "Cutwater\r\nCutfire\r\n", run_command("listcutmoves", "cut_moves.txt")
        assert_equal ["Cut moves information written to Analysis/cut_moves.txt"], messages
    end

    def test_held_and_super_item_lists_are_sorted_by_name
        create_item(id: :ZINC, pocket: 9, description: "Held.")
        create_item(id: :APPLE, pocket: 13, description: "Held.")
        create_item(id: :POTION, pocket: 2)
        create_item(id: :OLDITEM, pocket: 9, cut: true)
        create_item(id: :ZENITH, pocket: 5, super: true, description: "Super.")
        create_item(id: :AURA, pocket: 5, super: true, description: "Super.")
        create_item(id: :HELDSUPER, pocket: 9, super: true)

        assert_equal "Apple,\"Held.\"\r\nZinc,\"Held.\"\r\n", run_command("listhelditems", "held_items.txt")
        assert_equal "Aura,\"Super.\"\r\nZenith,\"Super.\"\r\n", run_command("listsuperitems", "held_items_super.txt")
    end

    def test_count_tribes_counts_the_final_base_forms_in_each_legal_tribe
        GameData::Tribe.register({ id: :LOYAL, id_number: 1 })
        GameData::Tribe.register({ id: :CLEVER, id_number: 2 })
        GameData::Tribe.register({ id: :GONE, id_number: 3, cut: true })
        two_stage_line(base: { tribes: [:LOYAL] }, top: { tribes: %i[LOYAL CLEVER] }, form: { tribes: [:CLEVER] })

        run_command("counttribes")

        assert_equal ["Tribes count", "LOYAL,1", "CLEVER,1"], echoed
    end

    def test_earliest_levels_finds_each_moves_earliest_level_and_learners
        %i[EMBER SURF SLASH].each.with_index(1) { |id, number| create_move(id: id, id_number: number) }
        create_move(id: :ANCIENT, id_number: 4, primeval: true)
        # TOP inherits BASE's level moves
        species(:BASE, id_number: 1, moves: [[10, :EMBER], [20, :SLASH]], evolutions: [[:TOP, :Item, :FIRESTONE, false]])
        species(:TOP, id_number: 2, moves: [[0, :SURF], [12, :SLASH]], evolutions: [[:BASE, :Item, :FIRESTONE, true]])
        species(:MID, id_number: 3, moves: [[0, :SLASH]], evolutions: [[:ROOT, :Level, 5, true]])
        species(:MID_1, id_number: 4, species: :MID, form: 1, form_name: +"50% Form", moves: [[1, :SURF]])
        species(:MID_2, id_number: 6, species: :MID, form: 2, moves: [[1, :SURF]])
        species(:ROOT, id_number: 5, evolutions: [[:MID, :Level, 5, false]])

        written = run_command("earliestlevels", "move_levels.txt")

        assert_equal "Move,Level,Evolution,Learners\r\nEMBER,10,false,BASE,TOP\r\nSLASH,5,true,MID\r\nSURF,35,true,TOP\r\n", written
    end
end
