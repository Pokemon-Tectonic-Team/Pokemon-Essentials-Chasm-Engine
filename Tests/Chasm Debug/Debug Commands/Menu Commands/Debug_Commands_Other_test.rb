require_relative "../../../support/test_helper"

class DebugCommandsOtherTest < Minitest::Test
    # The helpers report through echoln, which resolves to this method when a test calls them
    def echoln(text)
        echoed.push(text.to_s)
    end

    def echoed
        return @echoed ||= []
    end

    # getRenamedMovesBatch

    def renames_from(files, *version)
        Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
                FileUtils.mkdir_p("PBS")
                files.each { |name, text| File.binwrite("PBS/#{name}", text) }
                return getRenamedMovesBatch(*version)
            end
        end
    end

    def test_renames_are_read_from_move_renames_skipping_comments_and_blank_lines
        text = "\xEF\xBB\xBF# Old,New,Display\r\nEMBER,CINDER,Cinder\r\n\r\n  TACKLE,SLAM,Slam  # tidied\r\n"

        renames = renames_from({ "move_renames.txt" => text })

        assert_equal({ "EMBER" => %w[CINDER Cinder], "TACKLE" => %w[SLAM Slam] }, renames)
    end

    def test_a_version_reads_that_version_file
        files = { "move_renames.txt" => "EMBER,CINDER,Cinder\n", "move_renames_2.txt" => "SURF,WAVE,Wave\n" }

        assert_equal({ "SURF" => %w[WAVE Wave] }, renames_from(files, 2))
    end

    # renameMoves

    def test_rename_moves_replaces_the_move_record_keeping_its_number_and_data
        create_move(id: :EMBER, id_number: 7, base_damage: 40, category: 1, total_pp: 25)

        renameMoves({ "EMBER" => %w[CINDER Cinder] })

        refute GameData::Move.exists?(:EMBER)
        cinder = GameData::Move.get(:CINDER)
        assert_equal ["Cinder", 7, 40, 25], [cinder.real_name, cinder.id_number, cinder.base_damage, cinder.total_pp]
        assert_same cinder, GameData::Move.get(7)
    end

    def test_rename_moves_renames_the_move_in_every_species_move_list
        %i[EMBER TACKLE].each { |id| create_move(id: id) }
        create_species(id: :BASE, moves: [[1, :TACKLE], [5, :EMBER]], tutor_moves: [:EMBER], line_moves: %i[EMBER TACKLE])
        GameData::Species.get(:BASE).earliest_available = 12

        renameMoves({ "EMBER" => %w[CINDER Cinder] })

        renamed = GameData::Species.get(:BASE)
        assert_equal [[[1, :TACKLE], [5, :CINDER]], [:CINDER], %i[CINDER TACKLE]], [renamed.moves, renamed.tutor_moves, renamed.line_moves]
        assert_equal 12, renamed.earliest_available
        assert_equal ["Modifying Base"], echoed
    end

    def test_rename_moves_leaves_species_without_the_move_alone
        %i[EMBER TACKLE].each { |id| create_move(id: id) }
        species = create_species(id: :BASE, moves: [[1, :TACKLE]])

        renameMoves({ "EMBER" => %w[CINDER Cinder] })

        assert_same species, GameData::Species.get(:BASE)
        assert_empty echoed
    end

    # A trainer whose party is a sketcher, which registering the trainer checks no moves of
    def register_trainer
        create_move(id: :SKETCH, function_code: "ReplaceMoveWithTargetLastMoveUsed")
        without_form_moves(:SKETCHER)
        create_species(id: :SKETCHER, moves: [[1, :SKETCH]], flags: ["NoStaples"])
        return GameData::Trainer.register({
            id: [:LEADER, "Ann", 1], id_number: 5, trainer_type: :LEADER, name: "Ann", version: 1,
            name_for_hashing: "Ann2", items: [:POTION], lose_text: "Well fought.", flags: ["Rematch"],
            defined_in_extension: true,
            pokemon: [{ species: :SKETCHER, level: 10, moves: %i[EMBER TACKLE] }, { species: :SKETCHER, level: 12 }]
        })
    end

    def test_rename_moves_renames_trainer_moves_keeping_the_trainer_findable
        %i[EMBER TACKLE].each { |id| create_move(id: id) }
        old_trainer = register_trainer

        renameMoves({ "EMBER" => %w[CINDER Cinder] })

        trainer = GameData::Trainer.get(:LEADER, "Ann", 1)
        party_moves = trainer.pokemon.map { |member| member[:moves] }
        assert_equal [%i[CINDER TACKLE], nil], party_moves
        assert_same trainer, GameData::Trainer::DATA[5]
        assert_equal %i[EMBER TACKLE], old_trainer.pokemon[0][:moves] # The old record is left as it was
    end

    def test_rename_moves_keeps_the_rest_of_the_trainer
        create_move(id: :EMBER)
        register_trainer

        renameMoves({ "EMBER" => %w[CINDER Cinder] })

        trainer = GameData::Trainer.get(:LEADER, "Ann", 1)
        kept = [trainer.real_name, trainer.name_for_hashing, trainer.items, trainer.real_lose_text, trainer.flags, trainer.defined_in_extension]
        assert_equal ["Ann", "Ann2", [:POTION], "Well fought.", ["Rematch"], true], kept
    end

    def test_rename_moves_renames_avatar_moves_keeping_the_rest_of_the_avatar
        %i[EMBER TACKLE].each { |id| create_move(id: id) }
        create_ability(id: :BLAZE)
        GameData::Avatar.register({
            id: [:BASE, 2], id_number: 3, species: :BASE, version: 2, moves1: %i[EMBER TACKLE], moves2: [:EMBER],
            abilities: [:BLAZE], items: [:POTION], aggression: 1, defined_in_extension: true, pit_avatar: true
        })

        renameMoves({ "EMBER" => %w[CINDER Cinder] })

        avatar = GameData::Avatar.get(:BASE, 2)
        assert_equal [%i[CINDER TACKLE], [:CINDER]], [avatar.moves1, avatar.moves2]
        assert_equal [:BASE, 2, [:POTION], [:BLAZE], true], [avatar.species, avatar.version, avatar.items, avatar.abilities, avatar.defined_in_extension]
        assert_equal [avatar], GameData::Avatar.getPitAvatars
    end

    def test_rename_moves_drops_an_unknown_move
        renames = { "NOTAMOVE" => %w[NEW New] }

        renameMoves(renames)

        assert_empty renames
        refute GameData::Move.exists?(:NEW)
        assert_equal ["No move with the internal name NOTAMOVE was found."], echoed
    end

    def test_rename_moves_warns_of_an_invalid_new_name_but_still_renames
        create_move(id: :EMBER)

        renameMoves({ "EMBER" => %w[1CINDER Cinder] })

        assert GameData::Move.exists?(:"1CINDER")
        assert_includes echoed.first, "New internal name 1CINDER must contain only letters"
    end

    # setSaveVersion

    # The pit avatar list is a class variable, which the per-test reset doesn't restore
    def teardown
        FileUtils.rm_f(SaveData::FILE_PATH)
        GameData::Avatar.class_variable_get(:@@pit_avatars).clear
    end

    def test_set_save_version_rewrites_the_saved_game_version
        File.binwrite(SaveData::FILE_PATH, Marshal.dump({ game_version: "3.0.0", player: "kept" }))

        setSaveVersion("2.5.0")

        assert_equal({ game_version: "2.5.0", player: "kept" }, SaveData.get_data_from_file(SaveData::FILE_PATH))
    end
end
