def setSpeaker(speakerName,viewport = nil)
    unless $SpeakerNameWindow
        $SpeakerNameWindow = Window_AdvancedTextPokemon.new
        $SpeakerNameWindow.setSkin(MessageConfig.pbGetSpeechFrame)
    end
    $SpeakerNameWindow.text = _INTL(speakerName)
    $SpeakerNameWindow.viewport = viewport
    refreshSpeakerWindow
end

# A separate version of setSpeaker that works in Ruby functions without affecting the behaviour in scripts
# It is the calling function's responsibility to call removeSpeakerRuby before moving into a function that will display speakerless messages
def setSpeakerRuby(speakerName,viewport = nil)
    unless $SpeakerNameWindowRuby
        $SpeakerNameWindowRuby = Window_AdvancedTextPokemon.new
        $SpeakerNameWindowRuby.setSkin(MessageConfig.pbGetSpeechFrame)
    end
    $SpeakerNameWindowRuby.text = _INTL(speakerName)
    $SpeakerNameWindowRuby.viewport = viewport
    refreshSpeakerWindow
end

def refreshSpeakerWindow
    return unless $SpeakerNameWindow
    $SpeakerNameWindow.resizeToFit($SpeakerNameWindow.text,Graphics.width)
    $SpeakerNameWindow.width = 160 if $SpeakerNameWindow.width <= 160
    $SpeakerNameWindow.y = Graphics.height - $SpeakerNameWindow.height
    $SpeakerNameWindow.z = 99_999
    $SpeakerNameWindow.visible = false # Starts hidden
end

def setSpeakerTrainer(trainerClass,trainerName)
    begin
        trainerData = GameData::Trainer.get(trainerClass,trainerName)
        setSpeaker(trainerData.to_trainer.full_name)
    rescue ArgumentError
        echoln("Unable to find dialogue label display name for trainer: #{trainerClass} #{trainerName}")
    end
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

def showSpeakerRuby
    return unless $SpeakerNameWindowRuby
    $SpeakerNameWindowRuby.visible = true
end

def removeSpeaker
    $SpeakerNameWindow.dispose if $SpeakerNameWindow
    $SpeakerNameWindow = nil
end

def removeSpeakerRuby
    $SpeakerNameWindowRuby.dispose if $SpeakerNameWindowRuby
    $SpeakerNameWindowRuby = nil
end