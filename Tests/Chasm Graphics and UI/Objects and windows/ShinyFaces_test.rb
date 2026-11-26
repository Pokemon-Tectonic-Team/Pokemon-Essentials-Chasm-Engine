require_relative "../../support/test_helper"

class ShinyFacesTest < Minitest::Test
    def teardown
        $shiny_faces = nil
    end

    def saveValue
        return SaveData.instance_variable_get(:@values).find { |value| value.id == :shiny_faces }
    end

    def test_no_face_starts_shiny
        refute ShinyFaces.new.shiny?("Val")
    end

    def test_a_flagged_face_is_shiny
        faces = ShinyFaces.new
        faces.setShiny("Val", true)
        assert faces.shiny?("Val")
    end

    def test_flagging_one_face_leaves_the_others_alone
        faces = ShinyFaces.new
        faces.setShiny("Val", true)
        refute faces.shiny?("Ana")
    end

    def test_a_face_can_be_unflagged
        faces = ShinyFaces.new
        faces.setShiny("Val", true)
        faces.setShiny("Val", false)
        refute faces.shiny?("Val")
    end

    def test_flagging_twice_then_unflagging_once_unflags
        faces = ShinyFaces.new
        faces.setShiny("Val", true)
        faces.setShiny("Val", true)
        faces.setShiny("Val", false)
        refute faces.shiny?("Val")
    end

    def test_unflagging_a_face_never_flagged_does_nothing
        faces = ShinyFaces.new
        faces.setShiny("Val", false)
        refute faces.shiny?("Val")
    end

    def test_a_new_game_starts_with_no_shiny_faces
        saveValue.load_new_game_value
        assert_instance_of ShinyFaces, $shiny_faces
        refute $shiny_faces.shiny?("Val")
    end

    def test_the_save_holds_the_flags
        $shiny_faces = ShinyFaces.new
        assert_same $shiny_faces, saveValue.save
    end

    def test_loading_a_save_restores_its_flags
        faces = ShinyFaces.new
        faces.setShiny("Val", true)
        saveValue.load(faces)
        assert $shiny_faces.shiny?("Val")
    end

    def test_a_save_holding_something_else_is_refused
        assert_raises(SaveData::InvalidValueError) { saveValue.load([]) }
    end
end
