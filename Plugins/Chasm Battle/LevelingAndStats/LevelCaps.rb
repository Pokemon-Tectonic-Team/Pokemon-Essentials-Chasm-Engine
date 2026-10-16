LEVEL_CAPS_USED = true
LEVEL_CAP_VAR = 26

STARTING_LEVEL_CAP = 15
LEVEL_CAP_INCREASE = 5
MAX_LEVEL_CAP = 70

# Can be :SAME_CAP, :SEPARATE_CAP, or :IGNORE_CAP
# If :SAME_CAP, rare candies obey the same level cap as everything else
# If :SEPARATE_CAP, rare candies have their own, seperate level cap which is higher than the regular level cap
# If :IGNORE_CAP, rare candies can be used regardless of the level cap
RARE_CANDY_LEVEL_CAP_BEHAVIOUR = :IGNORE_CAP
# Only used if :SEPARATE_CAP is the setting used
RARE_CANDY_LEVEL_CAP_OFFSET = 5 # How much higher the rare candy level cap is compared to the regular level cap

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

def rareCandiesLevelCapped?
    return LEVEL_CAPS_USED && RARE_CANDY_LEVEL_CAP_BEHAVIOUR != :IGNORE_CAP
end

def getRareCandyLevelCap
    case RARE_CANDY_LEVEL_CAP_BEHAVIOUR
    when :SAME_CAP
        return getLevelCap
    when :SEPARATE_CAP
        return [getLevelCap + RARE_CANDY_LEVEL_CAP_OFFSET, GameData::GrowthRate.max_level].min
    when :IGNORE_CAP
        return GameData::GrowthRate.max_level
    end
end
