class BossViewer_Scene
    include MoveInfoDisplay

    POKEMON_ICON_SIZE = 64
    base   = Color.new(80, 80, 88)
    shadow = Color.new(160, 160, 168)

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
        addBackgroundPlane(@sprites, "bg", backgroundFileName, @viewport)

        # Define main overlays
        @sprites["boss_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @bossInfoOverlay = @sprites["boss_overlay"].bitmap
        pbSetSystemFont(@bossInfoOverlay)

        @sprites["phase_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @phaseInfoOverlay = @sprites["phase_overlay"].bitmap
        pbSetSystemFont(@phaseInfoOverlay)

        # Define some constants
        @typeX = 132
        @typeY = 12
        @arrowY = 28
        @phaseNumberY = 28
        @speciesIconX = 16
        @speciesIconY = 4

        # Create the left and right arrow sprites which surround the selected index
        @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow", 8, 40, 28, 2, @viewport)
        @sprites["leftarrow"].x       = 280
        @sprites["leftarrow"].y       = @arrowY
        @sprites["leftarrow"].play
        @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow", 8, 40, 28, 2, @viewport)
        @sprites["rightarrow"].x       = 280 + 180
        @sprites["rightarrow"].y       = @arrowY
        @sprites["rightarrow"].play

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

        loop do
            Graphics.update
            Input.update
            pbUpdate
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
        drawFormattedTextEx(@bossInfoOverlay, 100, 44, Graphics.width, abilityLabel, base, shadow)
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