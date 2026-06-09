LEVEL_CAPS_USED = true
LEVEL_CAP_VAR = 26
STARTING_LEVEL_CAP = 15
LEVEL_CAP_INCREASE = 5
MAX_LEVEL_CAP = 70

def setStartingLevelCap
    setLevelCap(STARTING_LEVEL_CAP,false)
end

def increaseLevelCap(increase = LEVEL_CAP_INCREASE)
    return unless LEVEL_CAPS_USED
    setLevelCap($game_variables[LEVEL_CAP_VAR] + increase)
end

def setLevelCap(newCap, showMessage = true)
    return unless LEVEL_CAPS_USED
    $game_variables[LEVEL_CAP_VAR] = newCap
    pbMessage(_INTL("\\wmLevel cap raised to {1}!\\me[Bug catching 3rd]\\wtnp[80]\1", newCap)) if showMessage
end

def levelCapMaxed?
    return $game_variables[LEVEL_CAP_VAR] >= MAX_LEVEL_CAP
end

def getLevelCap
    return $game_variables[LEVEL_CAP_VAR]
end
