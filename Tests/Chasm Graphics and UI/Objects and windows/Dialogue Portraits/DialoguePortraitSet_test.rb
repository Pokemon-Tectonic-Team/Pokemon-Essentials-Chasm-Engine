require_relative "../../../support/test_helper"

class DialoguePortraitSetTest < Minitest::Test
    # Stands in for DialoguePortrait, which needs a real window. It records what
    # the set asks of it, and is settled unless a test says otherwise.
    class FakePortrait
        attr_reader :side, :face, :file, :anchors, :updates
        attr_accessor :frame
        attr_writer :settled, :dimmed

        def initialize(side, face)
            @side = side
            @face = face
            @file = parseFaceSpec(face)[0]
            @frame = nil
            @dimmed = nil
            @closing = false
            @settled = true
            @disposed = false
            @anchors = []
            @updates = 0
        end

        def dimmed?
            return @dimmed
        end

        def close
            @closing = true
        end

        def closing?
            return @closing
        end

        def closed?
            return @closing && @settled
        end

        def settled?
            return @settled
        end

        def anchor(anchor)
            @anchors.push(anchor)
        end

        def restImageRect
            return "rect of #{@face}"
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

    # Given to the set as its portrait class; keeps every portrait it builds.
    class FakePortraitFactory
        attr_reader :built

        def initialize
            @built = []
        end

        def new(side, face)
            portrait = FakePortrait.new(side, face)
            @built.push(portrait)
            return portrait
        end
    end

    ANCHOR = PortraitAnchor.new(288, 96, 0, 0)
    OTHER_ANCHOR = PortraitAnchor.new(0, 96, 0, 0)

    def setup
        @factory = FakePortraitFactory.new
        @set = DialoguePortraitSet.new(@factory)
    end

    def show(side, face, anchor = ANCHOR)
        @set.show(side, face, anchor)
        return @factory.built.last
    end

    # show

    def test_showing_a_face_builds_its_portrait_on_that_side
        portrait = show(:left, "Val")
        assert_equal [:left, "Val"], [portrait.side, portrait.face]
    end

    def test_showing_a_face_makes_its_side_the_speaker
        show(:left, "Val")
        assert_equal :left, @set.speaker
    end

    def test_showing_anchors_the_new_portrait
        assert_equal [ANCHOR], show(:left, "Val").anchors
    end

    def test_showing_re_anchors_every_portrait_including_those_leaving
        left = show(:left, "Val")
        right = show(:right, "Ana")
        @set.hide(:right)
        show(:centre, "Kai", OTHER_ANCHOR)
        assert_equal OTHER_ANCHOR, left.anchors.last
        assert_equal OTHER_ANCHOR, right.anchors.last
    end

    def test_another_frame_of_the_same_file_swaps_in_place
        first = show(:left, "Val")
        @set.show(:left, "Val,2", ANCHOR)
        assert_equal 1, @factory.built.length
        assert_equal 2, first.frame
        refute_predicate first, :closing?
    end

    def test_the_bare_name_of_a_shown_file_swaps_to_frame_zero
        first = show(:left, "Val,2")
        @set.show(:left, "Val", ANCHOR)
        assert_equal 0, first.frame
    end

    def test_a_different_file_sends_the_old_portrait_out_and_brings_the_new_one_in
        old = show(:left, "Val")
        new = show(:left, "Ana")
        refute_same old, new
        assert_predicate old, :closing?
        refute_predicate new, :closing?
    end

    def test_a_swap_in_place_makes_its_side_the_speaker
        show(:left, "Val")
        show(:right, "Ana")
        @set.show(:left, "Val,1", ANCHOR)
        assert_equal :left, @set.speaker
    end

    def test_an_empty_face_sends_the_side_out
        portrait = show(:left, "Val")
        @set.show(:left, "", ANCHOR)
        assert_predicate portrait, :closing?
        assert_equal 1, @factory.built.length
    end

    def test_an_empty_face_on_the_speaker_leaves_nobody_speaking
        show(:left, "Val")
        @set.show(:left, "", ANCHOR)
        assert_nil @set.speaker
    end

    def test_an_empty_face_on_another_side_keeps_the_speaker
        show(:left, "Val")
        show(:right, "Ana")
        @set.show(:left, "", ANCHOR)
        assert_equal :right, @set.speaker
    end

    def test_an_empty_face_on_an_empty_side_builds_nothing
        @set.show(:left, "", ANCHOR)
        assert_empty @factory.built
        assert_nil @set.speaker
    end

    # Dimming

    def test_a_lone_speaker_is_not_dimmed
        refute_predicate show(:left, "Val"), :dimmed?
    end

    def test_everyone_but_the_speaker_is_dimmed
        left = show(:left, "Val")
        centre = show(:centre, "Kai")
        right = show(:right, "Ana")
        assert_predicate left, :dimmed?
        assert_predicate centre, :dimmed?
        refute_predicate right, :dimmed?
    end

    def test_setting_the_speaker_moves_the_dimming
        left = show(:left, "Val")
        right = show(:right, "Ana")
        @set.speaker = :left
        refute_predicate left, :dimmed?
        assert_predicate right, :dimmed?
    end

    def test_a_speaker_with_no_portrait_dims_everyone_shown
        left = show(:left, "Val")
        right = show(:right, "Ana")
        @set.speaker = :centre
        assert_equal :centre, @set.speaker
        assert_predicate left, :dimmed?
        assert_predicate right, :dimmed?
    end

    def test_no_speaker_dims_nobody
        left = show(:left, "Val")
        right = show(:right, "Ana")
        @set.speaker = nil
        refute_predicate left, :dimmed?
        refute_predicate right, :dimmed?
    end

    def test_an_unknown_speaker_side_raises_and_keeps_the_speaker
        show(:left, "Val")
        assert_raises(ArgumentError) { @set.speaker = :center }
        assert_equal :left, @set.speaker
    end

    def test_hiding_the_speaker_undims_the_rest
        left = show(:left, "Val")
        show(:right, "Ana")
        @set.hide(:right)
        refute_predicate left, :dimmed?
    end

    def test_a_leaving_portrait_keeps_its_dim
        left = show(:left, "Val")
        show(:right, "Ana")
        @set.hide(:left)
        @set.speaker = nil
        assert_predicate left, :dimmed?
    end

    # hide and hideAll

    def test_hiding_a_side_sends_its_portrait_out
        portrait = show(:left, "Val")
        @set.hide(:left)
        assert_predicate portrait, :closing?
    end

    def test_hiding_another_side_keeps_the_speaker
        show(:left, "Val")
        show(:right, "Ana")
        @set.speaker = :left
        @set.hide(:right)
        assert_equal :left, @set.speaker
    end

    def test_hiding_an_empty_speaking_side_leaves_nobody_speaking
        show(:left, "Val")
        @set.speaker = :centre
        @set.hide(:centre)
        assert_nil @set.speaker
    end

    def test_hiding_all_sends_every_portrait_out_and_leaves_nobody_speaking
        portraits = [show(:left, "Val"), show(:centre, "Kai"), show(:right, "Ana")]
        @set.hideAll
        assert(portraits.all?(&:closing?))
        assert_nil @set.speaker
    end

    def test_a_side_shown_again_after_hiding_gets_a_new_portrait
        old = show(:left, "Val")
        @set.hide(:left)
        new = show(:left, "Val")
        refute_same old, new
    end

    # animating?

    def test_settled_portraits_are_not_animating
        show(:left, "Val")
        refute_predicate @set, :animating?
    end

    def test_an_unsettled_portrait_is_animating
        show(:left, "Val").settled = false
        assert_predicate @set, :animating?
    end

    def test_a_leaving_portrait_is_animating_until_an_update_removes_it
        show(:left, "Val")
        @set.hide(:left)
        assert_predicate @set, :animating?
        @set.update(true)
        refute_predicate @set, :animating?
    end

    def test_an_empty_set_is_not_animating
        refute_predicate @set, :animating?
    end

    # speakerPlacement

    def test_the_speaker_placement_is_its_side_and_rest_image_rect
        show(:left, "Val")
        show(:right, "Ana")
        assert_equal [:right, "rect of Ana"], @set.speakerPlacement
    end

    def test_no_speaker_has_no_placement
        show(:left, "Val")
        @set.speaker = nil
        assert_nil @set.speakerPlacement
    end

    def test_a_speaker_with_no_portrait_has_no_placement
        show(:left, "Val")
        @set.speaker = :right
        assert_nil @set.speakerPlacement
    end

    # update and dispose

    def test_an_update_updates_every_portrait_including_those_leaving
        leaving = show(:left, "Val")
        leaving.settled = false
        @set.hide(:left)
        staying = show(:right, "Ana")
        @set.update(true)
        assert_equal [1, 1], [leaving.updates, staying.updates]
    end

    def test_an_update_disposes_portraits_that_have_finished_leaving
        portrait = show(:left, "Val")
        @set.hide(:left)
        @set.update(true)
        assert_predicate portrait, :disposed?
    end

    def test_a_portrait_still_leaving_is_kept
        portrait = show(:left, "Val")
        portrait.settled = false
        @set.hide(:left)
        @set.update(true)
        refute_predicate portrait, :disposed?
        assert_predicate @set, :animating?
    end

    def test_a_disposed_portrait_is_not_updated_again
        portrait = show(:left, "Val")
        @set.hide(:left)
        @set.update(true)
        @set.update(true)
        assert_equal 1, portrait.updates
    end

    def test_an_update_in_conversation_keeps_the_portraits_up
        portrait = show(:left, "Val")
        @set.update(true)
        refute_predicate portrait, :closing?
        assert_equal :left, @set.speaker
    end

    def test_an_update_out_of_conversation_sends_every_portrait_out
        left = show(:left, "Val")
        right = show(:right, "Ana")
        @set.update(false)
        assert_predicate left, :closing?
        assert_predicate right, :closing?
        assert_nil @set.speaker
    end

    def test_disposing_disposes_shown_and_leaving_portraits
        leaving = show(:left, "Val")
        leaving.settled = false
        @set.hide(:left)
        shown = show(:right, "Ana")
        @set.dispose
        assert_predicate leaving, :disposed?
        assert_predicate shown, :disposed?
        refute_predicate @set, :animating?
    end
end
