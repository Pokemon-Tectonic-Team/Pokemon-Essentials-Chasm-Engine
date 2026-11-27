#===============================================================================
# Dialogue portrait script commands
# For an event's Script command, to do outside a message what \ml, \mc and \mr
# do inside one (see DialoguePortraits.rb). side is :left, :centre or :right;
# face is written as in those codes.
#
#   showPortrait(:left, "Val")     Val slides in on the left and speaks.
#   showPortrait(:left, "Val,2")   Val's third frame swaps in place.
#   showPortrait(:left, "")        The left portrait slides out.
#   hidePortrait(:right)           The right portrait slides out.
#   hidePortraits                  Every portrait slides out.
#   setPortraitSpeaker(:right)     The right side speaks and the rest dim. A
#                                  side with no portrait is someone off
#                                  screen, so everyone shown dims.
#   setPortraitSpeaker(nil)        Nobody speaks; nothing is dimmed.
#   waitForPortraits               Waits until every portrait has finished
#                                  sliding, fading and dimming.
#
# The event carries on while portraits move unless it waits. They stand where
# the next message will show and follow it once it does. Portraits only exist
# on the map; elsewhere these commands raise.
#===============================================================================
def showPortrait(side, face)
    checkPortraitSide(side)
    scriptPortraits.show(side, face, defaultPortraitAnchor)
end

def hidePortrait(side)
    checkPortraitSide(side)
    scriptPortraits.hide(side)
end

def hidePortraits
    scriptPortraits.hideAll
end

def setPortraitSpeaker(side)
    scriptPortraits.speaker = side
end

def waitForPortraits
    portraits = scriptPortraits
    pbWait(1) while portraits.animating?
end

# The map's portraits, raising off the map, where there are none.
def scriptPortraits
    portraits = pbDialoguePortraits
    raise "dialogue portraits only show on the map" unless portraits
    return portraits
end
