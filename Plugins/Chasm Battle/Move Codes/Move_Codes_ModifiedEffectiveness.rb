#===============================================================================
# Effectiveness against Dragon-type is 2x. (Slay)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstDragon < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :DRAGON
    end
end

#===============================================================================
# Effectiveness against Electric-type is 2x. (Blackout)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstElectric < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :ELECTRIC
    end
end

#===============================================================================
# Effectiveness against Ghost-type is 2x. (Holly Charm)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstGhost < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :GHOST
    end
end

#===============================================================================
# Effectiveness against Fighting-type is 2x. (Spasmic Sting)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstFighting < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :FIGHTING
    end
end

#===============================================================================
# Effectiveness against Fairy-type is 2x. (Dispell)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstFairy < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :FAIRY
    end
end

#===============================================================================
# Effectiveness against Steel-type is 2x.
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstSteel < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :STEEL
    end
end

#===============================================================================
# Effectiveness against Poison-type is 2x.
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstPoison < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :POISON
    end
end

#===============================================================================
# Effectiveness against Normal-type is 2x.
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstNormal < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :NORMAL
    end
end

#===============================================================================
# Effectiveness against Dark-type is 2x.
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstDark < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :DARK
    end
end

#===============================================================================
# Effectiveness against Ground-type is 2x.
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstGround < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :GROUND
    end
end

#===============================================================================
# Effectiveness against Flying-type is 2x.
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstFlying < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :FLYING
    end
end

#===============================================================================
# Effectiveness against Psychic-type is 2x.
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstPsychic < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :PSYCHIC
    end
end

#===============================================================================
# Effectiveness against Steel-type is 1x. (Acid Breach)
#===============================================================================
class PokeBattle_Move_NeutralEffectiveAgainstSteelLowerDef1 < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeNeutral = :STEEL
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        target.tryLowerStat(:DEFENSE, user)
    end
end

#===============================================================================
# Is also Flying-type. (Flying Press)
#===============================================================================
class PokeBattle_Move_AlsoFlyingType < PokeBattle_Move
    def self.extraType; return :FLYING; end
end

#===============================================================================
# Is also Psychic-type. (Leyline Burst)
#===============================================================================
class PokeBattle_Move_AlsoPsychicType < PokeBattle_Move
    def self.extraType; return :PSYCHIC; end
end
