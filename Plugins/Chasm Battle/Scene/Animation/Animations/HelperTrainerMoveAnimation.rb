#===============================================================================
# Helper Trainer's pokemon using a move animation
#===============================================================================
def pbHelperTrainerMoveAnimation(pokemon, isFoe = false)
    return false unless pokemon
    viewport = Viewport.new(0, 0, 0, 0)
    viewport.z = 99_999
    bg = Sprite.new(viewport)
    bgUrl = "Battle/helper_trainer_move_bg"
    bgUrl += "_foe" if isFoe
    bg.bitmap = RPG::Cache.picture(bgUrl)
    sprite = PokemonSprite.new(viewport)
    sprite.setOffset(PictureOrigin::Center)
    sprite.setPokemonBitmap(pokemon)
    sprite.z = 1
    sprite.visible = false

    strobebitmap = AnimatedBitmap.new("Graphics/Pictures/hiddenMoveStrobes")
    strobes = []

    speedup = $Options.battlescene == 1

    15.times do |i|
        strobe = BitmapSprite.new(26 * 2, 8 * 2, viewport)
        strobe.bitmap.blt(0, 0, strobebitmap.bitmap, Rect.new(0, (i % 2) * 8 * 2, 26 * 2, 8 * 2))
        strobe.z = (i.even? ? 2 : 0)
        strobe.visible = false
        strobes.push(strobe)
    end
    strobebitmap.dispose

    interp = RectInterpolator.new(
        Rect.new(0, Graphics.height / 2, Graphics.width, 0),
       Rect.new(0, (Graphics.height - bg.bitmap.height) / 2, Graphics.width, bg.bitmap.height),
       Graphics.frame_rate / 4)
    ptinterp = nil
    phase = 1
    frames = 0
    strobeSpeed = 64 * 20 / Graphics.frame_rate
    loop do
        Graphics.update
        Input.update
        sprite.update
        case phase
        when 1   # Expand viewport height from zero to full
            interp.update
            interp.set(viewport.rect)
            bg.oy = (bg.bitmap.height - viewport.rect.height) / 2
            if interp.done?
                phase = 2
                interpDuration = Graphics.frame_rate * 4 / 10
                interpDuration /= 2 if speedup
                ptinterp = PointInterpolator.new(
                    Graphics.width + (sprite.bitmap.width / 2), bg.bitmap.height / 2,
                   Graphics.width / 2, bg.bitmap.height / 2,
                   interpDuration)
            end
        when 2   # Slide Pokémon sprite in from right to centre
            ptinterp.update
            sprite.x = ptinterp.x
            sprite.y = ptinterp.y
            sprite.visible = true
            if ptinterp.done?
                phase = 3
                pokemon.play_cry
                frames = 0
            end
        when 3   # Wait
            frames += 1
            waitDuration = Graphics.frame_rate * 3 / 4
            waitDuration /= 2 if speedup
            if frames > waitDuration
                phase = 4
                interpDuration = Graphics.frame_rate * 4 / 10
                interpDuration /= 2 if speedup
                ptinterp = PointInterpolator.new(
                    Graphics.width / 2, bg.bitmap.height / 2,
                   -(sprite.bitmap.width / 2), bg.bitmap.height / 2,
                   interpDuration)
                frames = 0
            end
        when 4   # Slide Pokémon sprite off from centre to left
            ptinterp.update
            sprite.x = ptinterp.x
            sprite.y = ptinterp.y
            if ptinterp.done?
                phase = 5
                sprite.visible = false
                interp = RectInterpolator.new(
                    Rect.new(0, (Graphics.height - bg.bitmap.height) / 2, Graphics.width, bg.bitmap.height),
                   Rect.new(0, Graphics.height / 2, Graphics.width, 0),
                   Graphics.frame_rate / 4)
            end
        when 5   # Shrink viewport height from full to zero
            interp.update
            interp.set(viewport.rect)
            divisor = speedup ? 3 : 2
            bg.oy = (bg.bitmap.height - viewport.rect.height) / divisor
            phase = 6 if interp.done?
        end
        # Constantly stream the strobes across the screen
        for strobe in strobes
            strobe.ox = strobe.viewport.rect.x
            strobe.oy = strobe.viewport.rect.y
            if !strobe.visible # Initial placement of strobes
                randomY = 16 * (1 + rand(bg.bitmap.height / 16 - 2))
                strobe.y = randomY + (Graphics.height - bg.bitmap.height) / 2
                strobe.x = rand(Graphics.width)
                strobe.visible = true
            elsif strobe.x < Graphics.width # Move strobe right
                strobe.x += strobeSpeed
            else # Strobe is off the screen, reposition it to the left of the screen
                randomY = 16 * (1 + rand(bg.bitmap.height / 16 - 2))
                strobe.y = randomY + (Graphics.height - bg.bitmap.height) / 2
                strobe.x = -strobe.bitmap.width - rand(Graphics.width / 4)
            end
        end
        pbUpdateSceneMap
        break if phase == 6
    end
    sprite.dispose
    for strobe in strobes
        strobe.dispose
    end
    strobes.clear
    bg.dispose
    viewport.dispose
    return true
end
