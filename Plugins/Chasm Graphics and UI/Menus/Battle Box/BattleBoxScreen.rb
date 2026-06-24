#===============================================================================
# Battle Box mechanics
#===============================================================================
class BattleBoxScreen
    attr_reader :scene
    attr_reader :storage
    attr_accessor :currentBoxIndex
    attr_accessor :selectedToMove

    def initialize(scene, storage)
        @scene = scene
        @storage = storage
        @currentBoxIndex = 0
        @selectedToMove = -1
    end

    def currentBox
        return @storage[@currentBoxIndex]
    end

    def pbStartScreen(ableProc = nil)
        @scene.pbStartBox(self)
        loop do
            selected = @scene.pbSelectParty
            break if selected == nil
            pbInteractWithTeam(*selected)
        end
        @scene.pbCloseBox
    end

    def pbUpdate # For debug
        @scene.update
    end

    def pbHardRefresh # For debug
        @scene.pbHardRefresh
    end

    def pbRefreshSingle(i) # For debug
        @scene.pbHardRefresh
    end

    def pbInteractWithTeam(team, teamIndex)
        if @selectedToMove == -1
            cmds = []
            use_cmd = -1
            showcase_cmd = -1
            edit_cmd = -1
            move_cmd = -1
            rename_cmd = -1
            cmds[use_cmd = cmds.size] = _INTL("Use")
            cmds[showcase_cmd = cmds.size] = _INTL("Showcase")
            cmds[edit_cmd = cmds.size] = _INTL("Edit")
            cmds[move_cmd = cmds.size] = _INTL("Move")
            cmds[rename_cmd = cmds.size] = _INTL("Rename")
            result = pbShowCommands(_INTL("What do you want to do with this team ?"), cmds)
            case result
            when -1
                return
            when use_cmd
                pbChangePartyIntoTeam(team)
            when showcase_cmd
                dummy_trainer = NPCTrainer.new(self.currentBox.teamnames[teamIndex], $Trainer.trainer_type)
                dummy_trainer.party = team
                pbFadeOutIn {
                    PokemonPartyShowcase_Scene.new(dummy_trainer, npcTrainer: true, illusionsFool: false, flags: ["notrainertype"])
                }
            when edit_cmd
                pbDisplay("Not implemented yet.")
            when move_cmd
                @selectedToMove = teamIndex
                @scene.selectedToMove = teamIndex
            when rename_cmd
                rename = pbEnterText(_INTL("Team name..."),1,24)
                self.currentBox.setTeamName(teamIndex, rename) if rename
            end
        else
            self.currentBox.pbMove(@selectedToMove, teamIndex)
            @selectedToMove = -1
            @scene.selectedToMove = -1
            @scene.pbUpdateBox
        end
        @scene.update
        @scene.pbRefresh
    end

    def pbDisplay(message)
        @scene.pbDisplay(message)
    end

    def pbConfirm(str)
        return @scene.pbConfirm(str)
    end

    def pbShowCommands(msg, commands, index = 0)
        return @scene.pbShowCommands(msg, commands, index)
    end

    def pbChangePartyIntoTeam(team)
        originalTeam = $Trainer.party.deep_clone
        teamIssues = []
        tempTeam = []
        begin
            #Search for Pokémon
            for i in 0...team.size()
                matchingPartyMon = (0...$Trainer.party.size).select { |j| $Trainer.party[j].species == team[i].species }[0]
                unless matchingPartyMon.nil?
                    tempTeam.push($Trainer.party.delete_at(matchingPartyMon))
                else
                    matchingPCPokemon = $PokemonStorage.pbSearch(team[i].speciesName, 2)
                    if matchingPCPokemon[1]
                        matchingPCPokemon = matchingPCPokemon[0]
                        matchingPCPokemon.map! {|val| [$PokemonStorage[val[0], val[1]], val]}
                        matchingPCPokemon.sort! {|a, b| b[0].level <=> a[0].level} #Prioritize higher-level Pokémon
                        tempTeam.push(matchingPCPokemon[0][0])
                        $PokemonStorage.pbDelete(matchingPCPokemon[0][1][0], matchingPCPokemon[0][1][1])
                    else 
                        teamIssues.push("Couldn't find a #{GameData::Species.try_get(team[i].species).full_name} in your boxes or party.")
                    end
                end
                tempTeam[i] = tempTeam[i] #If no element has been pushed, make it nil
            end

            # Moves
            unless $PokemonGlobal.omnitutor_active
                teamIssues.push("Couldn't alter the Pokémon's moves. Proprietary OmniTutor™ software is required.")
            else
                tempTeam.each_with_index do |pkmn, i|
                    next if pkmn.nil?
                    for j in 0...4
                        if getOmniMoves(pkmn).include?(team[i].moves[j])
                            pkmn.moves[j] = team[i].moves[j]
                        else
                            teamIssues.push("#{pkmn.name} cannot currently learn the move #{team[i].moves[j].name}.")
                        end
                    end
                end
            end

            #Style
            unless pbHasItem?(:STYLINGKIT)
                teamIssues.push("Couldn't alter the Pokémon's styles. A Styling Kit is required.")
            else
                tempTeam.each_with_index do |pkmn, i|
                    next if pkmn.nil?
                    pkmn.ev = team[i].ev
                end
            end

            #Abilities
            abilitiesToChange = []
            tempTeam.each_with_index do |pkmn, i|
                next if pkmn.nil?
                next if pkmn.ability_index == team[i].ability_index
                abilitiesToChange.push(i)
            end
            canChangeAbilities = false
            canChangeAbilities = true if pbHasItem?(:VIRALHELIX)
            if !canChangeAbilities && abilitiesToChange.size > 0
                abilityCapsulesCount = pbQuantity(:ABILITYCAPSULE)
                if abilityCapsulesCount >= abilitiesToChange.size
                    canChangeAbilities = true if pbConfirm("Use #{abilitiesToChange.size} Ability Capsules to change this team's abilities ? You have #{abilityCapsulesCount}.")
                else
                    teamIssues.push("You do not have enough Ability Capsules to change all your team Pokémon's abilities.")
                end
            end
            if canChangeAbilities
                tempTeam.each_with_index do |pkmn, i|
                    next if pkmn.nil?
                    pkmn.ability_index = team[i].ability_index
                end
            end

            #Forms
            formChangesFormalizable = []
            formChangesNonFormalizable = []
            tempTeam.each_with_index do |pkmn, i|
                next if pkmn.nil?
                next if pkmn.form == team[i].form
                if GameData::Species.try_get(pkmn.species).formalizer.include?(team[i].form)
                    formChangesFormalizable.push(i)
                else
                    formChangesNonFormalizable.push(i)
                end
            end
            end
            unless formChangesNonFormalizable.empty?
                teamIssues.push("Couldn't change the following Pokémon's forms : #{formChangesNonFormalizable.map { |i| team[i].name}.join(", ")}")
            end
            unless formChangesFormalizable.empty?
                unless pbHasItem?(:UNIVERSALFORMALIZER)
                    teamIssues.push("Couldn't change the following Pokémon's forms : #{formChangesNonFormalizable.map { |i| team[i].name}.join(", ")}. Universal Formalizer hardware is required.")
                else 
                    formChangesFormalizable.each do |i|
                        tempTeam[i].form = team[i].form
                    end
                end
            end

            #Display team issues
            if !(teamIssues.empty?) && pbConfirm("View team issues ?")
                teamIssues.each { |msg| pbDisplay("- #{msg}") }
            end

        rescue => e
            pbDisplay("An error occured during the team's formation. Your Pokémon will be put back to their respective boxes.")
            $Trainer.party = originalTeam
            tempTeam.each { |pkmn| $PokemonStorage.pbStoreCaught(pkmn) unless pkmn.nil? }
            raise
        else
            # Store party mons and load temp team into party
            unless tempTeam.compact.empty?
                $Trainer.party.each { |pkmn| $PokemonStorage.pbStoreCaught(pkmn) unless pkmn.nil?}
                $Trainer.party = tempTeam
                pbDisplay("The team was loaded into your party.")
                return true
            end
            pbDisplay("Couldn't form a team.")
            return false
        end

end