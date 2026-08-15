class PokemonRuleSet
  # Returns a deduplicated list of human-readable reasons why no combination
  # of [minTeamLength, maxTeamLength] Pokemon from the list can satisfy this
  # ruleset, by re-running validityErrors (which already collects every
  # issue, not just the first) over every combination hasValidTeam? tried.
  # hasValidTeam? only returns a boolean, so without this a rejected team
  # gives the player no clue why.
  def registrationErrors(list)
    return [_INTL("Choose a Pokémon.")] if !list || list.length < self.minTeamLength
    errors = []
    (self.minTeamLength..self.maxTeamLength).each do |x|
      pbEachCombination(list,x){|comb|
        errors.concat(validityErrors(comb))
      }
    end
    return errors.uniq
  end
end

class PokemonPartyScreen
  def pbPokemonMultipleEntryScreenOrder(ruleset)
    annot = []
    statuses = []
    ordinals = [
       _INTL("INELIGIBLE"),
       _INTL("NOT ENTERED"),
       _INTL("BANNED"),
       _INTL("FIRST"),
       _INTL("SECOND"),
       _INTL("THIRD"),
       _INTL("FOURTH"),
       _INTL("FIFTH"),
       _INTL("SIXTH")
    ]
    if !ruleset.hasValidTeam?(@party)
      errors = ruleset.registrationErrors(@party)
      pbDisplay(_INTL("I'm sorry, you do not have a valid Pokémon team with these rules."))
      pbMessage("Issues:\n" + errors.map { |e| "- #{e}" }.join("\n")) unless errors.empty?
      return nil
    end
    ret = nil
    addedEntry = false
    for i in 0...@party.length
      statuses[i] = (ruleset.isPokemonValid?(@party[i])) ? 1 : 2
    end
    for i in 0...@party.length
      annot[i] = ordinals[statuses[i]]
    end
    @scene.pbStartScene(@party,_INTL("Choose Pokémon and confirm."),annot,true)
    loop do
      realorder = []
      for i in 0...@party.length
        for j in 0...@party.length
          if statuses[j]==i+3
            realorder.push(j)
            break
          end
        end
      end
      for i in 0...realorder.length
        statuses[realorder[i]] = i+3
      end
      for i in 0...@party.length
        annot[i] = ordinals[statuses[i]]
      end
      @scene.pbAnnotate(annot)
      if realorder.length==ruleset.number && addedEntry
        @scene.pbSelect(6)
      end
      @scene.pbSetHelpText(_INTL("Choose Pokémon and confirm."))
      pkmnid = @scene.pbChoosePokemon
      addedEntry = false
      if pkmnid==6 # Confirm was chosen
        ret = []
        test_ret = []
        for i in realorder
          ret.push(i)
          test_ret.push(@party[i])
        end
        break if ruleset.isValid?(test_ret)
        errors = ruleset.validityErrors(test_ret)
        pbDisplay(_INTL("I'm sorry, this team isn't allowed."))
        pbMessage("Issues:\n" + errors.map { |e| "- #{e}" }.join("\n")) unless errors.empty?
        ret = nil
        test_ret = nil
      end
      break if pkmnid<0 # Canceled
      cmdEntry   = -1
      cmdNoEntry = -1
      cmdSummary = -1
      commands = []
      if (statuses[pkmnid] || 0) == 1
        commands[cmdEntry = commands.length]   = _INTL("Entry")
      elsif (statuses[pkmnid] || 0) > 2
        commands[cmdNoEntry = commands.length] = _INTL("No Entry")
      end
      pkmn = @party[pkmnid]
      commands[cmdSummary = commands.length]   = _INTL("Summary")
      commands[commands.length]                = _INTL("Cancel")
      command = @scene.pbShowCommands(_INTL("Do what with {1}?",pkmn.name),commands) if pkmn
      if cmdEntry>=0 && command==cmdEntry
        if realorder.length>=ruleset.number && ruleset.number>0
          pbDisplay(_INTL("No more than {1} Pokémon may enter.",ruleset.number))
        else
          statuses[pkmnid] = realorder.length+3
          addedEntry = true
          pbRefreshSingle(pkmnid)
        end
      elsif cmdNoEntry>=0 && command==cmdNoEntry
        statuses[pkmnid] = 1
        pbRefreshSingle(pkmnid)
      elsif cmdSummary>=0 && command==cmdSummary
        @scene.pbSummary(pkmnid)
      end
    end
    @scene.pbEndScene
    return ret
  end
end