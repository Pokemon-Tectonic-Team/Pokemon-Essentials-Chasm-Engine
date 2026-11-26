require_relative "../../../support/test_helper"
require_relative "../../../support/graphics_folder"

class DialoguePortraitTest < Minitest::Test
    # Stands in for FaceWindowVX, which needs a real bitmap. Sized as it sizes
    # itself, and records what the portrait sets on it.
    class FakeFaceWindow
        attr_reader :face, :width, :height, :colors, :updates
        attr_accessor :x, :y, :z, :windowskin, :contents_opacity, :frame

        def initialize(face, frameWidth, frameHeight)
            @face = face
            @width = frameWidth + 32
            @height = frameHeight + 32
            @windowskin = :default
            @colors = []
            @updates = 0
            @disposed = false
        end

        def color=(color)
            @colors.push(color)
        end

        def color
            return @colors.last
        end

        def update
            @updates += 1
        end

        def dispose
            @disposed = true
        end

        def disposed?
            return @disposed
        end
    end

    ANCHOR = PortraitAnchor.new(288, 96, 0, 0)
    # Enough frames for the slowest of slide, fade and dim to finish.
    SETTLE_FRAMES = (PORTRAIT_SLIDE_SECONDS * Graphics.frame_rate).ceil + 1

    def build(side = :left, face = "Val,2")
        portrait = DialoguePortrait.new(side, face, FakeFaceWindow)
        @window = portrait.instance_variable_get(:@window)
        return portrait
    end

    def anchored(side = :left)
        portrait = build(side)
        portrait.anchor(ANCHOR)
        return portrait
    end

    def restX(side = :left)
        return portraitWindowPosition(side, @window.width, @window.height, ANCHOR, Graphics.width)[0]
    end

    def updateTimes(portrait, frames)
        frames.times { portrait.update }
    end

    # Updates until the block holds, returning the frames it took; fails after a second.
    def framesUntil(portrait)
        Graphics.frame_rate.times do |frames|
            return frames if yield

            portrait.update
        end
        flunk "not reached within a second of frames"
    end

    def test_the_window_shows_the_face_at_portrait_frame_size
        build
        assert_equal "Val,2", @window.face
        assert_equal [PORTRAIT_FRAME_WIDTH + 32, PORTRAIT_FRAME_HEIGHT + 32], [@window.width, @window.height]
    end

    def test_the_window_has_no_skin_and_stands_at_portrait_depth
        build
        assert_nil @window.windowskin
        assert_equal PORTRAIT_Z, @window.z
    end

    def test_the_file_is_the_face_without_its_frame
        assert_equal "Val", build.file
    end

    def test_a_new_portrait_starts_out_of_view_and_moving
        portrait = anchored
        assert_equal restX - PORTRAIT_SLIDE_DISTANCE, @window.x
        assert_equal 0, @window.contents_opacity
        refute portrait.settled?
    end

    def test_a_new_portrait_starts_undimmed
        anchored
        assert_equal [0, 0, 0, 0], colorOf(@window.color)
    end

    def test_anchoring_places_the_window_at_its_rest_height
        anchored
        assert_equal portraitWindowPosition(:left, @window.width, @window.height, ANCHOR, Graphics.width)[1], @window.y
    end

    def test_one_frame_slides_and_fades_partway_in
        portrait = anchored
        portrait.update
        slide = 1.0 / (PORTRAIT_SLIDE_SECONDS * Graphics.frame_rate)
        fade = 1.0 / (PORTRAIT_FADE_SECONDS * Graphics.frame_rate)
        assert_equal restX + portraitSlideOffset(:left, slide), @window.x
        assert_equal (255 * fade).round, @window.contents_opacity
    end

    def test_a_portrait_comes_to_rest_fully_in_and_opaque
        portrait = anchored
        updateTimes(portrait, SETTLE_FRAMES)
        assert portrait.settled?
        assert_equal restX, @window.x
        assert_equal 255, @window.contents_opacity
    end

    def test_opening_takes_the_slide_time
        portrait = anchored
        frames = framesUntil(portrait) { @window.x == restX }
        assert_in_delta PORTRAIT_SLIDE_SECONDS * Graphics.frame_rate, frames, 1
    end

    def test_a_portrait_is_opaque_before_it_finishes_sliding
        portrait = anchored
        framesUntil(portrait) { @window.contents_opacity == 255 }
        assert_operator @window.x, :<, restX
    end

    def test_a_right_portrait_comes_in_from_the_right
        portrait = anchored(:right)
        assert_equal restX(:right) + PORTRAIT_SLIDE_DISTANCE, @window.x
        updateTimes(portrait, SETTLE_FRAMES)
        assert_equal restX(:right), @window.x
    end

    def test_reanchoring_a_resting_portrait_moves_it_straight_there
        portrait = anchored
        updateTimes(portrait, SETTLE_FRAMES)
        portrait.anchor(PortraitAnchor.new(0, 96, 0, 0))
        assert_equal 96 - PORTRAIT_WINDOW_PADDING, @window.y
    end

    def test_the_rest_image_rect_is_the_image_inside_the_padding_at_rest
        portrait = anchored
        rect = portrait.restImageRect
        assert_equal [restX + PORTRAIT_WINDOW_PADDING, @window.y + PORTRAIT_WINDOW_PADDING,
                      PORTRAIT_FRAME_WIDTH, PORTRAIT_FRAME_HEIGHT],
            [rect.x, rect.y, rect.width, rect.height]
    end

    def test_the_rest_image_rect_ignores_the_slide
        portrait = anchored
        assert_equal restX + PORTRAIT_WINDOW_PADDING, portrait.restImageRect.x
    end

    def test_an_open_portrait_is_not_closed
        portrait = anchored
        updateTimes(portrait, SETTLE_FRAMES)
        refute portrait.closed?
    end

    def test_a_closing_portrait_is_not_closed_until_it_has_left
        portrait = anchored
        updateTimes(portrait, SETTLE_FRAMES)
        portrait.close
        portrait.update
        refute portrait.closed?
    end

    def test_a_closed_portrait_has_slid_out_and_faded
        portrait = anchored
        updateTimes(portrait, SETTLE_FRAMES)
        portrait.close
        updateTimes(portrait, SETTLE_FRAMES)
        assert portrait.closed?
        assert_equal restX - PORTRAIT_SLIDE_DISTANCE, @window.x
        assert_equal 0, @window.contents_opacity
    end

    def test_closing_partway_in_turns_back
        portrait = anchored
        updateTimes(portrait, 3)
        x = @window.x
        portrait.close
        portrait.update
        assert_operator @window.x, :<, x
    end

    def test_dimming_darkens_to_the_dim_colour
        portrait = anchored
        portrait.dimmed = true
        updateTimes(portrait, SETTLE_FRAMES)
        assert_equal colorOf(PORTRAIT_DIM_COLOR), colorOf(@window.color)
        assert portrait.settled?
    end

    def test_dimming_eases_in_over_the_dim_time
        portrait = anchored
        portrait.dimmed = true
        portrait.update
        assert_includes 1...PORTRAIT_DIM_COLOR.alpha, @window.color.alpha
        frames = 1 + framesUntil(portrait) { @window.color.alpha == PORTRAIT_DIM_COLOR.alpha }
        assert_in_delta PORTRAIT_DIM_SECONDS * Graphics.frame_rate, frames, 1
    end

    def test_undimming_eases_back_out
        portrait = anchored
        portrait.dimmed = true
        updateTimes(portrait, SETTLE_FRAMES)
        portrait.dimmed = false
        portrait.update
        assert_includes 1...PORTRAIT_DIM_COLOR.alpha, @window.color.alpha
    end

    def test_a_closing_portrait_is_not_settled
        portrait = anchored
        updateTimes(portrait, SETTLE_FRAMES)
        portrait.close
        refute portrait.settled?
    end

    def test_a_dimming_portrait_is_not_settled
        portrait = anchored
        updateTimes(portrait, SETTLE_FRAMES)
        portrait.dimmed = true
        refute portrait.settled?
    end

    def test_undimming_clears_the_colour
        portrait = anchored
        portrait.dimmed = true
        updateTimes(portrait, SETTLE_FRAMES)
        portrait.dimmed = false
        updateTimes(portrait, SETTLE_FRAMES)
        assert_equal 0, @window.color.alpha
    end

    def test_the_colour_is_only_set_when_the_dim_changes
        portrait = anchored
        updateTimes(portrait, SETTLE_FRAMES)
        portrait.anchor(ANCHOR)
        assert_equal 1, @window.colors.length
    end

    def test_setting_the_frame_shows_it_in_the_window
        build.frame = 3
        assert_equal 3, @window.frame
    end

    def test_each_update_updates_the_window
        portrait = anchored
        updateTimes(portrait, 2)
        assert_equal 2, @window.updates
    end

    def test_disposing_disposes_the_window
        build.dispose
        assert @window.disposed?
    end

    private

    def colorOf(color)
        return [color.red, color.green, color.blue, color.alpha]
    end
