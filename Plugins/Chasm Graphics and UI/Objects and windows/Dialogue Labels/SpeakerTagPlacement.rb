# Where the speaker name tag (DialogueLabels.rb) stands beside a portrait.
SPEAKER_TAG_GAP = 4

# The x of a tag tagWidth wide beside a portrait image of the given side.
def speakerTagX(side, imageRect, tagWidth, screenWidth)
    leftOfImage = imageRect.x - SPEAKER_TAG_GAP - tagWidth
    rightOfImage = imageRect.x + imageRect.width + SPEAKER_TAG_GAP
    x = case side
        when :left   then rightOfImage
        when :centre then (leftOfImage >= 0) ? leftOfImage : rightOfImage
        else leftOfImage
        end
    return x.clamp(0, screenWidth - tagWidth)
end
