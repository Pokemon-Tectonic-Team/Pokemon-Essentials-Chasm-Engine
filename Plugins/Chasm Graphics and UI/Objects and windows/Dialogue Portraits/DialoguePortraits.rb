#===============================================================================
# Dialogue portraits
# Based on the "Dialogue Portraits" plugin by AenaonDogsky and Mr. Gela, with
# the slide and fade animation of rainefall's rainefallPortraits, and the
# speaker dimming, speaker name tag placement, script commands and standing on
# the skin's visible frame of ___beta___'s "Dialogue Portraits v1.0".
#
# In a message, \ml[face], \mc[face] and \mr[face] show a large portrait on
# the left, centre or right, standing on the message window's visible frame
# (below any transparent space its skin leaves). face is a file in
# Graphics/Faces (or Graphics/Pictures), optionally with a frame index:
# \ml[Val,2] shows the third 192x256 frame of a sheet laid out four to a row.
#
# A portrait slides in from its edge of the screen while fading in (the centre
# one only fades) and stays up across messages until the event ends, the map
# changes, or the same code with no face (\ml[]) clears it. Giving a side
# another frame of the same file swaps it in place, for expression changes; a
# different file slides the old portrait out as the new one slides in.
# Portraits only show on the map. PortraitCommands.rb does the same from an
# event's Script command.
#
# The side last given a face is the speaker, and every portrait but the
# speaker's is dimmed. Clearing the speaker's side leaves nobody speaking, and
# nothing is dimmed.
#===============================================================================
PORTRAIT_FRAME_WIDTH    = 192
PORTRAIT_FRAME_HEIGHT   = 256
# A window draws its contents this far inside its edges
PORTRAIT_WINDOW_PADDING = 16
PORTRAIT_EDGE_MARGIN    = 8
PORTRAIT_SLIDE_DISTANCE = 128
PORTRAIT_SLIDE_SECONDS  = 0.15
PORTRAIT_FADE_SECONDS   = 0.1
PORTRAIT_DIM_SECONDS    = 0.1
PORTRAIT_DIM_COLOR      = Color.new(0, 0, 0, 110)
# Level with message windows, so screen tone and cave darkness don't cover it
PORTRAIT_Z = 99_999
PORTRAIT_SIDES = { "ml" => :left, "mc" => :centre, "mr" => :right }.freeze

# Raises ArgumentError unless side is one of PORTRAIT_SIDES.
def checkPortraitSide(side)
    return if PORTRAIT_SIDES.value?(side)
    raise ArgumentError, "portrait side must be one of #{PORTRAIT_SIDES.values.inspect}, not #{side.inspect}"
end

# Where portraits stand: a message window's position and size, and how far its
# visible frame sits inside its top and bottom edges.
PortraitAnchor = Struct.new(:y, :height, :topInset, :bottomInset) do
    def self.of(window)
        topInset, bottomInset = window.frameInsets
        return new(window.y, window.height, topInset, bottomInset)
    end
end

# The anchor outside a message: where the next message window would show, in
# the speech skin.
def defaultPortraitAnchor
    window = pbCreateStatusWindow
    begin
        pbRepositionMessageWindow(window, pbDefaultMessageLines)
        return PortraitAnchor.of(window)
    ensure
        window.dispose
    end
end

