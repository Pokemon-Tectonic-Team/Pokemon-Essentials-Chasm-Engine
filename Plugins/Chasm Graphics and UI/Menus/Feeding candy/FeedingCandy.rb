class PokemonFeedCandyScene
 
    def pbUpdate(animating=false)
      pbUpdateSpriteHash(@sprites)
    end
  
    def pbStartScreen(pokemon,expAmount)
      @pokemon = pokemon
      @expAmount = expAmount
      @sprites = {}
      @bgviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @bgviewport.z = 99999
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @msgviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @msgviewport.z = 99999
      addBackgroundOrColoredPlane(@sprites, "background", "evolutionbg", Color.new(248,248,248),@bgviewport)

      pokemon_sprite = PokemonSprite.new(@viewport)
      pokemon_sprite.setOffset(PictureOrigin::Center)
      pokemon_sprite.setPokemonBitmap(@pokemon,false)
      @pokemonCenter = [Graphics.width/2, (Graphics.height-64)/2]
      pokemon_sprite.x = @pokemonCenter[0]
      pokemon_sprite.y = @pokemonCenter[1]
      
      @sprites["pokemon_sprite"] = pokemon_sprite

      # Calculate how many candy sprites there should be
      candyAmounts = calculateCandySplitForEXP(@expAmount)
      candySum = candyAmounts.sum
      spriteIndex = 0
      radius = 100
      @candySprites = []
      @candySpriteStartingPositions = []
      EXP_CANDY_IDS.each_with_index do |expCandyID, index|
        candyAmounts[index].times do |i|
            newCandyIcon = ItemIconSprite.new(0, 0, expCandyID, @viewport)
            newCandyIcon.setOffset(PictureOrigin::Center)

            angle = 2 * Math::PI * spriteIndex / candySum.to_f
            iconXOffset = Math.cos(angle) * radius
            iconYOffset = Math.sin(angle) * radius

            newCandyIcon.x = @pokemonCenter[0] + iconXOffset
            newCandyIcon.y = @pokemonCenter[1] + iconYOffset

            @candySpriteStartingPositions.push([newCandyIcon.x,newCandyIcon.y])

            newCandyIcon.zoom_x = 0
            newCandyIcon.zoom_y = 0

            @sprites["#{expCandyID.to_s.downcase}_sprite_#{i}"] = newCandyIcon
            @candySprites.push(newCandyIcon)

            spriteIndex += 1
        end
      end

      @sprites["msgwindow"] = pbCreateMessageWindow(@msgviewport)
      pbFadeInAndShow(@sprites) { pbUpdate }

      weightValue = ((pokemon.species_data.weight ** 0.5) / 10.0).clamp(0.5,1.5)
      @nomPitch = 150 - (50 * weightValue).floor
    end

    def pbEndScreen
      pbDisposeMessageWindow(@sprites["msgwindow"])
      pbFadeOutAndHide(@sprites) { pbUpdate }
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
      @bgviewport.dispose
      @msgviewport.dispose
      $PokemonTemp.dependentEvents.refresh_sprite(false)
    end

    # Opens the evolution screen
    def pbFeedCandy
        pbBGMStop
        pbPlayDecisionSE

        framesToAppear = 14
        framesToMove = 6
        delayBetweenCandy = 40
        startingZoomDelay = 10
        startingMovementDelay = startingZoomDelay + 30
        totalDuration = startingMovementDelay + delayBetweenCandy + 5
        totalDuration.times do |frame|
            @candySprites.each_with_index do |sprite, index|
                zoomDelay = startingZoomDelay + (delayBetweenCandy * index / @candySprites.length)
                zoom = [[(frame - zoomDelay) / framesToAppear.to_f, 0].max, 1].min
                sprite.zoom_x = zoom
                sprite.zoom_y = zoom

                positionDelay = startingMovementDelay + (delayBetweenCandy * index / @candySprites.length)
                movementProgress = [[(frame - positionDelay) / framesToMove.to_f, 0].max, 1].min
                movementProgress = movementProgress ** 0.9
                startingPosition = @candySpriteStartingPositions[index]
                sprite.x = (@pokemonCenter[0] * movementProgress + startingPosition[0] * (1 - movementProgress))
                sprite.y = (@pokemonCenter[1] * movementProgress + startingPosition[1] * (1 - movementProgress))

                opacityBefore = sprite.opacity
                opacityChange = [[(movementProgress - 0.8) / 0.2,0].max,1].min
                sprite.opacity = 255 * (1 - opacityChange)
                pbSEPlay("Anim/PRSFX- Nom",80,@nomPitch) if sprite.opacity == 0 && opacityBefore != 0
            end
            Graphics.update
            Input.update
            pbUpdate(true)
        end

        @pokemon.play_cry
    end
end