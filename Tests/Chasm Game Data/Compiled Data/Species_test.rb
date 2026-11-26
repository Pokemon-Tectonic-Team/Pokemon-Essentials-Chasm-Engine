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