# Returns the [x, y] of a portrait window at rest. It stands on the anchor's
# visible top edge, or hangs under its visible bottom edge when the message
# window is at the top of the screen. Allowing for the window padding means
# the image itself touches the edge.
def portraitWindowPosition(side, portraitWidth, portraitHeight, anchor, screenWidth)
    x = case side
        when :left   then PORTRAIT_EDGE_MARGIN
        when :centre then (screenWidth - portraitWidth) / 2
        else screenWidth - portraitWidth - PORTRAIT_EDGE_MARGIN
        end
    y = if anchor.y <= 0
            anchor.y + anchor.height - PORTRAIT_WINDOW_PADDING - anchor.bottomInset
        else
            anchor.y - portraitHeight + PORTRAIT_WINDOW_PADDING + anchor.topInset
        end
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
        @dim = 0.0
        @dimTarget = 0.0
        @dimAlpha = nil
        @restX = 0
        @restY = 0
        refresh
    end

    def frame=(index)
        @window.frame = index
    end

    def dimmed=(value)
        @dimTarget = value ? 1.0 : 0.0
    end

    def close
        @target = 0.0
    end

    def closed?
        return @target == 0 && settled?
    end

    # Whether slide, fade and dim have all reached their targets.
    def settled?
        return @slide == @target && @fade == @target && @dim == @dimTarget
    end

    def anchor(anchor)
        @restX, @restY = portraitWindowPosition(@side, @window.width, @window.height,
            anchor, Graphics.width)
        refresh
    end

    # Where the image stands once fully in, wherever the slide has it now.
    def restImageRect
        return Rect.new(@restX + PORTRAIT_WINDOW_PADDING, @restY + PORTRAIT_WINDOW_PADDING,
            PORTRAIT_FRAME_WIDTH, PORTRAIT_FRAME_HEIGHT)
    end

    def update
        @slide = approach(@slide, @target, PORTRAIT_SLIDE_SECONDS)
        @fade = approach(@fade, @target, PORTRAIT_FADE_SECONDS)
        @dim = approach(@dim, @dimTarget, PORTRAIT_DIM_SECONDS)
        @window.update
        refresh
    end

    def dispose
        @window.dispose
    end

    private

    # Moves value one frame's step towards target, taking the given number of
    # seconds to cover the whole way from 0 to 1.
    def approach(value, target, seconds)
        step = 1.0 / (seconds * Graphics.frame_rate)
        return [value + step, target].min if value < target
        return [value - step, target].max
    end

    def refresh
        @window.x = @restX + portraitSlideOffset(@side, @slide)
        @window.y = @restY
        @window.contents_opacity = (255 * @fade).round
        refreshDim
    end

    # Setting a window's color redraws all its sprites, so only on a change.
    def refreshDim
        alpha = (PORTRAIT_DIM_COLOR.alpha * @dim).round
        return if alpha == @dimAlpha
        @dimAlpha = alpha
        @window.color = Color.new(PORTRAIT_DIM_COLOR.red, PORTRAIT_DIM_COLOR.green,
            PORTRAIT_DIM_COLOR.blue, alpha)
    end
end

# The portraits on screen, one per side, plus any still sliding out.
class DialoguePortraitSet
    attr_reader :speaker

    def initialize
        @shown = {}
        @leaving = []
        @speaker = nil
    end

    # Shows face on side, standing on anchor, and makes side the speaker. An
    # empty face clears the side.
    def show(side, face, anchor)
        current = @shown[side]
        name, index = parseFaceSpec(face)
        if current && current.file == name
            current.frame = index
        else
            hide(side)
            @shown[side] = DialoguePortrait.new(side, face) unless face.empty?
        end
        @speaker = side unless face.empty?
        refreshDims
        anchor(anchor)
    end

    # Sends side's portrait out, if it has one.
    def hide(side)
        @speaker = nil if side == @speaker
        portrait = @shown.delete(side)
        return unless portrait
        portrait.close
        @leaving.push(portrait)
        refreshDims
    end

    def hideAll
        @shown.each_key { |side| hide(side) }
    end

    # side is one of PORTRAIT_SIDES, or nil for nobody. A side with no
    # portrait is someone off screen, so every portrait shown dims.
    def speaker=(side)
        checkPortraitSide(side) unless side.nil?
        @speaker = side
        refreshDims
    end

    # Whether any portrait is still moving, fading, dimming or leaving.
    def animating?
        return !@leaving.empty? || !@shown.values.all?(&:settled?)
    end

    # [side, restImageRect] of the speaker's portrait, or nil while no shown
    # portrait is speaking.
    def speakerPlacement
        portrait = @shown[@speaker]
        return nil unless portrait
        return [@speaker, portrait.restImageRect]
    end

    def anchor(anchor)
        portraits.each { |portrait| portrait.anchor(anchor) }
    end

    # inConversation is false once no event or message needs the portraits,
    # which sends them all out.
    def update(inConversation)
        hideAll unless inConversation
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

    # Leaving portraits keep the dim they had.
    def refreshDims
        @shown.each { |side, portrait| portrait.dimmed = !@speaker.nil? && side != @speaker }
    end
end
