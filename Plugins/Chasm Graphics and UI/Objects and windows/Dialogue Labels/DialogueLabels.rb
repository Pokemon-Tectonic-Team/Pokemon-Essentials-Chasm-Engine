#===============================================================================
# Dialogue labels
# setSpeaker(name) shows a name tag on the messages events show, until
# removeSpeaker, which starting another event calls.
#
# While a message shows, the tag sits on the message window's left, at least
# SPEAKER_TAG_MIN_WIDTH wide. When the speaking side has a dialogue portrait,
# the tag instead shrinks to its text and stands beside that portrait's image
# on the side facing the screen centre: right of a left portrait, left of a
# right one, and left of a centre one if it fits there, else right. It stays
# on screen even if that means covering a portrait (speakerTagX, in
# SpeakerTagPlacement.rb).
#===============================================================================
SPEAKER_TAG_MIN_WIDTH = 160

# The name tag window, which remembers how wide its text alone needs it to be.
class SpeakerNameWindow < Window_AdvancedTextPokemon
    attr_reader :fitWidth

    def resizeToFit(text, maxwidth = -1)
        super
        @fitWidth = width
    end
end

def setSpeaker(speakerName, viewport = nil)
    unless $SpeakerNameWindow
        $SpeakerNameWindow = SpeakerNameWindow.new
        $SpeakerNameWindow.setSkin(MessageConfig.pbGetSpeechFrame)
    end
    $SpeakerNameWindow.text = _INTL(speakerName)
    $SpeakerNameWindow.viewport = viewport
    refreshSpeakerWindow
end

def refreshSpeakerWindow
    return unless $SpeakerNameWindow
    $SpeakerNameWindow.resizeToFit($SpeakerNameWindow.text, Graphics.width)
    $SpeakerNameWindow.width = [$SpeakerNameWindow.fitWidth, SPEAKER_TAG_MIN_WIDTH].max
    $SpeakerNameWindow.y = Graphics.height - $SpeakerNameWindow.height
    $SpeakerNameWindow.z = 99_999
    $SpeakerNameWindow.visible = false # Starts hidden
end

# Places the tag for msgwindow. speaker is nil, or [side, imageRect] of the
# speaking portrait (DialoguePortraitSet#speakerPlacement).
def positionSpeakerWindow(msgwindow, speaker)
    window = $SpeakerNameWindow
    return unless window
    width = speaker ? window.fitWidth : [window.fitWidth, SPEAKER_TAG_MIN_WIDTH].max
    window.width = width if window.width != width # Setting it redraws the text
    pbPositionNearMsgWindow(window, msgwindow, :left)
    window.y += 12
    window.z = msgwindow.z + 1
    if speaker
        window.x = speakerTagX(*speaker, width, Graphics.width)
    else
        window.x += 12
    end
end

# Names the speaker by the trainer's full name, or logs and shows nothing for a
# trainer that isn't defined.
def setSpeakerTrainer(trainerClass, trainerName)
    unless speakerTrainerExists?(trainerClass, trainerName)
        echoln("Unable to find dialogue label display name for trainer: #{trainerClass} #{trainerName}")
        return
    end
    setSpeaker(GameData::Trainer.get(trainerClass, trainerName).to_trainer.full_name)
end

# Whether a trainer is defined, false for a class or name of the wrong type.
def speakerTrainerExists?(trainerClass, trainerName)
    return GameData::Trainer.exists?(trainerClass, trainerName)
rescue ArgumentError
    return false
end

def speakerNameWindowVisible?
    return $SpeakerNameWindow&.visible
end

def hideSpeaker
    return unless $SpeakerNameWindow
    $SpeakerNameWindow.visible = false
end

def showSpeaker
    return unless $SpeakerNameWindow
    $SpeakerNameWindow.visible = true
end

def removeSpeaker
    $SpeakerNameWindow&.dispose
    $SpeakerNameWindow = nil
end
