class BossViewer_Scene
    include MoveInfoDisplay

    POKEMON_ICON_SIZE = 64
    VISIBLEMOVES = 5
    MOVE_ENTRY_HEIGHT = 40
    PRIMEVAL_COLOR = Color.new(139, 224, 146)

    def initialize(bossSpecies, bossVersion: 0)
        @bossSpecies = bossSpecies
        @boss = GameData::Avatar.get(bossSpecies, bossVersion)
        @phase = 0
        @moveIndex = 0

        @sprites = {}
        @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
        @viewport.z = 99999

        # Add background
        backgroundFileName = "Boss viewer/boss_viewer_bg"
        backgroundFileName += "_dark" if darkMode?
        addBackgroundPlane(@sprites, "bg", backgroundFileName, @viewport)

        # Define main overlays
        @sprites["boss_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @bossInfoOverlay = @sprites["boss_overlay"].bitmap
        pbSetSystemFont(@bossInfoOverlay)

        @sprites["phase_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @phaseInfoOverlay = @sprites["phase_overlay"].bitmap
        pbSetSystemFont(@phaseInfoOverlay)

        @sprites["move_names_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @moveNamesOverlay = @sprites["move_names_overlay"].bitmap
        pbSetSystemFont(@moveNamesOverlay)

        # Define some constants
        @speciesIconX = 16
        @speciesIconY = 0
        @typeX = 132
        @typeY = 8
        @abilityY = 40
        @arrowY = 28
        @phaseNumberY = 28

        # Create the left and right arrow sprites which surround the selected index
        @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow", 8, 40, 28, 2, @viewport)
        @sprites["leftarrow"].x       = 280
        @sprites["leftarrow"].y       = @arrowY
        @sprites["leftarrow"].play
        @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow", 8, 40, 28, 2, @viewport)
        @sprites["rightarrow"].x       = 280 + 180
        @sprites["rightarrow"].y       = @arrowY
        @sprites["rightarrow"].play

        # Create the list of moves to look at
        @sprites["commands"] = Window_CommandPokemon.new(moveListForCurrentPhase, 32)
        @sprites["commands"].height = 32 * (VISIBLEMOVES + 1)
        @sprites["commands"].visible = false

        # Create overlay for selected move's extra info (shows move's BP, description)
        move_path = "Graphics/Pictures/move_info_display_backwards_l"
        move_path += "_dark" if darkMode?
        @moveInfoDisplayBitmap = AnimatedBitmap.new(_INTL(move_path))
        @moveInfoDisplay = SpriteWrapper.new(@viewport)
        @moveInfoDisplay.bitmap = @moveInfoDisplayBitmap.bitmap
        @sprites["moveInfoDisplay"] = @moveInfoDisplay
        @extraInfoOverlay = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["extra_info_overlay"] = @extraInfoOverlay
        pbSetNarrowFont(@extraInfoOverlay.bitmap)

        @typebitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/types")))

        renderBossInfo
        renderPhaseInfo

        pbFadeInAndShow(@sprites) { pbUpdate }

        pbProcessInputs
    end

    MAX_MOVE_NAME_WIDTH = 140

    def renderBossInfo
        base = MessageConfig::DARK_TEXT_MAIN_COLOR
        shadow = MessageConfig::DARK_TEXT_SHADOW_COLOR
        @bossInfoOverlay.clear

        # Add pokemon icon
        @sprites["pokeicon"] = PokemonSpeciesIconSprite.new(@bossSpecies, @viewport)
        @sprites["pokeicon"].x = @speciesIconX
        @sprites["pokeicon"].y = @speciesIconY

        # Draw ability name(s)
        abilityLabel = GameData::Ability.get(@boss.abilities[0]).name
        if @boss.abilities.length > 1
            for abilityIndex in 1..@boss.abilities.length-1
                nextAbilityName = GameData::Ability.get(@boss.abilities[abilityIndex]).name
                abilityLabel = "#{abilityLabel}, #{nextAbilityName}"
            end
            pbSetSmallFont(@bossInfoOverlay)
        end
        drawFormattedTextEx(@bossInfoOverlay, 100, @abilityY, Graphics.width, abilityLabel, base, shadow)
        pbSetSystemFont(@bossInfoOverlay)

        # Draw items
        unless @boss.items.empty?
            pixelsBetweenItems = 20
            itemX = @speciesIconX + POKEMON_ICON_SIZE - 8 - pixelsBetweenItems * (@boss.items.length - 1)
            itemY = @speciesIconY + POKEMON_ICON_SIZE - 8
            @boss.items.each_with_index do |item, itemIndex|
                newItemIcon = ItemIconSprite.new(itemX,itemY,item,@viewport)
                newItemIcon.zoom_x = 0.5
                newItemIcon.zoom_y = 0.5
                @sprites["item_#{itemIndex}"] = newItemIcon

                itemX += pixelsBetweenItems
            end
        end
    end

    def renderPhaseInfo
        base = MessageConfig::DARK_TEXT_MAIN_COLOR
        shadow = MessageConfig::DARK_TEXT_SHADOW_COLOR
        @phaseInfoOverlay.clear

        # Draw Pokémon type(s)
        if @phase == 0
            bossSpeciesData = GameData::Species.get(@bossSpecies)
            type1_number = GameData::Type.get(bossSpeciesData.type1).id_number

            unless bossSpeciesData.type1 == bossSpeciesData.type2
                type2_number = GameData::Type.get(bossSpeciesData.type2).id_number
            end
        else
            types = @boss.getTypeForPhase(@phase)
            if types.is_a?(Array)
                type1_number = GameData::Type.get(types[0]).id_number
                type2_number = GameData::Type.get(types[1]).id_number
            else
                type1_number = GameData::Type.get(types).id_number
            end
        end
        type1rect = Rect.new(0, type1_number * 28, 64, 28)
        
        if type2_number
            type2rect = Rect.new(0, type2_number * 28, 64, 28)

            @phaseInfoOverlay.blt(@typeX, @typeY, @typebitmap.bitmap, type1rect)
            @phaseInfoOverlay.blt(@typeX + 66, @typeY, @typebitmap.bitmap, type2rect)
        else
            @phaseInfoOverlay.blt(@typeX + 32, @typeY, @typebitmap.bitmap, type1rect)
        end

        # Draw phase number
        drawFormattedTextEx(@phaseInfoOverlay, 336, @phaseNumberY, Graphics.width, _INTL("Phase {1}/{2}",@phase+1,@boss.num_phases), base, shadow)

        # Draw move info
        writeMoveInfoToInfoOverlayBackwardsL(@extraInfoOverlay.bitmap,@boss.arrayOfMoveSets[@phase][@moveIndex],false)
    
        @sprites["leftarrow"].visible = @phase > 0
        @sprites["rightarrow"].visible = @phase < @boss.num_phases - 1

        pbDrawMoveList
    end

    def moveListForCurrentPhase
        list = []
        @boss.arrayOfMoveSets[@phase].each do |moveID|
            list.push(GameData::Move.get(moveID).name)
        end
        return list
    end

    def refreshMoveList
        @sprites["commands"].commands = moveListForCurrentPhase
        @sprites["commands"].index = 0

        pbDrawMoveList
    end

    def pbDrawMoveList
        @moveNamesOverlay.clear

        base = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor

        textpos = []
        imagepos = []

        startingYPos = 80
        if @boss.arrayOfMoveSets[@phase].length > 0
            yPos = startingYPos
            # Draw the selectable move elements
            for i in 0...VISIBLEMOVES
                moveobject = @boss.arrayOfMoveSets[@phase][@sprites["commands"].top_item + i]
                if moveobject
                    moveData = GameData::Move.get(moveobject)
                    # type_number = GameData::Type.get(moveData.type).id_number
                    # imagepos.push([addLanguageSuffix("Graphics/Pictures/types"), 12, yPos + 8, 0, type_number * 28, 64, 28])
                    formattedName, nameColor, nameShadow = getFormattedMoveName(moveobject)
                    drawFormattedTextEx(@moveNamesOverlay, 16, yPos, 450, formattedName, nameColor, nameShadow)
                end
                yPos += MOVE_ENTRY_HEIGHT
            end

            # Draw the selection cursor
            sel_path = "Graphics/Pictures/Move Tutor/reminderSel"
            sel_path += "_dark" if darkMode?
            imagepos.push([sel_path,
                        0, 72 + (@sprites["commands"].index - @sprites["commands"].top_item) * MOVE_ENTRY_HEIGHT, 0, 0, 254, 48,])

            # Draw the selected move
            selectedMoveID = @boss.arrayOfMoveSets[@phase][@sprites["commands"].index]
            drawMoveInfo(selectedMoveID)
        else
            textpos.push([_INTL("None"), 126, startingYPos-12, 2, base, shadow])
            @extraInfoOverlay.bitmap.clear
        end

        # Actually render everything
        pbDrawImagePositions(@moveNamesOverlay, imagepos)
        pbDrawTextPositions(@moveNamesOverlay, textpos)
    end

    def drawMoveInfo(selected_move)
        writeMoveInfoToInfoOverlayBackwardsL(@extraInfoOverlay.bitmap, selected_move, false)
    end

    def getFormattedMoveName(move)
        fSpecies = @boss.speciesData
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
        if move_data.primeval
            if isSTAB
                moveName = "<outln2>" + moveName + "</outln2>"
            else
                moveName = "<outln>" + moveName + "</outln>"
            end
            shadow = PRIMEVAL_COLOR
        else
            shadow = MessageConfig.pbDefaultTextShadowColor
        end
        return moveName, color, shadow
    end

    # Processes the scene
    def pbProcessInputs
        Graphics.update
        Input.update
        pbUpdate

        oldcmd = -1
        pbActivateWindow(@sprites, "commands") do
            loop do
                oldcmd = @sprites["commands"].index
                Graphics.update
                Input.update
                pbUpdate
                if @sprites["commands"].index != oldcmd
                    pbDrawMoveList
                end
                refreshNeeded = false
                if Input.trigger?(Input::BACK)
                    pbEndScene
                    pbPlayCloseMenuSE
                    return
                elsif Input.trigger?(Input::LEFT)
                    if @phase > 0
                        @phase -= 1
                        refreshNeeded = true
                        pbPlayCursorSE
                    else
                        pbPlayBuzzerSE
                    end
                elsif Input.trigger?(Input::RIGHT)
                    if @phase < @boss.num_phases - 1
                        @phase += 1
                        refreshNeeded = true
                        pbPlayCursorSE
                    else
                        pbPlayBuzzerSE
                    end
                end
                renderPhaseInfo if refreshNeeded
            end
        end
    end

    # End the scene here
    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        # DISPOSE OF BITMAPS HERE #
        @moveInfoDisplayBitmap.dispose
        @typebitmap.dispose
    end

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end
end

def bossViewer(bossSpecies, bossVersion: 0)
    if bossSpecies.is_a?(PokeBattle_Battler)
        bossVersion = bossSpecies.pokemon.bossVersion
        bossSpecies = bossSpecies.species
    end
    pbFadeOutIn {
        BossViewer_Scene.new(bossSpecies, bossVersion: bossVersion)
    }
end