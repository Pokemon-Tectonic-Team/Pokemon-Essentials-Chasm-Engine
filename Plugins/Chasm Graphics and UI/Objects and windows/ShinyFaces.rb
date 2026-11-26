#===============================================================================
# Shiny faces
# A face flagged shiny in this save shows its sheet from Graphics/Faces shiny
# instead, both as an \ff face and as a dialogue portrait. Flag one from an
# event's script call:
#   $shiny_faces.setShiny("Val", true)
# The flag applies to faces shown after it is set; a portrait already on screen
# keeps its sheet until it leaves.
#===============================================================================
SaveData.register(:shiny_faces) do
    ensure_class :ShinyFaces
    save_value { $shiny_faces }
    load_value { |value| $shiny_faces = value }
    new_game_value { ShinyFaces.new }
end

class ShinyFaces
    def initialize
        @names = []
    end

    def shiny?(name)
        return @names.include?(name)
    end

    def setShiny(name, shiny)
        if shiny
            @names |= [name]
        else
            @names.delete(name)
        end
    end
end