end

# Portraits on real face windows, in a set as the map holds them.
class DialoguePortraitFaceTest < Minitest::Test
    SHEET = [768, 512].freeze
    IMAGES = { "Graphics/Faces/Val" => SHEET, "Graphics/Faces shiny/Val" => SHEET }.freeze
    ANCHOR = PortraitAnchor.new(288, 96, 0, 0)

    def run(...)
        GraphicsFolder.with(IMAGES) { super }
    end

    def setup
        $shiny_faces = ShinyFaces.new
        @portraits = DialoguePortraitSet.new
    end

    def teardown
        @portraits.dispose
        $shiny_faces = nil
    end

    def leftWindow
        return @portraits.instance_variable_get(:@shown)[:left].instance_variable_get(:@window)
    end

    def sheetShown
        return leftWindow.contents.blts.last[2].path
    end

    def frameXShown
        return leftWindow.contents.blts.last[3].x
    end

    def test_a_portrait_is_a_skinless_face_window_of_the_portrait_frame_size
        @portraits.show(:left, "Val,1", ANCHOR)
        assert_instance_of FaceWindowVX, leftWindow
        assert_nil leftWindow.windowskin
        assert_equal [PORTRAIT_FRAME_WIDTH + 32, PORTRAIT_FRAME_HEIGHT + 32], [leftWindow.width, leftWindow.height]
        assert_equal PORTRAIT_FRAME_WIDTH, frameXShown
    end

    def test_another_frame_redraws_the_same_window
        @portraits.show(:left, "Val", ANCHOR)
        window = leftWindow
        @portraits.show(:left, "Val,3", ANCHOR)
        assert_same window, leftWindow
        assert_equal PORTRAIT_FRAME_WIDTH * 3, frameXShown
    end

    def test_a_shiny_face_shows_its_shiny_sheet
        $shiny_faces.setShiny("Val", true)
        @portraits.show(:left, "Val", ANCHOR)
        assert_equal "Graphics/Faces shiny/Val.png", sheetShown
    end

    def test_a_face_flagged_shiny_while_shown_keeps_its_sheet_until_it_comes_back
        @portraits.show(:left, "Val", ANCHOR)
        $shiny_faces.setShiny("Val", true)
        @portraits.show(:left, "Val,1", ANCHOR)
        assert_equal "Graphics/Faces/Val.png", sheetShown
        @portraits.hide(:left)
        @portraits.show(:left, "Val", ANCHOR)
        assert_equal "Graphics/Faces shiny/Val.png", sheetShown
    end
end
