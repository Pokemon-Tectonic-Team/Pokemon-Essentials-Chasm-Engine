class TripleBattle < BattleRule
    def setRule(battle); battle.setBattleMode("triple"); end
end

class PokemonRuleSet
    def hasRegistrableTeam?(list)
        return false if !list || list.length < minTeamLength
        (minTeamLength..maxTeamLength).each do |x|
            pbEachCombination(list, x) { |comb|
                return true if canRegisterTeam?(comb)
            }
        end
        return false
    end

    def hasValidTeam?(team)
        if !team || team.length < minTeamLength
            return false
        end
        validPokemon = []
        for pokemon in team
            if isPokemonValid?(pokemon)
                validPokemon.push(pokemon)
            end
        end
        if validPokemon.length < minLength
            return false
        end
        if @teamRules.length > 0
            (minTeamLength..maxTeamLength).each do |x|
                pbEachCombination(team, x) { |comb|
                    if isValid?(comb)
                        return true
                    end
                }
            end
            return false
        end
        return true
    end
end

class PokemonOnlineRules
    attr_reader :team_preview
    attr_reader :ruleset
    attr_reader :levelAdjustment
    attr_reader :battlerules
    attr_reader :rules_hash

    def initialize
        @team_preview = 0
        @ruleset = ruleset || PokemonRuleSet.new
        @levelAdjustment = nil
        @battlerules = []
        @rules_hash = { :battle => [], :pokemon => [], :subset => [], :team => [], :level_adjust => nil }
    end

    def team_preview?; return @team_preview > 0; end

    def number
        return ruleset.number
    end

    def setNumberRange(minValue, maxValue)
        ruleset.setNumberRange(minValue, maxValue)
        return self
    end

    def setTeamPreview(value)
        @team_preview = value
        return self
    end

    def adjustLevels(party1, party2)
        if @levelAdjustment && @levelAdjustment.type == LevelAdjustment::BothTeams
            return @levelAdjustment.adjustLevels(party1, party2)
        else
            return nil
        end
    end

    def unadjustLevels(party1, party2, adjusts)
        if @levelAdjustment && adjusts && @levelAdjustment.type == LevelAdjustment::BothTeams
            @levelAdjustment.unadjustLevels(party1, party2, adjusts)
        end
    end

    def addPokemonRule(rule, *args)
        saved_args = CableClub.apply_args_type_hint(*args)
        @rules_hash[:pokemon].push([rule, *saved_args])
        ruleset.addPokemonRule(rule.new(*args))
        return self
    end

    def addSubsetRule(rule, *args)
        saved_args = CableClub.apply_args_type_hint(*args)
        @rules_hash[:subset].push([rule, *saved_args])
        ruleset.addSubsetRule(rule.new(*args))
        return self
    end

    def addTeamRule(rule, *args)
        saved_args = CableClub.apply_args_type_hint(*args)
        @rules_hash[:team].push([rule, *saved_args])
        ruleset.addTeamRule(rule.new(*args))
        return self
    end

    def addBattleRule(rule, *args)
        saved_args = CableClub.apply_args_type_hint(*args)
        @rules_hash[:battle].push([rule, *saved_args])
        @battlerules.push(rule.new(*args))
        return self
    end

    def setLevelAdjustment(rule, *args)
        if rule
            saved_args = CableClub.apply_args_type_hint(*args)
            @rules_hash[:level_adjust] = [rule, *saved_args]
            @levelAdjustment = rule.new(*args)
        else
            @rules_hash[:level_adjust] = nil
            @levelAdjustment = nil
        end
        return self
    end

    def applyBattleRules(battle)
        for p in @battlerules
            p.setRule(battle)
        end
    end
end
