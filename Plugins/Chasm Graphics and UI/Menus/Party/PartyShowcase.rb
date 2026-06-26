class PokemonPartyShowcase_Scene
    POKEMON_ICON_SIZE = 64
    base   = Color.new(80, 80, 88)
    shadow = Color.new(160, 160, 168)

    def initialize(trainer,snapshot: false,snapShotName: nil,fastSnapshot: false, npcTrainer: false, illusionsFool: true, flags: [], startWithIndex: 0, revealStates: nil)
        @trainer = trainer

        @sprites = {}
        @revealStates = revealStates
        # In partial-info mode, revealStates is the source of truth for which Pokémon to show
        # (e.g. previewed-but-unsent ones the trainer's actual battle roster doesn't include
        # yet) - trainer.party alone isn't enough.
        @party = revealStates ? revealStates.map { |state| state.pokemon } : trainer.party.clone
        @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
        @viewport.z = 99999
        @npcTrainer = npcTrainer
        @flags = flags

        if @npcTrainer
            backgroundFileName = "Party/showcase_bg_npc"
        else
            backgroundFileName = "Party/showcase_bg"
            backgroundFileName += "_postgame" if gameWon?
        end
        addBackgroundPlane(@sprites, "bg", backgroundFileName, @viewport)

        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @overlay = @sprites["overlay"].bitmap
        pbSetSmallFont(@overlay)

        @sprites["overlay2"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["overlay2"].z = 99999
        @overlay2 = @sprites["overlay2"].bitmap
        pbSetSmallFont(@overlay2)

        @cursorBitmap = AnimatedBitmap.new(addLanguageSuffix("Graphics/Pictures/Party/cursor_pokemon_showcase"))
        @sprites["pokemonsel"] = SpriteWrapper.new(@viewport)
        @sprites["pokemonsel"].bitmap = @cursorBitmap.bitmap
        @sprites["pokemonsel"].visible = false unless @npcTrainer

        # Fake lead
        if startWithIndex != 0
            @party[0], @party[startWithIndex] = @party[startWithIndex], @party[0]
            @revealStates[0], @revealStates[startWithIndex] = @revealStates[startWithIndex], @revealStates[0] if @revealStates
        end

        # Illusion
        if illusionsFool && @party[0].hasAbility?(%i[ILLUSION INCOGNITO])
            lastIndex = @party.length - 1
            @party[0], @party[lastIndex] = @party[lastIndex], @party[0]
            @revealStates[0], @revealStates[lastIndex] = @revealStates[lastIndex], @revealStates[0] if @revealStates
        end

        drawPartyShowcase

        pbFadeInAndShow(@sprites) { pbUpdate }

        pbScreenCapture(snapShotName, !fastSnapshot) if snapshot

        @selectedIndex = 0

        loop do
            Graphics.update
            Input.update
            pbUpdate

            if Input.trigger?(Input::BACK) || fastSnapshot
                pbEndScene
                pbPlayCloseMenuSE
                return
            end

            if @npcTrainer
                if Input.trigger?(Input::USE)
                    selectedPokemon = @party[@selectedIndex]
                    selectedRevealState = @revealStates ? @revealStates[@selectedIndex] : PokeXRayRevealState.full(selectedPokemon)
                    # Only ever the ones whose ID is in selectedRevealState's known list - in
                    # full-info mode that's every item the Pokémon actually holds, same as before.
                    knownItems = selectedPokemon.items.select { |item| selectedRevealState.item_known?(item) }

                    showMasterDexCommand = -1
                    showMovesCommand = -1
                    showItemCommand = -1
                    commands = []
                    commands[showMasterDexCommand = commands.length] = _INTL("View MasterDex")
                    # View Moves opens the real full summary screen (true moveset/IVs/EVs/
                    # ability) - that's fine once everything's visible anyway, but would leak
                    # real data past what's been revealed in partial-info mode, so drop it there.
                    commands[showMovesCommand = commands.length] = _INTL("View Moves") unless @revealStates
                    unless knownItems.empty?
                        if knownItems.length > 1
                            commands[showItemCommand = commands.length] = _INTL("View Items")
                        else
                            commands[showItemCommand = commands.length] = _INTL("View Item")
                        end
                    end
                    commands[commands.length] = _INTL("Cancel")

                    commandChoice = pbMessage(_INTL("View which information?"),commands,commands.length)

                    if showMasterDexCommand > -1 && commandChoice == showMasterDexCommand
                        $Trainer.pokedex.set_last_form_seen(selectedPokemon.species, 0, selectedPokemon.form)
						openSingleDexScreen(selectedPokemon.species)
                    elsif showMovesCommand > -1 && commandChoice == showMovesCommand
                        showExternalSummary(selectedPokemon)
                    elsif showItemCommand > -1 && commandChoice == showItemCommand
                        if knownItems.length > 1
                            itemNames = []
                            knownItems.each do |itemID|
                                itemNames.push(getItemName(itemID))
                            end
                            itemNames[itemNames.length] = _INTL("Cancel")
                            chosenItemIndex = pbMessage(_INTL("View which item?"),itemNames,itemNames.length)
                            if chosenItemIndex < itemNames.length - 1
                                item = knownItems[chosenItemIndex]
                                showItemDescriptionMessage(item)
                            end
                        else
                            item = knownItems[0]
                            showItemDescriptionMessage(item)
                        end
                    end
                elsif Input.trigger?(Input::DOWN)
                    @selectedIndex += 2
                    if @selectedIndex >= @party.length
                        if @selectedIndex % 2 == 1 && @party.length > 1
                            @selectedIndex = 1
                        else
                            @selectedIndex = 0
                        end
                    end
                    pbPlayCursorSE
                elsif Input.trigger?(Input::UP)
                    @selectedIndex -= 2
                    if @selectedIndex < 0
                        if @party.length % 2 == 0
                            if @selectedIndex % 2 == 0
                                @selectedIndex = @party.length - 2
                            else
                                @selectedIndex = @party.length - 1
                            end
                        else
                            if @selectedIndex % 2 == 0
                                @selectedIndex = @party.length - 1
                            else
                                @selectedIndex = @party.length - 2
                            end
                        end
                    end
                    pbPlayCursorSE
                elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
                    newIndex = @selectedIndex + (@selectedIndex % 2 == 0 ? 1 : -1)
                    if newIndex < @party.length
                        @selectedIndex = newIndex
                        pbPlayCursorSE
                    else
                        pbPlayBuzzerSE
                    end
                end
                @sprites["pokemonsel"].x = 256 * (@selectedIndex % 2)
                @sprites["pokemonsel"].y = 122 * (@selectedIndex / 2)
            end
        end
    end
    
    def drawPartyShowcase
        base = MessageConfig::DARK_TEXT_MAIN_COLOR
        shadow = MessageConfig::DARK_TEXT_SHADOW_COLOR

        # Add party Pokémon sprites
        for i in 0...Settings::MAX_PARTY_SIZE
            next unless @party[i]
            renderShowcaseInfo(i,@party[i],@revealStates ? @revealStates[i] : nil)
        end

        bottomBarY = Graphics.height - 20

        # Draw tribal bonus info at the bottom
        pbDrawImagePositions(@overlay,[["Graphics/Pictures/icon_tribal_bonus",4,bottomBarY-4]])

        @trainer.tribalBonus.updateTribeCount
        bonusesList = @trainer.tribalBonus.getActiveBonusesList(false)
        tribesTotal = GameData::Tribe.legal_tribes_count
        fullDescription = ""
        if bonusesList.empty?
            fullDescription = _INTL("None")
        elsif bonusesList.length == tribesTotal
            fullDescription = _INTL("All")
        elsif bonusesList.length <= 2
            bonusesList.each_with_index do |label,index|
                fullDescription += "," unless index == 0
                fullDescription += label
            end
        else
            fullDescription = bonusesList.length.to_s
        end

        drawFormattedTextEx(@overlay, 32, bottomBarY, Graphics.width, fullDescription, base, shadow)

        # Show trainer name
        if @npcTrainer
            playtesterSubmitted = nil
            @trainer.flags.each do |flag|
                match = flag.match(/PlayerTeam\:(.+)/)
                next unless match
                playtesterSubmitted = match[1]
                break
            end
            if playtesterSubmitted
                playerName = _INTL("Team Submitted by {1}", playtesterSubmitted)
            else
                playerName = "<ar>#{@trainer.full_name}</ar>"  
            end
            drawFormattedTextEx(@overlay, Graphics.width - 304, bottomBarY, 300, playerName, base, shadow)
        elsif $Options.name_on_showcases != 1
            playerName = "<ar>#{@trainer.name}</ar>"
            drawFormattedTextEx(@overlay, Graphics.width - 164, bottomBarY, 160, playerName, base, shadow)
        end

        unless @npcTrainer
            # Show game version
            settingsLabel = "v#{Settings::GAME_VERSION}"
            settingsLabel += "-dev" if Settings::DEV_VERSION
            drawFormattedTextEx(@overlay, Graphics.width / 2 + 60, bottomBarY, 160, settingsLabel, base, shadow)

            numIcons = 0
            numIcons += 1 if Randomizer.on?
            numIcons += 1 if @flags.include?("cursed")
            numIcons += 1 if @flags.include?("perfect")

            # Show randomizer icon
            distanceBetweenIcons = 28
            bottomIconX = Graphics.width / 2 - (numIcons * distanceBetweenIcons) / 2
            if Randomizer.on?
                pbDrawImagePositions(@overlay,[["Graphics/Pictures/Party/icon_randomizer",bottomIconX,bottomBarY-4]])
                bottomIconX += distanceBetweenIcons
            end

            # Show cursed icon
            if @flags.include?("cursed")
                pbDrawImagePositions(@overlay,[["Graphics/Pictures/Party/icon_cursed",bottomIconX+2,bottomBarY-4]])
                bottomIconX += distanceBetweenIcons
            end

            # Show perfect icon
            if @flags.include?("perfect")
                pbDrawImagePositions(@overlay,[["Graphics/Pictures/Party/icon_perfect",bottomIconX,bottomBarY-4]])
                bottomIconX += distanceBetweenIcons
            end
        end
    end

    def showExternalSummary(pokemon)
        oldsprites = pbFadeOutAndHide(@sprites)
        scene = PokemonSummary_Scene.new
        screen = PokemonSummaryScreen.new(scene)
        screen.pbStartSingleExternalScene(pokemon)
        pbFadeInAndShow(@sprites,oldsprites)
    end

    MAX_MOVE_NAME_WIDTH = 140

    def renderShowcaseInfo(index,pokemon,revealState = nil)
        # Full info for offline showcases/the original overworld X-Ray - revealState only
        # narrows things down for the online Poké X-Ray's note-taking mode (issue #475).
        partialInfo = !revealState.nil?
        revealState ||= PokeXRayRevealState.full(pokemon)

        base = MessageConfig::DARK_TEXT_MAIN_COLOR
        shadow = MessageConfig::DARK_TEXT_SHADOW_COLOR

        displayX = ((index % 2) * (Graphics.width / 2)) + 6
        displayY = (index / 2) * (Graphics.height / 3 - 8) + 6

        mainIconY = displayY + 20
        newPokemonIcon = PokemonIconSprite.new(pokemon,@viewport)
        newPokemonIcon.x = displayX
        newPokemonIcon.y = mainIconY
        @sprites["pokemon#{index}"] = newPokemonIcon

        # Display status
        if @flags.include?("showstatuses")
            statusImageIndex = pokemon.getStatusImageIndex(true)
            if statusImageIndex >= 0
                imagepos = [[addLanguageSuffix("Graphics/Pictures/statuses"), displayX + 10, mainIconY + 4, 0, 16 * statusImageIndex, 44, 16]]
                pbDrawImagePositions(@overlay2, imagepos)
            end
        end

        # Display pokemon name and level - level isn't shown until actually seen, since team
        # preview alone doesn't reveal it (only the in-battle HUD does, once sent out)
        nameAndLevel = revealState.seen? ? _INTL("#{pokemon.name} Lv. #{pokemon.level.to_s}") : pokemon.name
        drawTextEx(@overlay, displayX + 4, displayY, 200, 1, nameAndLevel, base, shadow)

        # Display gender - visible as soon as the Pokémon is known at all (previewed or seen)
        genderX = displayX + 196
        genderY = displayY
        if pokemon.male?
            drawTextEx(@overlay, genderX, genderY, 80, 1, _INTL("♂"), Color.new(0,112,248), Color.new(120,184,232))
        elsif pokemon.female?
            drawTextEx(@overlay, genderX, genderY, 80, 1, _INTL("♀"), Color.new(232,32,16), Color.new(248,168,184))
        end

        if revealState.not_brought?
            # Nothing more can ever be revealed about a Pokémon ruled out this way - say so
            # plainly instead of leaving the rest of the row full of "???"s that imply it
            # might still show up.
            drawTextEx(@overlay, displayX + 4, mainIconY + POKEMON_ICON_SIZE + 8, 200, 1, _INTL("Not Brought"), base, shadow)
            return
        end

        # Display item icon(s) - a real, unrevealed item shows as "???" rather than nothing,
        # so it's clear there's something to learn there rather than no item at all
        if pokemon.hasItem?
            pixelsBetweenItems = 20
            itemX = displayX + POKEMON_ICON_SIZE - 8 - pixelsBetweenItems * (pokemon.items.length - 1)
            itemY = mainIconY + POKEMON_ICON_SIZE - 8
            pokemon.items.each_with_index do |item, itemIndex|
                if revealState.item_known?(item)
                    newItemIcon = ItemIconSprite.new(itemX,itemY,item,@viewport)
                    newItemIcon.zoom_x = 0.5
                    newItemIcon.zoom_y = 0.5
                    newItemIcon.type = pokemon.itemTypeChosen
                    @sprites["item_#{index}_#{itemIndex}"] = newItemIcon
                else
                    drawTextEx(@overlay, itemX - 8, itemY - 4, 40, 1, _INTL("???"), base, shadow)
                end

                itemX += pixelsBetweenItems
            end
        end

        unless @npcTrainer
            # Display ball caught in icon
            newItemIcon = ItemIconSprite.new(displayX + 200,mainIconY + POKEMON_ICON_SIZE + 16,pokemon.poke_ball,@viewport)
            newItemIcon.zoom_x = 0.5
            newItemIcon.zoom_y = 0.5
            @sprites["ball_#{index}"] = newItemIcon
        end

        # Draw shiny icon - not visible until actually sent out, same as level
        if revealState.seen? && pokemon.shiny?
            shinyIconFileName = pokemon.shiny_variant? ? "Graphics/Pictures/shiny_variant" : "Graphics/Pictures/shiny"
            pbDrawImagePositions(@overlay,[[shinyIconFileName,displayX,mainIconY,0,0,16,16]])
        end

        # Display moves (including any curse extra moves), "???" for any not yet revealed
        displayMoveIDs = pokemon.moves.map { |pokemonMove| pokemonMove.id }
        displayMoveIDs += pokemon.extraMoves if pokemon.hasExtraMoves?
        # In partial-info mode, always pad up to the full 4 move slots with placeholders -
        # otherwise a Pokémon with fewer than 4 actual moves would show fewer "???" rows,
        # leaking its true move count even though that's never actually been revealed.
        if partialInfo && displayMoveIDs.length < 4
            displayMoveIDs += [nil] * (4 - displayMoveIDs.length)
        end
        # Normally rows are 16px apart starting at +2. When extra moves push the count past
        # the usual 4, start a little higher (just under the name) and spread the rows down to
        # just above the ability label, using the whole available band without overlapping the
        # top (name) or bottom (ability) text.
        if displayMoveIDs.length > 4
            moveTopOffset = -4                              # start just under the name
            moveBottomRowOffset = POKEMON_ICON_SIZE - 8     # 56: last row stays clear of the ability label (+72)
            moveLineHeight = [(moveBottomRowOffset - moveTopOffset) / (displayMoveIDs.length - 1), 16].min
        else
            moveTopOffset = 2
            moveLineHeight = 16
        end
        displayMoveIDs.each_with_index do |displayMoveID,moveIndex|
            moveName = revealState.move_known?(displayMoveID) ? GameData::Move.get(displayMoveID).name : _INTL("???")
            expectedMoveNameWidth = @overlay.text_size(moveName).width
            if expectedMoveNameWidth > MAX_MOVE_NAME_WIDTH
                charactersToShave = 3
                loop do
                    testString = moveName[0..-charactersToShave] + "..."
                    expectedTestStringWidth = @overlay.text_size(testString).width
                    excessWidth = expectedTestStringWidth - MAX_MOVE_NAME_WIDTH
                    break if excessWidth <= 0
                    charactersToShave += 1
                end
                shavedName = moveName[0..-charactersToShave]
                shavedName = shavedName[0..-1] if shavedName[shavedName.length-1] == " "
                moveName = shavedName + "..."
            end
            drawTextEx(@overlay, displayX + POKEMON_ICON_SIZE + 8, mainIconY + moveTopOffset + moveIndex * moveLineHeight, 200, 1, moveName, base, shadow)
        end

        # Display ability name
        if @trainer.policies.include?(:CURSE_DOUBLE_ABILITIES)
            abilityNameLabel = ""
            legalAbilityCount = pokemon.species_data.legalAbilities.length
            pokemon.species_data.legalAbilities.each_with_index do |legalAbilityID, index|
                abilityNameLabel += GameData::Ability.get(legalAbilityID).name
                abilityNameLabel += ", " unless index == legalAbilityCount - 1
            end
            @overlay.font.size = 20
        elsif pokemon.ability.nil?
            abilityNameLabel = _INTL("No Ability")
        elsif !revealState.ability_known?(pokemon.ability_id)
            abilityNameLabel = _INTL("???")
        else
            abilityNameLabel = pokemon.ability.name
            if pokemon.hasExtraAbilities?
                pokemon.extraAbilities.each do |extraAbilityID|
                    abilityNameLabel += ", "
                    abilityNameLabel += revealState.ability_known?(extraAbilityID) ? GameData::Ability.get(extraAbilityID).name : _INTL("???")
                end
                @overlay.font.size = 20
            end
        end
        drawTextEx(@overlay, displayX + 4, mainIconY + POKEMON_ICON_SIZE + 8, 200, 1, abilityNameLabel, base, shadow)
        pbSetSmallFont(@overlay)

        # Display Style Points - only once actually seen. They're arithmetically derivable
        # from the in-battle stat screen once a Pokémon's level/stats have been shown, so
        # this isn't holding back anything a real opponent couldn't already work out by hand.
        return unless revealState.seen?
        styleValueX = displayX + 222
        styleHash = pokemon.ev
        styleValues = [styleHash[:HP],styleHash[:ATTACK],styleHash[:DEFENSE],styleHash[:SPECIAL_ATTACK],styleHash[:SPECIAL_DEFENSE],styleHash[:SPEED]]
        styleValues.each_with_index do |styleValue,styleIndex|
            #styleOpacity = (0.5 + styleValue / 40.0) * 255
            thisColor = base.clone
            thisColor.alpha = 120 if styleValue == 0
            thisShadow = shadow.clone
            thisShadow.alpha = 120 if styleValue == 0
            drawTextEx(@overlay, styleValueX, 2 + displayY + 18 * styleIndex, 80, 1, styleValue.to_s, thisColor, thisShadow)
        end
    end

    # End the scene here
    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        # DISPOSE OF BITMAPS HERE #
        @cursorBitmap.dispose
    end

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end
end

def enemyTrainerShowcase(trainerClass,trainerName,version=0, illusionsFool: false)
    trainer = pbLoadTrainer(trainerClass,trainerName,version)
    trainerShowcase(trainer, npcTrainer: true, illusionsFool: illusionsFool)
end

def trainerShowcase(trainer, npcTrainer: false, illusionsFool: false, flags: [], startWithIndex: 0, revealStates: nil)
    pbFadeOutIn {
        PokemonPartyShowcase_Scene.new(trainer, npcTrainer: npcTrainer, illusionsFool: illusionsFool, flags: flags, startWithIndex: startWithIndex, revealStates: revealStates)
    }
end

def createVisualTrainerDocumentation
    GameData::Trainer.each do |trainerData|
        trainer = pbLoadTrainer(trainerData.trainer_type,trainerData.name,trainerData.version)
        screenshotName = "#{trainerData.trainer_type} #{trainerData.name}"
        screenshotName += " (#{trainerData.version})" if trainerData.version > 0
        screenshotName += " "
        PokemonPartyShowcase_Scene.new(trainer,snapshot: true,snapShotName: screenshotName,fastSnapshot: true, npcTrainer: true)
    end
end