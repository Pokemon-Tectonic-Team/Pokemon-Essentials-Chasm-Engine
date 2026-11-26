require_relative "../../support/test_helper"
require_relative "../../support/graphics_folder"

class TrainerTypeTest < Minitest::Test
    # What the filename helpers read from the player: the trainer type's gender and the outfit
    FakePlayer = Struct.new(:gender, :outfit)

    ICONS = "Graphics/Pictures/Town Map/Player Icons/mapPlayer".freeze

    def teardown
        $Trainer = nil
        super
    end

    def register(id, **attributes)
        GameData::TrainerType.register({ id: id }.merge(attributes))
        return GameData::TrainerType.get(id)
    end

    # Runs the block in a game folder holding a 16x16 image at each path
    def with_images(*paths, &)
        GraphicsFolder.with(paths.to_h { |path| [path, [16, 16]] }, &)
    end

    # check_file

    def test_check_file_returns_nil_for_an_unknown_trainer_type
        with_images("Graphics/Trainers/LEADER") do
            assert_nil GameData::TrainerType.check_file(:LEADER, "Graphics/Trainers/")
        end
    end

    def test_check_file_returns_nil_when_no_image_exists
        register(:LEADER, id_number: 7)

        with_images do
            assert_nil GameData::TrainerType.check_file(:LEADER, "Graphics/Trainers/", "_1", "_back")
        end
    end

    def test_check_file_prefers_the_id_over_the_id_number
        register(:LEADER, id_number: 7)

        with_images("Graphics/Trainers/LEADER", "Graphics/Trainers/007") do
            assert_equal "Graphics/Trainers/LEADER", GameData::TrainerType.check_file(:LEADER, "Graphics/Trainers/")
        end
    end

    def test_check_file_falls_back_to_the_id_number_padded_to_three_digits
        register(:LEADER, id_number: 7)

        with_images("Graphics/Trainers/007") do
            assert_equal "Graphics/Trainers/007", GameData::TrainerType.check_file(:LEADER, "Graphics/Trainers/")
        end
    end

    def test_check_file_tries_each_name_in_order_with_an_optional_suffix
        register(:LEADER, id_number: 7)
        candidates = %w[LEADER_1_back 007_1_back _1_back LEADER_back 007_back].map { |name| "Graphics/Trainers/#{name}" }

        candidates.each_index do |index|
            with_images(*candidates[index..]) do
                assert_equal candidates[index], GameData::TrainerType.check_file(:LEADER, "Graphics/Trainers/", "_1", "_back")
            end
        end
    end

    def test_check_file_skips_the_suffix_only_name_without_an_optional_suffix
        register(:LEADER, id_number: 7)

        with_images("Graphics/Trainers/_back") do
            assert_nil GameData::TrainerType.check_file(:LEADER, "Graphics/Trainers/", "", "_back")
        end
    end

    # Filename helpers

    def test_player_map_icon_filename_uses_the_gender_icon_shared_by_every_trainer_type
        register(:POKEMONTRAINER_Feminine, id_number: 2)
        $Trainer = FakePlayer.new(1, 0)

        with_images("#{ICONS}000", "#{ICONS}001", "#{ICONS}002") do
            assert_equal "#{ICONS}001", GameData::TrainerType.player_map_icon_filename(:POKEMONTRAINER_Feminine)
        end
    end

    def test_player_map_icon_filename_prefers_an_icon_for_the_trainer_type
        register(:POKEMONTRAINER_Feminine, id_number: 2)
        $Trainer = FakePlayer.new(1, 0)

        with_images("#{ICONS}POKEMONTRAINER_Feminine001", "#{ICONS}001") do
            assert_equal "#{ICONS}POKEMONTRAINER_Feminine001", GameData::TrainerType.player_map_icon_filename(:POKEMONTRAINER_Feminine)
        end
    end

    def test_player_map_icon_filename_reads_gender_0_without_a_player
        register(:POKEMONTRAINER_Masculine, id_number: 1)

        with_images("#{ICONS}000", "#{ICONS}001") do
            assert_equal "#{ICONS}000", GameData::TrainerType.player_map_icon_filename(:POKEMONTRAINER_Masculine)
        end
    end

    def test_map_icon_filename_has_no_gender
        register(:LEADER, id_number: 7)

        with_images("#{ICONS}LEADER", "#{ICONS}000") do
            assert_equal "#{ICONS}LEADER", GameData::TrainerType.map_icon_filename(:LEADER)
        end
    end

    def test_player_front_sprite_filename_uses_the_outfit
        register(:LEADER, id_number: 7)
        $Trainer = FakePlayer.new(0, 2)

        with_images("Graphics/Trainers/LEADER_2", "Graphics/Trainers/LEADER") do
            assert_equal "Graphics/Trainers/LEADER_2", GameData::TrainerType.player_front_sprite_filename(:LEADER)
        end
    end

    def test_player_front_sprite_filename_reads_outfit_0_without_a_player
        register(:LEADER, id_number: 7)

        with_images("Graphics/Trainers/LEADER_0", "Graphics/Trainers/LEADER_2") do
            assert_equal "Graphics/Trainers/LEADER_0", GameData::TrainerType.player_front_sprite_filename(:LEADER)
        end
    end

    def test_player_back_sprite_filename_uses_the_outfit_and_back_suffix
        register(:LEADER, id_number: 7)
        $Trainer = FakePlayer.new(0, 2)

        with_images("Graphics/Trainers/LEADER_2_back", "Graphics/Trainers/LEADER_back") do
            assert_equal "Graphics/Trainers/LEADER_2_back", GameData::TrainerType.player_back_sprite_filename(:LEADER)
        end
    end

    def test_back_sprite_filename_has_the_back_suffix
        register(:LEADER, id_number: 7)

        with_images("Graphics/Trainers/LEADER", "Graphics/Trainers/LEADER_back") do
            assert_equal "Graphics/Trainers/LEADER_back", GameData::TrainerType.back_sprite_filename(:LEADER)
        end
    end

    def test_front_sprite_filenames_read_their_folders
        register(:LEADER, id_number: 7)

        with_images("Graphics/Trainers/LEADER", "Graphics/Trainers/Holograms/LEADER") do
            assert_equal "Graphics/Trainers/LEADER", GameData::TrainerType.front_sprite_filename(:LEADER)
            assert_equal "Graphics/Trainers/Holograms/LEADER", GameData::TrainerType.front_sprite_filename_hologram(:LEADER)
        end
    end

    def test_charset_filenames_with_and_without_the_folder
        register(:LEADER, id_number: 7)

        with_images("Graphics/Characters/trainer_LEADER") do
            assert_equal "Graphics/Characters/trainer_LEADER", GameData::TrainerType.charset_filename(:LEADER)
            assert_equal "trainer_LEADER", GameData::TrainerType.charset_filename_brief(:LEADER)
        end
    end

    def test_charset_filename_brief_returns_nil_without_a_charset
        register(:LEADER, id_number: 7)

        with_images do
            assert_nil GameData::TrainerType.charset_filename_brief(:LEADER)
        end
    end

    # cableClubClasses

    def test_cable_club_classes_lists_the_player_classes_first_then_cable_club_types
        register(:LEADER, cable_club: true)
        register(:HIKER)
        register(:ACE, cable_club: true)

        expected = [:POKEMONTRAINER_Androgynous, :POKEMONTRAINER_Feminine, :POKEMONTRAINER_Masculine, :LEADER, :ACE]
        assert_equal expected, GameData::TrainerType.cableClubClasses
    end

    # Record

    def test_initialize_defaults
        tr_type = GameData::TrainerType.new({ id: :LEADER })

        assert_equal :LEADER, tr_type.id
        assert_equal(-1, tr_type.id_number)
        assert_equal "Unnamed", tr_type.real_name
        assert_equal 30, tr_type.base_money
        assert_equal 30, tr_type.skill_level
        assert_equal 2, tr_type.gender
        assert_equal [], tr_type.policies
        assert_equal false, tr_type.cable_club
        assert_nil tr_type.cable_club_name
    end

    def test_skill_level_defaults_to_the_base_money
        assert_equal 80, GameData::TrainerType.new({ id: :LEADER, base_money: 80 }).skill_level
        assert_equal 50, GameData::TrainerType.new({ id: :LEADER, base_money: 80, skill_level: 50 }).skill_level
    end

    def test_name_is_the_real_name
        assert_equal "Gym Leader", GameData::TrainerType.new({ id: :LEADER, name: "Gym Leader" }).name
    end

    def test_cable_club_display_name_prefers_the_cable_club_name
        assert_equal "Leader", GameData::TrainerType.new({ id: :LEADER, name: "Leader" }).cable_club_display_name
        assert_equal "Trainer", GameData::TrainerType.new({ id: :LEADER, name: "Leader", cable_club_name: "Trainer" }).cable_club_display_name
    end

    # compile_trainer_types and write_trainer_types. The names compile passes to
    # MessageTypes.setMessages are untested: reading them back loads the game's message files.

    PBS_HEADER = "\xEF\xBB\xBF# See the documentation on the wiki to learn how to edit this file.\r\n".b.freeze

    FULL_PBS = <<~PBS.freeze
        [LEADER]
        Name = Gym Leader
        Gender = Female
        BaseMoney = 80
        SkillLevel = 50
        Policies = CAREFUL,AGGRO
        IntroBGM = Intro
        BattleBGM = Battle
        CursedBGM = Cursed
        VictoryBGM = Victory
        CableClub = true
        CableClubName = Leader
    PBS

    # Runs the block in an empty game folder with PBS/ and Data/, restoring the registered PBS
    # extensions afterwards
    def in_game_folder
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

    def compile(text, path = "PBS/trainertypes.txt")
        File.binwrite(path, text)
        Compiler.compile_trainer_types(path)
    end

    def attributes(tr_type)
        return [tr_type.real_name, tr_type.gender, tr_type.base_money, tr_type.skill_level, tr_type.policies, tr_type.intro_ME,
                tr_type.battle_BGM, tr_type.cursed_battle_BGM, tr_type.victory_ME, tr_type.cable_club, tr_type.cable_club_name]
    end

    def registered_attributes
        return GameData::TrainerType.keys.sort.to_h { |id| [id, attributes(GameData::TrainerType.get(id))] }
    end

    def register_policies
        GameData::Policy.register({ id: :CAREFUL })
        GameData::Policy.register({ id: :AGGRO })
    end

    def test_compile_reads_each_property
        register_policies

        in_game_folder do
            compile(FULL_PBS)
        end

        expected = ["Gym Leader", 1, 80, 50, [:CAREFUL, :AGGRO], "Intro", "Battle", "Cursed", "Victory", true, "Leader"]
        assert_equal expected, attributes(GameData::TrainerType.get(:LEADER))
        refute GameData::TrainerType.get(:LEADER).defined_in_extension
    end

    def test_compile_registers_every_section_including_the_last
        in_game_folder do
            compile("[LEADER]\nName = Leader\n[HIKER]\nName = Hiker\n")
        end

        assert_equal "Leader", GameData::TrainerType.get(:LEADER).real_name
        assert_equal "Hiker", GameData::TrainerType.get(:HIKER).real_name
    end

    def test_compile_replaces_the_registered_types
        register(:OLD)

        in_game_folder do
            compile("[LEADER]\n")
        end

        assert_equal [:LEADER], GameData::TrainerType.keys
    end

    def test_compile_reads_each_spelling_of_wild_as_gender_3
        in_game_folder do
            compile(%w[Wild wild W w 3].each_with_index.map { |gender, index| "[TYPE#{index}]\nGender = #{gender}\n" }.join)
        end

        genders = GameData::TrainerType.keys.sort.map { |id| GameData::TrainerType.get(id).gender }
        assert_equal [3] * 5, genders
    end

    def test_compile_ignores_unknown_properties
        in_game_folder do
            compile("[LEADER]\nName = Leader\nUnknown = 1\n")
        end

        assert_equal "Leader", GameData::TrainerType.get(:LEADER).real_name
    end

    def test_compile_refuses_an_id_used_twice
        error = in_game_folder do
            assert_raises(RuntimeError) { compile("[LEADER]\n[LEADER]\n") }
        end

        assert_match(/Trainer Type ID 'LEADER' is used twice/, error.message)
    end

    def test_compile_refuses_a_property_before_any_section
        error = in_game_folder do
            assert_raises(RuntimeError) { compile("Name = Leader\n") }
        end

        assert_match(/Expected a section at the beginning of the file/, error.message)
    end

    def test_compile_marks_the_types_from_extension_files
        in_game_folder do
            File.binwrite("PBS/trainertypes_extra.txt", "[HIKER]\n")
            Compiler.register_extension("trainertypes", "PBS/trainertypes_extra.txt")
            compile("[LEADER]\n")
        end

        refute GameData::TrainerType.get(:LEADER).defined_in_extension
        assert GameData::TrainerType.get(:HIKER).defined_in_extension
    end

    def test_compile_saves_the_types_to_the_data_file
        saved = in_game_folder do
            compile("[LEADER]\nName = Leader\n")
            Marshal.load(File.binread("Data/trainer_types.dat")) # rubocop:disable Security/MarshalLoad -- the file the compiler just wrote
        end

        assert_equal [:LEADER], saved.keys
        assert_equal "Leader", saved[:LEADER].real_name
    end

    def test_write_writes_each_property
        register_policies
        register(:LEADER, name: "Gym Leader", gender: 1, base_money: 80, skill_level: 50, policies: [:CAREFUL, :AGGRO],
                          intro_ME: "Intro", battle_BGM: "Battle", cursed_battle_BGM: "Cursed", victory_ME: "Victory",
                          cable_club: true, cable_club_name: "Leader")

        written = in_game_folder do
            Compiler.write_trainer_types
            File.binread("PBS/trainertypes.txt")
        end

        assert_equal PBS_HEADER + "#-------------------------------\r\n#{FULL_PBS.gsub("\n", "\r\n")}".b, written
    end

    def test_write_leaves_out_unset_properties_and_a_skill_level_equal_to_the_base_money
        register(:LEADER, name: "Leader", gender: 0, base_money: 40)

        written = in_game_folder do
            Compiler.write_trainer_types
            File.binread("PBS/trainertypes.txt")
        end

        assert_equal "#{PBS_HEADER}#-------------------------------\r\n[LEADER]\r\nName = Leader\r\nGender = Male\r\nBaseMoney = 40\r\n", written
    end

    def test_write_names_gender_3_wild
        register(:WILD, gender: 3)

        written = in_game_folder do
            Compiler.write_trainer_types
            File.binread("PBS/trainertypes.txt")
        end

        assert_includes written, "Gender = Wild\r\n"
    end

    def test_write_leaves_out_the_types_from_extension_files
        register(:LEADER)
        register(:HIKER, defined_in_extension: true)

        written = in_game_folder do
            Compiler.write_trainer_types
            File.binread("PBS/trainertypes.txt")
        end

        assert_includes written, "[LEADER]"
        refute_includes written, "[HIKER]"
    end

    def test_written_types_compile_back_unchanged
        register_policies
        register(:LEADER, name: "Gym Leader", gender: 1, base_money: 80, skill_level: 50, policies: [:CAREFUL, :AGGRO],
                          intro_ME: "Intro", battle_BGM: "Battle", cursed_battle_BGM: "Cursed", victory_ME: "Victory",
                          cable_club: true, cable_club_name: "Leader")
        register(:WILD, name: "Wild", gender: 3, base_money: 0)
        before = registered_attributes

        in_game_folder do
            Compiler.write_trainer_types
            Compiler.compile_trainer_types
        end

        assert_equal before, registered_attributes
    end

    def test_gender_predicates
        predicates = (0..3).map do |gender|
            tr_type = GameData::TrainerType.new({ id: :LEADER, gender: gender })
            [tr_type.male?, tr_type.female?, tr_type.wild?]
        end

        assert_equal [[true, false, false], [false, true, false], [false, false, false], [false, false, true]], predicates
    end
end
