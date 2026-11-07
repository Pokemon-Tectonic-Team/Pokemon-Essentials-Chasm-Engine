#===============================================================================
# Dialogue portraits
# Based on the "Dialogue Portraits" plugin by AenaonDogsky and Mr. Gela, with
# the slide and fade animation of rainefall's rainefallPortraits.
#
# In a message, \ml[face], \mc[face] and \mr[face] show a large portrait on
# the left, centre or right, standing on the message window. face is a file in
# Graphics/Faces (or Graphics/Pictures), optionally with a frame index:
# \ml[Val,2] shows the third 192x256 frame of a sheet laid out four to a row.
#
# A portrait slides in from its edge of the screen while fading in (the centre
# one only fades) and stays up across messages until the event ends, the map
# changes, or the same code with no face (\ml[]) clears it. Giving a side
# another frame of the same file swaps it in place, for expression changes; a
# different file slides the old portrait out as the new one slides in.
# Portraits only show on the map.
#===============================================================================
PORTRAIT_FRAME_WIDTH    = 192
PORTRAIT_FRAME_HEIGHT   = 256
PORTRAIT_EDGE_MARGIN    = 8
PORTRAIT_SLIDE_DISTANCE = 128
PORTRAIT_SLIDE_SECONDS  = 0.15
PORTRAIT_FADE_SECONDS   = 0.1
# Level with message windows, so screen tone and cave darkness don't cover it
PORTRAIT_Z = 99_999
PORTRAIT_SIDES = { "ml" => :left, "mc" => :centre, "mr" => :right }.freeze

# Returns the [x, y] of a portrait window at rest. It stands on the message
# window's top edge, or hangs under its bottom edge when the message window is
# at the top of the screen. The 16px window padding means the image itself
# touches the edge.
def portraitWindowPosition(side, portraitWidth, portraitHeight, msgY, msgHeight, screenWidth)
    x = case side
        when :left   then PORTRAIT_EDGE_MARGIN
        when :centre then (screenWidth - portraitWidth) / 2
        when :right  then screenWidth - portraitWidth - PORTRAIT_EDGE_MARGIN
        end
    y = (msgY <= 0) ? msgY + msgHeight - 16 : msgY - portraitHeight + 16
    return [x, y]
end

# Horizontal offset from the rest position, where slide 0 is fully out and
# 1 is fully in. Side portraits come from their own edge; the centre one
# doesn't move.
def portraitSlideOffset(side, slide)
    distance = (PORTRAIT_SLIDE_DISTANCE * (1 - slide)).round
    return case side
           when :left  then -distance
           when :right then distance
           else 0
           end
end

# The portraits shown on the current map, or nil off the map.
def pbDialoguePortraits
    return nil unless $scene.is_a?(Scene_Map)
    return $scene.spritesetGlobal&.portraits
end

# One portrait on one side of the screen, animating towards shown or hidden.
class DialoguePortrait
    attr_reader :file

    def initialize(side, face)
        @side = side
        @file = parseFaceSpec(face)[0]
        @window = FaceWindowVX.new(face, PORTRAIT_FRAME_WIDTH, PORTRAIT_FRAME_HEIGHT)
        @window.windowskin = nil
        @window.z = PORTRAIT_Z
        @slide = 0.0
        @fade = 0.0
        @target = 1.0
        @restX = 0
        @restY = 0
        refresh
    end

    def frame=(index)
        @window.frame = index
    end

    def close
        @target = 0.0
    end

    def closed?
        return @target == 0 && @slide == 0 && @fade == 0
    end

    def anchor(msgY, msgHeight)
        @restX, @restY = portraitWindowPosition(@side, @window.width, @window.height,
            msgY, msgHeight, Graphics.width)
        refresh
    end

    def update
        @slide = approach(@slide, PORTRAIT_SLIDE_SECONDS)
        @fade = approach(@fade, PORTRAIT_FADE_SECONDS)
        @window.update
        refresh
    end

    def dispose
        @window.dispose
    end

    private

    # Moves value one frame's step towards the target, taking the given
    # number of seconds to cover the whole way.
    def approach(value, seconds)
        step = 1.0 / (seconds * Graphics.frame_rate)
        return [value + step, @target].min if value < @target
        return [value - step, @target].max
    end

    def refresh
        @window.x = @restX + portraitSlideOffset(@side, @slide)
        @window.y = @restY
        @window.contents_opacity = (255 * @fade).round
    end
end

# The portraits on screen, one per side, plus any still sliding out.
class DialoguePortraitSet
    def initialize
        @shown = {}
        @leaving = []
    end

    # Shows face on side, standing on msgwindow. An empty face clears the side.
    def show(side, face, msgwindow)
        current = @shown[side]
        name, index = parseFaceSpec(face)
        if current && current.file == name
            current.frame = index
        else
            leave(side)
            @shown[side] = DialoguePortrait.new(side, face) unless face.empty?
        end
        anchor(msgwindow)
    end

    def anchor(msgwindow)
        portraits.each { |portrait| portrait.anchor(msgwindow.y, msgwindow.height) }
    end

    # inConversation is false once no event or message needs the portraits,
    # which sends them all out.
    def update(inConversation)
        @shown.keys.each { |side| leave(side) } unless inConversation
        portraits.each(&:update)
        finished, @leaving = @leaving.partition(&:closed?)
        finished.each(&:dispose)
    end

    def dispose
        portraits.each(&:dispose)
        @shown.clear
        @leaving.clear
    end

    private

    def portraits
        return @shown.values + @leaving
    end

    def leave(side)
        portrait = @shown.delete(side)
        return unless portrait
        portrait.close
        @leaving.push(portrait)
    end
end
