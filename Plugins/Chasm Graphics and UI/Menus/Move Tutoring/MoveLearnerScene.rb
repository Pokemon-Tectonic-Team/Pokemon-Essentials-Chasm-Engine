#===============================================================================
# Scene class for handling appearance of the screen
#===============================================================================
class MoveLearner_Scene
    include MoveInfoDisplay

    VISIBLEMOVES = 5
    MOVE_ENTRY_HEIGHT = 40
    SIGNATURE_COLOR = Color.new(211, 175, 44)

    def pbDisplay(msg, brief = false)
        UIHelper.pbDisplay(@sprites["msgwindow"], msg, brief) { pbUpdate }
    end

    def pbConfirm(msg)
        UIHelper.pbConfirm(@sprites["msgwindow"], msg) { pbUpdate }
    end

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end

    def pbStartScene(pokemon, movesProc)
        @pokemon = pokemon
        @movesProc = movesProc

        @tabSelected = 0

        regenerateMoveList

        # Create sprite hash
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        @sprites = {}
        bg_path = "Move Tutor/reminderbg"
        bg_path += "_dark" if darkMode?
        addBackgroundPlane(@sprites, "bg", bg_path, @viewport)
        @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
        @sprites["pokeicon"].setOffset(PictureOrigin::Center)
        @sprites["pokeicon"].x = 312
        @sprites["pokeicon"].y = 58
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        sel_path = "Graphics/Pictures/Move Tutor/reminderSel"
        sel_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(sel_path)
        @sprites["background"].y = 74
        @sprites["background"].src_rect = Rect.new(0, 48, 254, 48)
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetSystemFont(@sprites["overlay"].bitmap)
        @sprites["commands"] = Window_CommandPokemon.new(@moveCommands[@tabSelected], 32)
        @sprites["commands"].height = 32 * (VISIBLEMOVES + 1)
        @sprites["commands"].visible = false
        @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
        @sprites["msgwindow"].visible = false
        @sprites["msgwindow"].viewport = @viewport
        @typebitmap = AnimatedBitmap.new(addLanguageSuffix("Graphics/Pictures/types"))

        # Create the left and right arrow sprites which surround the selected index
        @index = 0
        @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow", 8, 40, 28, 2, @viewport)
        @sprites["leftarrow"].x       = 26 + 2
        @sprites["leftarrow"].y       = 30
        @sprites["leftarrow"].play
        @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow", 8, 40, 28, 2, @viewport)
        @sprites["rightarrow"].x       = 26 + 158
        @sprites["rightarrow"].y       = 30
        @sprites["rightarrow"].play

        # Create overlay for selected move's extra info (shows move's BP, description)
        move_path = "Graphics/Pictures/move_info_display_backwards_l"
        move_path += "_dark" if darkMode?
        @moveInfoDisplayBitmap = AnimatedBitmap.new(_INTL(move_path))
        @moveInfoDisplay = SpriteWrapper.new(@viewport)
        @moveInfoDisplay.bitmap = @moveInfoDisplayBitmap.bitmap
        @sprites["moveInfoDisplay"] = @moveInfoDisplay
        @extraInfoOverlay = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetNarrowFont(@extraInfoOverlay.bitmap)
        @sprites["extraInfoOverlay"] = @extraInfoOverlay

        pbDrawMoveList
        pbDeactivateWindows(@sprites)
        # Fade in all sprites
        pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def regenerateMoveList
        unsortedMoves = @movesProc.call(@pokemon)

        speciesData = @pokemon.species_data

        # Sorts moves first by base power (descending)
        # Then by whether or not they are STAB (STAB moves go first)
        # Then by type ID
        unsortedMoves.sort! { |move_a, move_b|
            moveDataA = GameData::Move.get(move_a)
            moveDataB = GameData::Move.get(move_b)

            if moveDataA.base_damage == moveDataB.base_damage
                if speciesData.hasType?(moveDataA.type) == speciesData.hasType?(moveDataB.type) # Both STAB or both not STAB
                    next GameData::Type.get(moveDataA.type).id_number <=> GameData::Type.get(moveDataB.type).id_number
                elsif speciesData.hasType?(moveDataA.type)
                    next -1
                else
                    next 1
                end
            else
                next moveDataB.base_damage <=> moveDataA.base_damage
            end
        }

        @moves = [[],[],[]] # An array for each category
        @moveCommands = [[],[],[]]
        unsortedMoves.each do |m|
            moveData = GameData::Move.get(m)
            category = moveData.category

            if category == 0 || category == 3 # Physical or adaptive
                @moves[0].push(m)
                @moveCommands[0].push(moveData.name)
            end

            if category == 1 || category == 3 # Special or adaptive
                @moves[1].push(m)
                @moveCommands[1].push(moveData.name)
            end

            if category == 2 # Status
                @moves[2].push(m)
                @moveCommands[2].push(moveData.name)
            end
        end
    end

    def refreshMoveList
        @sprites["commands"].commands = @moveCommands[@tabSelected]
        @sprites["commands"].index = 0

        setReminderSelPosition
        pbDrawMoveList
    end

    def setReminderSelPosition
        @sprites["background"].visible = @moveCommands[@tabSelected].length > 0
        @sprites["background"].x = 0
        @sprites["background"].y = 74 + (@sprites["commands"].index - @sprites["commands"].top_item) * MOVE_ENTRY_HEIGHT  
    end

    def pbDrawMoveList
        overlay = @sprites["overlay"].bitmap
        overlay.clear

        base = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor

        textpos = []
        imagepos = []

        # Draw the pokemon's info
        type1_number = GameData::Type.get(@pokemon.type1).id_number
        type2_number = GameData::Type.get(@pokemon.type2).id_number
        type1rect = Rect.new(0, type1_number * 28, 64, 28)
        type2rect = Rect.new(0, type2_number * 28, 64, 28)
        if @pokemon.type1 == @pokemon.type2
            overlay.blt(392, 44, @typebitmap.bitmap, type1rect)
        else
            overlay.blt(358, 44, @typebitmap.bitmap, type1rect)
            overlay.blt(428, 44, @typebitmap.bitmap, type2rect)
        end

        startingYPos = 80
        if @moves[@tabSelected].length > 0
            yPos = startingYPos
            # Draw the selectable move elements
            for i in 0...VISIBLEMOVES
                moveobject = @moves[@tabSelected][@sprites["commands"].top_item + i]
                if moveobject
                    moveData = GameData::Move.get(moveobject)
                    # type_number = GameData::Type.get(moveData.type).id_number
                    # imagepos.push([addLanguageSuffix("Graphics/Pictures/types"), 12, yPos + 8, 0, type_number * 28, 64, 28])
                    formattedName, nameColor, nameShadow = getFormattedMoveName(moveobject)
                    drawFormattedTextEx(overlay, 16, yPos, 450, formattedName, nameColor, nameShadow)
                end
                yPos += MOVE_ENTRY_HEIGHT
            end

            # Draw the selection cursor
            sel_path = "Graphics/Pictures/Move Tutor/reminderSel"
            sel_path += "_dark" if darkMode?
            imagepos.push([sel_path,
                        0, 72 + (@sprites["commands"].index - @sprites["commands"].top_item) * MOVE_ENTRY_HEIGHT, 0, 0, 254, 48,])

            # Draw the selected move
            selectedMoveID = @moves[@tabSelected][@sprites["commands"].index]
            drawMoveInfo(selectedMoveID)
        else
            textpos.push([_INTL("None"), 126, startingYPos-12, 2, base, shadow])
            @extraInfoOverlay.bitmap.clear
        end

        # Draw the currently selected category name
        categoryName = [_INTL("Physical"),_INTL("Special"),_INTL("Status")][@tabSelected]
        textpos.push([categoryName, 126, 20, 2, base, shadow])

        # Actually render everything
        pbDrawImagePositions(overlay, imagepos)
        pbDrawTextPositions(overlay, textpos)
    end

    def drawMoveInfo(selected_move)
        writeMoveInfoToInfoOverlayBackwardsL(@extraInfoOverlay.bitmap, selected_move, false)
    end

    def getFormattedMoveName(move)
        fSpecies = @pokemon.species_data
        move_data = GameData::Move.get(move)
        moveName = move_data.name
    
        if move_data.type == :FLEX
            isSTAB = true
        else
            isSTAB = move_data.category != 2 && [fSpecies.type1, fSpecies.type2].include?(move_data.type)
        end
    
        # Add formatting based on if the move is the same type as the user
        # Or of any of its evolutions
        if isSTAB
            moveName = "<b>#{moveName}</b>"
        elsif move_data.category != 2 && isAnyEvolutionOfType(fSpecies, move_data.type)
            moveName = "<i>#{moveName}</i>"
        end
    
        color = MessageConfig.pbDefaultTextMainColor
        if move_data.is_signature?
            if isSTAB
                moveName = "<outln2>" + moveName + "</outln2>"
            else
                moveName = "<outln>" + moveName + "</outln>"
            end
            shadow = SIGNATURE_COLOR
        else
            shadow = MessageConfig.pbDefaultTextShadowColor
        end
        return moveName, color, shadow
    end

    # Processes the scene
    def pbChooseMove
        oldcmd = -1
        pbActivateWindow(@sprites, "commands") do
            loop do
                oldcmd = @sprites["commands"].index
                Graphics.update
                Input.update
                pbUpdate
                if @sprites["commands"].index != oldcmd
                    setReminderSelPosition
                    pbDrawMoveList
                end
                if Input.trigger?(Input::BACK)
                    return nil
                elsif Input.trigger?(Input::USE)
                    if @moves[@tabSelected].length > 0
                        return @moves[@tabSelected][@sprites["commands"].index]
                    else
                        pbPlayBuzzerSE
                    end
                elsif Input.trigger?(Input::LEFT)
                    @tabSelected -= 1
                    @tabSelected = 2 if @tabSelected < 0
                    refreshMoveList
                    pbPlayCursorSE
                elsif Input.trigger?(Input::RIGHT)
                    @tabSelected += 1
                    @tabSelected = 0 if @tabSelected > 2
                    refreshMoveList
                    pbPlayCursorSE
                elsif Input.trigger?(Input::ACTION)
                    if @moves[@tabSelected].empty?
                        pbMessage(_INTL("Cannot search on an empty tab."))
                        next
                    end
                    inputText = pbEnterText(_INTL("Search for which move?"),0,20).downcase
                    unless inputText.blank?
                        filteredIndex = -1
                        @moves[@tabSelected].each_with_index do |move, index|
                            next unless GameData::Move.get(move).name.downcase.include?(inputText)
                            filteredIndex = index
                            break
                        end

                        if filteredIndex >= 0
                            pbPlayCursorSE
                            @sprites["commands"].index = filteredIndex
                            setReminderSelPosition
                            pbDrawMoveList
                        else
                            pbMessage(_INTL("No matching move was found in this tab."))
                        end
                    end
                end
            end
        end
    end

    # End the scene here
    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        @typebitmap.dispose
        @viewport.dispose
        @moveInfoDisplayBitmap.dispose
    end
end
