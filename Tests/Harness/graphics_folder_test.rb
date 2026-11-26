require_relative "../support/test_helper"
require_relative "../support/graphics_folder"

class GraphicsFolderTest < Minitest::Test
    def test_the_block_runs_in_a_temporary_folder_removed_after
        cwd = Dir.pwd
        folder = nil
        GraphicsFolder.with do |dir|
            folder = dir
            assert_equal File.realpath(dir), File.realpath(Dir.pwd)
        end
        assert_equal cwd, Dir.pwd
        refute File.exist?(folder)
    end

    def test_each_image_is_a_png_of_its_size
        GraphicsFolder.with("Graphics/Faces/Val" => [30, 20]) do
            assert_equal [30, 20], Bitmap.png_size("Graphics/Faces/Val.png")
        end
    end

    def test_the_game_resolves_each_image
        GraphicsFolder.with("Graphics/Faces/Val" => [30, 20]) do
            assert_equal "Graphics/Faces/Val.png", pbResolveBitmap("Graphics/Faces/Val")
        end
    end

    def test_the_message_skins_are_the_default_skins
        GraphicsFolder.with do
            assert_equal "#{MessageConfig.speechFrameName}.png", MessageConfig.pbGetSpeechFrame
            assert_equal "#{MessageConfig.systemFrameName}.png", MessageConfig.pbGetSystemFrame
        end
    end

    def test_the_image_cache_starts_empty
        RPG::Cache.setKey("stale", Bitmap.new(1, 1))
        GraphicsFolder.with { assert_empty RPG::Cache.instance_variable_get(:@cache) }
    end
end
