class PokeBattle_Battle
    # short: shortened duration due to ability set exception
    def pbStartRoom(roomEffect, user, short = nil, aiCheck = false, duration: nil)
        duration ||= (short ? 4 : 8)
        duration = user.getRoomDuration(duration, aiCheck: aiCheck)
        effectName = GameData::BattleEffect.get(roomEffect).name

        if @field.effectActive?(roomEffect)
            if @field.countEffect(roomEffect) >= duration
                pbDisplay(_INTL("The {1} stayed the same.", effectName)) unless aiCheck
                return 0
            elsif aiCheck
                return (duration - @field.countEffect(roomEffect)) * 20
            else
                pbDisplay(_INTL("The {1} was refreshed!", effectName))
                @field.effects[roomEffect] = duration
            end
        elsif aiCheck
            return duration * 20
        else
            @field.applyEffect(roomEffect, duration)
        end

        if aiCheck
            return 0
        else
            moreTurns = duration
            moreTurns -= 1 unless @turnCount == 0
            pbDisplay(_INTL("It'll last for {1} more turns.", moreTurns))
        end
    end
end
