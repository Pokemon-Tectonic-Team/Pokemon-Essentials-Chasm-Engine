#=============================================================================
# Get approximate properties for a battler
#=============================================================================
def pbRoughType(move, user)
    ret = move.pbCalcType(user)
    return ret
end

#=============================================================================
# Figure out if the AI should play more aggressively
# because the situation allows/requires it
#=============================================================================
def getUrgency
    urgency = 0
    eachOpposing do |b|
        urgency += 1 if !b.canActThisTurn? # pressure sleeping mons
        urgency += 2 if b.hasSetupMove?
        urgency += 2 if b.hasSetupMove? && b.lastRoundMoveCategory == 2 # Actively setting up
        urgency += 2 if b.hasUseableHazardMove?
        urgency += 1 if b.hasUseableHazardMove? && b.lastRoundMoveCategory == 2 # Actively hazard stacking
        urgency += 2 if b.hasActiveAbilityAI?(:CONTRARY) || b.hasActiveAbilityAI?(:INVERSION) || b.hasActiveAbilityAI?(:PERSISTENTGROWTH)
    end
    if inWeatherTeam && urgency = 0
        weatherInfo = [
            [:SUN_TEAM, @battle.sunny?, :DROUGHT, :HEATROCK],
            [:RAIN_TEAM, @battle.rainy?, :DRIZZLE, :DAMPROCK],
            [:SANDSTORM_TEAM, @battle.sandy?, :SANDSTREAM, :SMOOTHROCK],
            [:HAIL_TEAM, @battle.icy?, :SNOWWARNING, :ICYROCK],
            [:MOONGLOW_TEAM, @battle.moonGlowing?, :MOONGAZE, :MIRROREDROCK],
            [:ECLIPSE_TEAM, @battle.eclipsed?, :HARBINGER, :PINPOINTROCK],
        ]    
        weatherInfo.each do |weatherEntry|
            weatherPolicy = weatherEntry[0]
            weatherActive = weatherEntry[1]
            urgency += 1 if weatherActive && weatherPolicy # Weather teams play more aggressively
        end
    end
    urgency = 5 * urgency
    return urgency
end