#===============================================================================
# Powers up the ally's attack this round by 1.5. (Helping Hand)
#===============================================================================
class PokeBattle_Move_PowerUpAllyMove < PokeBattle_HelpingMove
    def initialize(battle, move)
        super
        @helpingEffect = :HelpingHand
    end
end

#===============================================================================
# Powers up the ally's attack this round by making it crit. (Lucky Cheer)
#===============================================================================
class PokeBattle_Move_AllyAttackGuaranteedCrit < PokeBattle_HelpingMove
    def initialize(battle, move)
        super
        @helpingEffect = :LuckyCheer
    end

    def getEffectScore(user, target)
        score = super
        score *= 1.3
        return score
    end
end

#===============================================================================
# Gives an ally an extra move this turn. (Greater Glories)
#===============================================================================
class PokeBattle_Move_AllyGainsExtraMoveThisTurn < PokeBattle_HelpingMove
    def initialize(battle, move)
        super
        @helpingEffect = :GreaterGlories
    end

    def pbFailsAgainstTarget?(_user, target, show_message)
        if target.fainted?
            @battle.pbDisplay(_INTL("But it failed, since the receiver of the help is gone!")) if show_message
            return true
        end
        if target.effectActive?(@helpingEffect)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already being helped!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end
end

#===============================================================================
# Powers up the ally's attack this round by boosting its damage and accuracy by 50%. (Spotting)
#===============================================================================
class PokeBattle_Move_PowerUpAndIncreaseAccOfAllyMove < PokeBattle_HelpingMove
    def initialize(battle, move)
        super
        @helpingEffect = :Spotting
    end

    def getEffectScore(user, target)
        score = super
    end
end

#===============================================================================
# Target is cured of dizziness and gains its other legal ability if it can. (Synaptic Unlock)
#===============================================================================
class PokeBattle_Move_CureDizzyAndUnlockBothAbilities < PokeBattle_HelpingMove
    def pbFailsAgainstTarget?(_user, target, show_message)
        if target.fainted?
            @battle.pbDisplay(_INTL("But it failed, since the receiver of the help is gone!")) if show_message
            return true
        end
        mindUnlocked = true
        target.eachLegalAbility do |legalAbility|
            next if target.ability_ids.include?(legalAbility)
            next if GameData::Ability.get(legalAbility).is_immutable_ability?
            next if target.hasAbility?(legalAbility)
            mindUnlocked = false
            break
        end
        if mindUnlocked && !target.dizzy?
            @battle.pbDisplay(_INTL("But it failed, since {1}'s mind is already unlocked!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        @battle.pbDisplay(_INTL("{1} unlocks the mind of {2}!", user.pbThis, target.pbThis(true)))
        target.pbCureStatus(true, :DIZZY) if target.dizzy?
        target.eachLegalAbility do |legalAbility|
            next if target.ability_ids.include?(legalAbility)
            next if GameData::Ability.get(legalAbility).is_immutable_ability?
            target.addAbility(legalAbility, true)
        end
    end
end