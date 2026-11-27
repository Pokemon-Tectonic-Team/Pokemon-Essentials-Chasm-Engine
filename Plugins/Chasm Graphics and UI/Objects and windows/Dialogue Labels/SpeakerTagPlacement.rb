# Where the speaker name tag (DialogueLabels.rb) stands beside a portrait.
SPEAKER_TAG_GAP = 4

# The x of a tag tagWidth wide beside a portrait image of the given side.
# Raises ArgumentError for a tag wider than the screen, which can't be kept on
# it.
def speakerTagX(side, imageRect, tagWidth, screenWidth)
    if tagWidth > screenWidth
        raise ArgumentError, "speaker tag is #{tagWidth} wide, wider than the #{screenWidth}-wide screen"
    end
    leftOfImage = imageRect.x - SPEAKER_TAG_GAP - tagWidth
    rightOfImage = imageRect.x + imageRect.width + SPEAKER_TAG_GAP
    x = case side
        when :left   then rightOfImage
        when :centre then (leftOfImage >= 0) ? leftOfImage : rightOfImage
        else leftOfImage
        end
    return x.clamp(0, screenWidth - tagWidth)
end
