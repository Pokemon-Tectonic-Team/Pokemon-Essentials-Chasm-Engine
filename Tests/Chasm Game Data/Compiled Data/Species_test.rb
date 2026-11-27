require "stringio"
require_relative "../../support/test_helper"

class SpeciesTest < Minitest::Test
    # Registers ids as one evolution line, each evolving into the next, with the prevolution
    # entries the compiler adds. Returns the registered records in line order.
    def register_line(*ids, **attributes)
        ids.each_with_index.map do |id, index|
            evolutions = []
            evolutions.push([ids[index - 1], :Level, 10 * index, true]) if index > 0
            evolutions.push([ids[index + 1], :Level, 10 * (index + 1), false]) if ids[index + 1]
            create_species(id: id, evolutions: evolutions, **attributes)
        end
    end

    def catch_rates(*ids, **attributes)
        return register_line(*ids, **attributes).map(&:catch_rate)
    end

    # Prevolution helpers

    def test_get_prevolutions_lists_only_the_prevolution_entries
        _, mid, = register_line(:BASE, :MID, :TOP)

        assert_equal [[:BASE, :Level, 10]], mid.get_prevolutions
    end

    def test_get_prevolutions_leaves_out_none_methods_unless_asked
        species = create_species(id: :MID, evolutions: [[:BASE, :None, nil, true]])

        assert_empty species.get_prevolutions
        assert_equal [[:BASE, :None, nil]], species.get_prevolutions(false)
        refute species.has_previous_species?
        assert_equal :MID, species.get_previous_species
    end

    def test_previous_species_of_an_unevolved_species_is_itself
        base, = register_line(:BASE, :MID)

        refute base.has_previous_species?
        assert_equal :BASE, base.get_previous_species
        assert_nil base.get_previous_species_data
    end

    def test_previous_species_of_an_evolved_species
        _, mid, = register_line(:BASE, :MID, :TOP)

        assert mid.has_previous_species?
        assert_equal :BASE, mid.get_previous_species
        assert_equal GameData::Species.get(:BASE), mid.get_previous_species_data
    end

    def test_prevolution_chain_lists_the_prevolutions_nearest_first
        base, mid, top = register_line(:BASE, :MID, :TOP)

        assert_empty base.prevolution_chain
        assert_equal [base], mid.prevolution_chain
        assert_equal [mid, base], top.prevolution_chain
    end

    def test_prevolution_chain_keeps_to_the_form_where_the_prevolution_has_it
        base, mid = register_line(:BASE, :MID)
        base_form = create_species(id: :BASE_1, species: :BASE, form: 1)
        mid_form = create_species(id: :MID_1, species: :MID, form: 1, evolutions: mid.evolutions)
        mid_form_2 = create_species(id: :MID_2, species: :MID, form: 2, evolutions: mid.evolutions)

        assert_equal [base_form], mid_form.prevolution_chain
        assert_equal [base], mid_form_2.prevolution_chain # BASE has no form 2
    end

    def test_get_line_start_is_the_first_species_of_the_line
        base, mid, top = register_line(:BASE, :MID, :TOP)

        assert_equal [base, base, base], [base, mid, top].map(&:get_line_start)
    end

    def test_evo_stage_counts_the_prevolutions
        assert_equal [0, 1, 2, 3], register_line(:A, :B, :C, :D).map(&:evo_stage)
    end

    def test_max_stage_is_the_stage_of_the_line_final_evolution
        assert_equal [0], register_line(:SOLO).map(&:max_stage)
        assert_equal [2, 2, 2], register_line(:BASE, :MID, :TOP).map(&:max_stage)
    end

    # BASE evolves into SHORT (final) or into MID, which evolves into TOP
    def register_branched_line
        create_species(id: :BASE, id_number: 1, evolutions: [[:SHORT, :Level, 10, false], [:MID, :Level, 10, false]])
        create_species(id: :SHORT, id_number: 2, evolutions: [[:BASE, :Level, 10, true]])
        create_species(id: :MID, id_number: 3, evolutions: [[:BASE, :Level, 10, true], [:TOP, :Level, 20, false]])
        create_species(id: :TOP, id_number: 4, evolutions: [[:MID, :Level, 20, true]])
        return %i[BASE SHORT MID TOP].map { |id| GameData::Species.get(id) }
    end

    def test_max_stage_of_a_branched_line_takes_the_longest_branch_unless_asked_for_the_shortest
        base, = register_branched_line

        assert_equal 2, base.max_stage
        assert_equal 1, base.max_stage(false)
    end

    def test_max_stage_reads_only_the_branches_below_the_species
        _, short, mid, top = register_branched_line

        assert_equal [1, 2, 2], [short, mid, top].map(&:max_stage)
    end

    def test_get_species_form_falls_back_to_the_base_form_and_is_nil_for_an_unknown_species
        base = create_species(id: :BASE)
        form = create_species(id: :BASE_1, species: :BASE, form: 1)

        assert_equal form, GameData::Species.get_species_form(:BASE, 1)
        assert_equal base, GameData::Species.get_species_form(:BASE, 2)
        assert_nil GameData::Species.get_species_form(:NOPE, 0)
    end

    # Family helpers

    # BASE evolves into TOP by the given method and parameter
    def register_pair(method, parameter)
        create_species(id: :BASE, evolutions: [[:TOP, method, parameter, false]])
        create_species(id: :TOP, evolutions: [[:BASE, method, parameter, true]])
        return %i[BASE TOP].map { |id| GameData::Species.get(id) }
    end

    def test_baby_species_is_the_line_start
        solo = create_species(id: :SOLO)
        _, _, top = register_line(:BASE, :MID, :TOP)

        assert_equal :SOLO, solo.get_baby_species
        assert_equal :BASE, top.get_baby_species
    end

    def test_related_species_are_the_whole_line
        solo = create_species(id: :SOLO)
        _, _, top = register_line(:BASE, :MID, :TOP)

        assert_equal [:SOLO], solo.get_related_species
        assert_equal %i[BASE MID TOP], top.get_related_species
    end

    def test_family_evolutions_have_method_matches_the_method_and_any_parameter_given
        _, top = register_pair(:Level, 16)

        assert top.family_evolutions_have_method?(:Level)
        assert top.family_evolutions_have_method?(%i[Item Level])
        assert top.family_evolutions_have_method?(:Level, 16)
        refute top.family_evolutions_have_method?(:Level, 20)
        refute top.family_evolutions_have_method?(:Item)
        refute top.family_evolutions_have_method?(%i[Item Trade])
        refute create_species(id: :SOLO).family_evolutions_have_method?(:Level)
    end

    def test_family_item_evolutions_use_item_matches_any_item_or_the_one_given
        _, top = register_pair(:Item, :FIRESTONE)

        assert top.family_item_evolutions_use_item?
        assert top.family_item_evolutions_use_item?(:FIRESTONE)
        refute top.family_item_evolutions_use_item?(:WATERSTONE)
    end

    def test_family_item_evolutions_use_item_is_false_without_an_item_evolution
        _, top = register_pair(:Level, 16)

        refute top.family_item_evolutions_use_item?
        refute create_species(id: :SOLO).family_item_evolutions_use_item?
    end

    def test_minimum_level_of_an_unevolved_species_is_1
        assert_equal 1, create_species(id: :SOLO).minimum_level
        assert_equal 1, register_line(:BASE, :TOP).first.minimum_level
    end

    def test_minimum_level_of_a_level_evolution_is_its_level
        assert_equal 16, register_pair(:Level, 16).last.minimum_level
    end

    # HasMove needs a level up, so the evolution is at level 2 at the earliest
    def test_minimum_level_of_an_any_level_up_evolution_is_one_above_its_minimum
        assert_equal 2, register_pair(:HasMove, :TACKLE).last.minimum_level
    end

    def test_minimum_level_skips_an_evolution_with_no_level_up
        assert_equal 1, register_pair(:Trade, nil).last.minimum_level
    end

    # Catch rates

    def test_default_catch_rates_by_line_length_and_stage
        assert_equal [95], catch_rates(:SOLO)
        assert_equal [145, 60], catch_rates(:PAIR1, :PAIR2)
        assert_equal [195, 95, 35], catch_rates(:TRIO1, :TRIO2, :TRIO3)
    end

    def test_a_four_stage_line_reads_the_three_stage_rates
        assert_equal [195, 95, 35, 25], catch_rates(:A, :B, :C, :D)
    end

    def test_a_branched_line_rates_each_species_by_the_branches_below_it
        assert_equal [195, 60, 95, 35], register_branched_line.map(&:catch_rate)
    end

    def test_legendary_catch_rates
        flags = ["Legendary"]

        assert_equal [5], catch_rates(:SOLO, flags: flags)
        assert_equal [15, 5], catch_rates(:PAIR1, :PAIR2, flags: flags)
        assert_equal [25, 15, 5], catch_rates(:TRIO1, :TRIO2, :TRIO3, flags: flags)
    end

    def test_ultra_beast_catch_rates
        flags = ["UltraBeast"]

        assert_equal [35], catch_rates(:SOLO, flags: flags)
        assert_equal [60, 35], catch_rates(:PAIR1, :PAIR2, flags: flags)
    end

    def test_ultra_beast_rates_win_over_legendary_rates
        assert_equal [35], catch_rates(:SOLO, flags: %w[Legendary UltraBeast])
    end

    # A line longer than its table's longest row reads that row, whose last stage then has no rate
    def test_a_stage_past_the_rate_table_falls_back_to_255
        assert_equal [25, 15, 5, 255], catch_rates(:A, :B, :C, :D, flags: ["Legendary"])
        assert_equal [60, 35, 255], catch_rates(:A1, :B1, :C1, flags: ["UltraBeast"])
    end

    def test_the_override_wins_over_the_default
        species = create_species(id: :SOLO, catch_rate: 3)

        assert_equal 3, species.catch_rate_override
        assert_equal 3, species.catch_rate
    end

    def test_no_override_without_a_catch_rate
        assert_nil create_species(id: :SOLO).catch_rate_override
    end

    # Writing PBS files

    # The writers total the base stats, and only Speed is left unset when none are given
    def stats
        return { HP: 50, ATTACK: 50, DEFENSE: 50, SPECIAL_ATTACK: 50, SPECIAL_DEFENSE: 50, SPEED: 50 }
    end

    def written_species(species)
        io = StringIO.new
        Compiler.write_species(io, species)
        return io.string
    end

    def written_form(form)
        io = StringIO.new
        Compiler.write_species_form(io, form)
        return io.string
    end

    def test_write_species_writes_rareness_only_for_an_override
        assert_includes written_species(create_species(id: :RARE, base_stats: stats, catch_rate: 3)), "Rareness = 3\r\n"
        refute_includes written_species(create_species(id: :PLAIN, base_stats: stats)), "Rareness"
    end

    def test_write_species_writes_the_lists_and_evolutions
        %i[TACKLE EMBER SURF].each { |id| create_move(id: id) }
        create_ability(id: :BLAZE)
        create_item(id: :GEM)
        create_species(id: :TOP, base_stats: stats)
        species = create_species(
            id: :BASE, base_stats: stats, abilities: [:BLAZE], moves: [[1, :TACKLE]], form_move: :SURF,
            tutor_moves: [:EMBER], line_moves: [:SURF], tribes: [:LOYAL], sticky_items: [:GEM],
            evolutions: [[:TOP, :Level, 16, false]]
        )

        lines = written_species(species).split("\r\n")

        expected = [
            "Abilities = BLAZE", "Moves = 1,TACKLE", "FormMove = SURF", "TutorMoves = EMBER", "LineMoves = SURF",
            "Tribes = LOYAL", "StickyItems = GEM", "Evolutions = TOP,Level,16"
        ]
        expected.each { |line| assert_includes lines, line }
    end

    def test_write_species_joins_evolutions_and_skips_the_prevolution
        create_item(id: :FIRESTONE)
        create_species(id: :BASE, base_stats: stats)
        %i[LEFT RIGHT].each { |id| create_species(id: id, base_stats: stats) }
        species = create_species(
            id: :MID, base_stats: stats,
            evolutions: [[:BASE, :Level, 10, true], [:LEFT, :Level, 30, false], [:RIGHT, :Item, :FIRESTONE, false]]
        )

        assert_includes written_species(species), "Evolutions = LEFT,Level,30,RIGHT,Item,FIRESTONE\r\n"
    end

    def test_write_species_writes_no_evolutions_line_for_a_final_evolution
        create_species(id: :BASE, base_stats: stats)
        top = create_species(id: :TOP, base_stats: stats, evolutions: [[:BASE, :Level, 10, true]])

        refute_includes written_species(top), "Evolutions"
    end

    def test_write_species_form_writes_what_differs_from_the_base_species
        create_move(id: :TACKLE)
        create_move(id: :EMBER)
        %i[BLAZE TORRENT].each { |id| create_ability(id: id) }
        create_species(id: :TOP, base_stats: stats)
        create_species(id: :BASE, base_stats: stats, abilities: [:BLAZE], moves: [[1, :TACKLE]])
        form = create_species(
            id: :BASE_1, species: :BASE, form: 1, base_stats: stats, abilities: [:TORRENT], moves: [[1, :EMBER]],
            evolutions: [[:TOP, :Level, 20, false]]
        )

        lines = written_form(form).split("\r\n")

        ["Abilities = TORRENT", "Moves = 1,EMBER", "Evolutions = TOP,Level,20"].each { |line| assert_includes lines, line }
    end

    def test_write_species_form_leaves_out_what_matches_the_base_species
        create_move(id: :TACKLE)
        create_ability(id: :BLAZE)
        create_species(id: :BASE, base_stats: stats, abilities: [:BLAZE], moves: [[1, :TACKLE]])
        form = create_species(id: :BASE_1, species: :BASE, form: 1, base_stats: stats, abilities: [:BLAZE], moves: [[1, :TACKLE]])

        written = written_form(form)

        %w[Abilities Moves Evolutions].each { |key| refute_includes written, key }
    end

    def test_write_species_server_lists_every_form_ability_and_move
        without_form_moves(:BASE)
        %i[TACKLE EMBER].each { |id| create_move(id: id) }
        %i[BLAZE TORRENT].each { |id| create_ability(id: id) }
        base = create_species(id: :BASE, base_stats: stats, abilities: [:BLAZE], moves: [[1, :TACKLE]], flags: ["NoStaples"])
        form = create_species(
            id: :BASE_3, species: :BASE, form: 3, base_stats: stats, abilities: %i[BLAZE TORRENT],
            moves: [[1, :EMBER]], flags: ["NoStaples"]
        )
        io = StringIO.new

        Compiler.write_species_server(io, base, [base, form])

        assert_equal "[BASE]\r\nforms = 0,1,2,3\r\ngender_ratio = #{base.gender_ratio}\r\nabilities = BLAZE,TORRENT\r\n" \
                     "moves = TACKLE,EMBER\r\n\r\n", io.string
    end

    def test_write_species_server_leaves_out_abilities_when_there_are_none
        without_form_moves(:BASE)
        species = create_species(id: :BASE, base_stats: stats, flags: ["NoStaples"])
        io = StringIO.new

        Compiler.write_species_server(io, species, [species])

        refute_includes io.string, "abilities"
    end

    def test_write_pokemon_writes_base_species_and_the_server_list_without_banned_or_extension_species
        without_form_moves(:BASE, :BANNED, :EXTRA)
        create_species(id: :BASE, id_number: 1, base_stats: stats, flags: ["NoStaples"])
        create_species(id: :BASE_1, id_number: 2, species: :BASE, form: 1, base_stats: stats, flags: ["NoStaples"])
        create_species(id: :BANNED, id_number: 3, base_stats: stats, flags: ["NoStaples"])
        create_species(id: :EXTRA, id_number: 4, base_stats: stats, flags: ["NoStaples"], defined_in_extension: true)

        pokemon, server = in_game_folder do
            File.write("PBS/pokemon_server_banlist.txt", "BANNED\n")
            Compiler.write_pokemon
            [File.binread("PBS/pokemon.txt"), File.binread("PBS/pokemon_server.txt")]
        end

        assert_equal %w[[BASE] [BANNED]], pokemon.scan(/^\[\w+\]/)
        assert_equal ["[BASE]"], server.scan(/^\[\w+\]/)
        assert_includes server, "forms = 0,1\r\n"
    end

    def test_write_species_form_writes_rareness_only_for_an_override
        create_species(id: :BASE, base_stats: stats, catch_rate: 3)
        rare_form = create_species(id: :BASE_1, species: :BASE, form: 1, base_stats: stats, catch_rate: 7)
        plain_form = create_species(id: :BASE_2, species: :BASE, form: 2, base_stats: stats)

        assert_includes written_form(rare_form), "Rareness = 7\r\n"
        refute_includes written_form(plain_form), "Rareness" # Even where the base species has one
    end

    # registration_hash

    # A value other than the default for every key initialize reads
    def full_species_hash
        return {
            id: :BASE_1, id_number: 12, species: :BASE, form: 1, name: "Base", form_name: "Alt", category: "Kind",
            pokedex_entry: "Entry", pokedex_form: 2, type1: :FIRE, type2: :WATER, base_stats: stats, stat_rounding: 1,
            base_exp: 64, growth_rate: :Fast, gender_ratio: :AlwaysMale, catch_rate: 3, happiness: 10,
            moves: [[1, :TACKLE]], form_move: :SURF, tutor_moves: [:EMBER], line_moves: [:SURF], abilities: [:BLAZE],
            hidden_abilities: [:BLAZE], wild_item_common: :BERRY, wild_item_uncommon: :GEM, wild_item_rare: :ORB,
            hatch_steps: 5, evolutions: [[:TOP, :Level, 30, false]], height: 7, weight: 9, generation: 3,
            mega_stone: :ORB, mega_move: :SURF, unmega_form: 1, mega_message: 1, notes: "Note", tribes: [:LOYAL],
            defined_in_extension: true, flags: ["Legendary"], formalizer: [1], sticky_items: [:GEM]
        }
    end

    def register_full_species
        %i[TACKLE EMBER SURF].each { |id| create_move(id: id) }
        %i[BERRY GEM ORB].each { |id| create_item(id: id) }
        create_ability(id: :BLAZE)
        return GameData::Species.register(full_species_hash)
    end

    def test_registration_hash_gives_back_what_the_species_was_registered_from
        assert_equal full_species_hash, register_full_species.registration_hash
    end

    def test_registration_hash_copies_the_arrays_and_hashes
        species = register_full_species
        hash = species.registration_hash

        hash[:moves].each { |entry| entry[0] = 99 }
        hash[:evolutions].each { |evolution| evolution[2] = 99 }
        hash.each_value { |value| value.clear if value.is_a?(Array) || value.is_a?(Hash) }

        assert_equal full_species_hash, species.registration_hash
    end

    # compile_pokemon_forms

    # Runs the block in an empty game folder with PBS/ and Data/, restoring the registered PBS
    # extensions afterwards
    def in_game_folder(&)
        extensions = Compiler.class_variable_get(:@@pbs_extentions)
        saved = extensions.transform_values(&:dup)
        Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
                FileUtils.mkdir_p(%w[PBS Data])
                yield dir
            end
        end
    ensure
        extensions.replace(saved)
    end

    def compile_forms(text)
        in_game_folder do
            File.binwrite("PBS/pokemonforms.txt", text)
            Compiler.compile_pokemon_forms
        end
    end

    def compile_pokemon(text)
        in_game_folder do
            File.binwrite("PBS/pokemon.txt", text)
            Compiler.compile_pokemon
        end
    end

    # compile_pokemon

    def test_compile_pokemon_sorts_moves_by_level_keeping_file_order_within_a_level
        %i[TACKLE EMBER SURF].each { |id| create_move(id: id) }

        compile_pokemon("[BASE]\nName = Base\nMoves = 5,SURF,1,TACKLE,1,EMBER\n")

        assert_equal [[1, :TACKLE], [1, :EMBER], [5, :SURF]], GameData::Species.get(:BASE).moves
    end

    def test_compile_pokemon_links_evolutions_both_ways
        compile_pokemon("[BASE]\nName = Base\nEvolutions = TOP,Level,16\n[TOP]\nName = Top\n")

        assert_equal [[:TOP, :Level, 16, false]], GameData::Species.get(:BASE).evolutions
        assert_equal [[:BASE, :Level, 16, true]], GameData::Species.get(:TOP).evolutions
    end

    # No species carries a Rareness, so the formula sets every catch rate
    def test_compiled_species_without_rareness_get_the_default_catch_rates
        compile_pokemon("[BASE]\nName = Base\nEvolutions = TOP,Level,16\n[TOP]\nName = Top\n[SOLO]\nName = Solo\n")

        rates = %i[BASE TOP SOLO].map { |id| GameData::Species.get(id).catch_rate }
        assert_equal [145, 60, 95], rates
    end

    def test_compile_pokemon_refuses_a_species_defined_twice
        error = assert_raises(RuntimeError) { compile_pokemon("[BASE]\nName = Base\n[BASE]\nName = Again\n") }

        assert_includes error.message, "Species ID 'BASE' is used twice."
    end

    # compile_pokemon_forms, further

    def test_a_compiled_form_reads_its_own_moves_and_evolutions
        %i[TACKLE EMBER].each { |id| create_move(id: id) }
        create_species(id: :BASE, id_number: 1, moves: [[1, :TACKLE]])
        create_species(id: :TOP, id_number: 2)

        compile_forms("[BASE,1]\nMoves = 3,EMBER,1,TACKLE\nEvolutions = TOP,Level,20\n")

        form = GameData::Species.get(:BASE_1)
        assert_equal [[1, :TACKLE], [3, :EMBER]], form.moves
        assert_equal [[:TOP, :Level, 20, false]], form.evolutions
    end

    def test_a_compiled_form_reads_an_item_evolution
        create_item(id: :FIRESTONE)
        create_species(id: :BASE, id_number: 1)
        create_species(id: :TOP, id_number: 2)

        compile_forms("[BASE,1]\nEvolutions = TOP,Item,FIRESTONE\n")

        assert_equal [[:TOP, :Item, :FIRESTONE, false]], GameData::Species.get(:BASE_1).evolutions
    end

    def test_a_compiled_form_refuses_a_form_defined_twice
        create_species(id: :BASE, id_number: 1)

        error = assert_raises(RuntimeError) { compile_forms("[BASE,1]\nFormName = A\n[BASE,1]\nFormName = B\n") }

        assert_includes error.message, "defined twice"
    end

    # compile_species_earliest_levels

    def register_encounter(map, min_level, normal_level, species)
        GameData::Encounter.register({
            id: :"#{map}_0", map: map, version: 0, min_available_levels: { Land: min_level },
            normal_available_levels: { Land: normal_level }, types: { Land: [[50, species, 1, 1]] }
        })
    end

    # BASE evolves into MID at level 16, which evolves into TOP with a Fire Stone, available from 35
    def earliest_levels
        create_species(id: :BASE, evolutions: [[:MID, :Level, 16, false]])
        create_species(id: :MID, evolutions: [[:BASE, :Level, 16, true], [:TOP, :Item, :FIRESTONE, false]])
        create_species(id: :TOP, evolutions: [[:MID, :Item, :FIRESTONE, true]])
        in_game_folder { Compiler.compile_species_earliest_levels }
        return %i[BASE MID TOP].map do |id|
            species = GameData::Species.get(id)
            [species.earliest_available, species.earliest_available_normal]
        end
    end

    def test_earliest_levels_follow_the_line_from_its_encounter
        register_encounter(1, 5, 10, :BASE)

        assert_equal [[5, 10], [16, 16], [35, 35]], earliest_levels
    end

    def test_earliest_levels_take_the_lowest_level_of_each_kind_across_encounters
        register_encounter(1, 5, 20, :BASE)
        register_encounter(2, 8, 12, :BASE)
        register_encounter(3, 9, 30, :BASE)

        assert_equal [5, 12], earliest_levels.first
    end

    def test_an_evolution_found_in_the_wild_keeps_its_lower_encounter_level
        register_encounter(1, 5, 10, :BASE)
        register_encounter(2, 40, 40, :TOP)
        register_encounter(3, 12, 30, :MID)

        assert_equal [[5, 10], [12, 16], [35, 35]], earliest_levels
    end

    def test_an_evolution_by_a_method_without_a_level_is_as_early_as_its_prevolution
        register_encounter(1, 5, 10, :BASE)
        create_species(id: :BASE, evolutions: [[:TOP, :Happiness, nil, false]])
        create_species(id: :TOP, evolutions: [[:BASE, :Happiness, nil, true]])

        in_game_folder { Compiler.compile_species_earliest_levels }

        top = GameData::Species.get(:TOP)
        assert_equal [5, 10], [top.earliest_available, top.earliest_available_normal]
    end

    def test_earliest_level_for_an_item_not_in_the_cap_table_is_100
        assert_equal 35, Compiler.getEarliestLevelForItem(:FIRESTONE)
        assert_equal 100, Compiler.getEarliestLevelForItem(:NOTANITEM)
    end

    def test_a_compiled_form_does_not_inherit_the_base_species_override
        create_species(id: :BASE, id_number: 1, catch_rate: 3)

        compile_forms("[BASE,1]\nFormName = Alt\n")

        form = GameData::Species.get(:BASE_1)
        assert_nil form.catch_rate_override
        assert_equal 95, form.catch_rate
    end

    def test_a_compiled_form_reads_its_own_rareness
        create_species(id: :BASE, id_number: 1)

        compile_forms("[BASE,1]\nRareness = 7\n")

        assert_equal 7, GameData::Species.get(:BASE_1).catch_rate
    end
end
