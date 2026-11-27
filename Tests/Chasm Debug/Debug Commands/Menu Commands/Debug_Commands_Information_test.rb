require_relative "../../../support/test_helper"

class DebugCommandsInformationTest < Minitest::Test
    # The command runs with the test as self, so its pbMessage and echoln calls resolve to the
    # test's own
    def echoln(text)
        echoed.push(text.to_s)
    end

    def echoed
        return @echoed ||= []
    end

    def pbMessage(text, *)
        messages.push(text)
    end

    def messages
        return @messages ||= []
    end

    # consolidateeggmoves, run in a game folder holding PBS/, with the server banlist writing the
    # species PBS reads, and Data/
    def consolidate
        Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
                FileUtils.mkdir_p(%w[PBS Data])
                File.binwrite("PBS/pokemon_server_banlist.txt", "")
                instance_exec(&DebugMenuCommands.getFunction("consolidateeggmoves", "effect"))
                return File.binread("PBS/pokemon.txt")
            end
        end
    end

    # Writing the species PBS reads every base stat
    BASE_STATS = { HP: 50, ATTACK: 50, DEFENSE: 50, SPECIAL_ATTACK: 50, SPECIAL_DEFENSE: 50, SPEED: 50 }.freeze

    def species(id, **attributes)
        without_form_moves(id)
        return create_species(id: id, flags: ["NoStaples"], base_stats: BASE_STATS.dup, **attributes)
    end

    def test_consolidate_moves_a_tutor_move_the_whole_line_shares_into_the_first_stages_line_moves
        %i[EMBER SURF SLASH].each { |id| create_move(id: id) }
        base = species(:BASE, id_number: 1, tutor_moves: %i[EMBER SURF], line_moves: [:SLASH], evolutions: [[:MID, :Level, 20, false]])
        mid = species(:MID, id_number: 2, tutor_moves: %i[SURF EMBER], evolutions: [[:BASE, :Level, 20, true], [:TOP, :Level, 40, false]])
        top = species(:TOP, id_number: 3, tutor_moves: [:EMBER], evolutions: [[:MID, :Level, 40, true]])
        solo = species(:SOLO, id_number: 4, tutor_moves: [:SURF])

        written = consolidate

        assert_equal [[:SLASH, :EMBER], [:SURF], [:SURF], []], [base.line_moves, base.tutor_moves, mid.tutor_moves, top.tutor_moves]
        assert_equal [:SURF], solo.tutor_moves
        assert_equal ["The evolutionary line starting with BASE shares these tutor moves: [:EMBER]"], echoed
        assert_includes written, "[BASE]"
        assert_equal ["Tutor moves consolidated!"], messages
    end
end
