require_relative "../../support/test_helper"
require_relative "../../support/graphics_folder"

class FaceWindowVXTest < Minitest::Test
    # Sheets four frames to a row: two rows of 96x96 frames, two rows of 192x256 ones.
    SMALL_SHEET = [384, 192].freeze
    LARGE_SHEET = [768, 512].freeze
    IMAGES = {
        "Graphics/Faces/Val" => LARGE_SHEET,
        "Graphics/Faces/Ana" => SMALL_SHEET,
        "Graphics/Faces shiny/Val" => LARGE_SHEET,
        "Graphics/Pictures/Sign" => SMALL_SHEET,
        "Graphics/Pictures/Val" => LARGE_SHEET,
        "Graphics/Faces/Blink" => LARGE_SHEET,
        # Two animation frames, each a whole sheet, side by side
        "Graphics/Faces/[2,10]Wink" => [LARGE_SHEET[0] * 2, LARGE_SHEET[1]],
    }.freeze

    def setup
        $shiny_faces = ShinyFaces.new
    end

    def teardown
        $shiny_faces = nil
    end

    def run(...)
        GraphicsFolder.with(IMAGES) { super }
    end

    def lastBlt(window)
        return window.contents.blts.last
    end

    def frameShown(window)
        rect = lastBlt(window)[3]
        return [rect.x, rect.y, rect.width, rect.height]
    end

    def sheetShown(window)
        return lastBlt(window)[2].path
    end

    def test_by_default_a_window_shows_a_small_face
        window = FaceWindowVX.new("Ana")
        assert_equal [128, 128], [window.width, window.height]
        assert_equal [0, 0, 96, 96], frameShown(window)
    end

    def test_the_frame_size_and_index_choose_the_frame
        window = FaceWindowVX.new("Val,1", 192, 256)
        assert_equal [224, 288], [window.width, window.height]
        assert_equal [192, 0, 192, 256], frameShown(window)
    end

    def test_the_faces_folder_comes_first
        assert_equal "Graphics/Faces/Val.png", sheetShown(FaceWindowVX.new("Val", 192, 256))
    end

    def test_a_face_not_in_the_faces_folder_comes_from_pictures
        assert_equal "Graphics/Pictures/Sign.png", sheetShown(FaceWindowVX.new("Sign"))
    end

    def test_a_shiny_face_shows_its_shiny_sheet
        $shiny_faces.setShiny("Val", true)
        assert_equal "Graphics/Faces shiny/Val.png", sheetShown(FaceWindowVX.new("Val", 192, 256))
    end

    def test_a_shiny_face_with_no_shiny_sheet_raises
        $shiny_faces.setShiny("Ana", true)
        error = assert_raises(RuntimeError) { FaceWindowVX.new("Ana") }
        assert_equal "Face Ana is flagged shiny but has no sheet in Graphics/Faces shiny", error.message
    end

    def test_a_shiny_face_never_comes_from_pictures
        $shiny_faces.setShiny("Sign", true)
        assert_raises(RuntimeError) { FaceWindowVX.new("Sign") }
    end

    def test_with_no_shiny_flags_at_all_faces_are_plain
        $shiny_faces = nil
        assert_equal "Graphics/Faces/Val.png", sheetShown(FaceWindowVX.new("Val", 192, 256))
    end

    def test_a_still_face_is_drawn_once
        window = FaceWindowVX.new("Ana")
        window.update
        assert_equal 1, window.contents.blts.length
    end

    def test_an_animated_sheet_moves_on_to_its_next_animation_frame
        window = FaceWindowVX.new("[2,10]Wink,1", 192, 256)
        first = lastBlt(window)[2]
        10.times { window.update }
        assert_equal 192, lastBlt(window)[3].x
        refute_same first, lastBlt(window)[2]
    end

    # A GIF, which mkxp-z animates itself.
    def test_an_animated_face_redraws_the_same_frame_on_update
        sheet = RPG::Cache.load_bitmap("Graphics/Faces/", "Blink.png")
        sheet.frame_count = 2
        sheet.frame_rate = 1
        window = FaceWindowVX.new("Blink,1", 192, 256)
        window.update
        frames = window.contents.blts.map { |blt| blt[3].x }
        assert_equal [192, 192], frames
    end

    def test_changing_the_frame_clears_and_redraws
        window = FaceWindowVX.new("Val", 192, 256)
        window.frame = 4
        assert_equal [0, 256, 192, 256], frameShown(window)
        assert_equal 2, window.contents.clears
    end

    def test_disposing_frees_the_face_and_the_window
        window = FaceWindowVX.new("Ana")
        sheet = lastBlt(window)[2]
        face = window.contents
        window.dispose
        assert sheet.disposed?
        assert face.disposed?
        assert window.disposed?
    end
end
