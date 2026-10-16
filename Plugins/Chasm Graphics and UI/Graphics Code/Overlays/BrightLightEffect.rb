#===============================================================================
# Light effects
#===============================================================================
class LightEffect
  def initialize(event,viewport=nil,map=nil,filename=nil)
    @light = IconSprite.new(0,0,viewport)
    if filename!=nil && filename!="" && pbResolveBitmap("Graphics/Pictures/Light Effects/"+filename)
      @light.setBitmap("Graphics/Pictures/Light Effects/"+filename)
    else
      @light.setBitmap("Graphics/Pictures/Light Effects/base_light")
    end
    @light.z = 1000
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
  end

  def disposed?
    return @disposed
  end

  def dispose
    @light.dispose
    @map = nil
    @event = nil
    @disposed = true
  end

  def update
    @light.update
  end
end



class LightEffect_Lamp < LightEffect
  def initialize(event,viewport=nil,map=nil)
    lamp = AnimatedBitmap.new("Graphics/Pictures/Light Effects/base_light")
    @light = Sprite.new(viewport)
    @light.bitmap  = Bitmap.new(128,64)
    src_rect = Rect.new(0, 0, 64, 64)
    @light.bitmap.blt(0, 0, lamp.bitmap, src_rect)
    @light.bitmap.blt(20, 0, lamp.bitmap, src_rect)
    @light.visible = true
    @light.z       = 1000
    lamp.dispose
    @map = (map) ? map : $game_map
    @event = event
  end
end

class LightEffect_Basic < LightEffect
  def update
    return if !@light || !@event
    super
    @light.opacity = 100
    @light.ox      = 32
    @light.oy      = 48
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event)
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
    else
      @light.x      = @event.screen_x
      @light.y      = @event.screen_y
      @light.zoom_x = 1.0
    end
    @light.zoom_y = @light.zoom_x
    @light.tone   = $game_screen.tone
  end
end

class LightEffect_DayNight < LightEffect
  def update
    return if !@light || !@event
    super
    shade = PBDayNight.getShade
    if shade>=144   # If light enough, call it fully day
      shade = 255
    elsif shade<=64   # If dark enough, call it fully night
      shade = 0
    else
      shade = 255-(255*(144-shade)/(144-64))
    end
    @light.opacity = 255-shade
    if @light.opacity>0
      @light.ox = 32
      @light.oy = 48
      if (Object.const_defined?(:ScreenPosHelper) rescue false)
        @light.x      = ScreenPosHelper.pbScreenX(@event)
        @light.y      = ScreenPosHelper.pbScreenY(@event)
        @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
        @light.zoom_y = ScreenPosHelper.pbScreenZoomY(@event)
      else
        @light.x      = @event.screen_x
        @light.y      = @event.screen_y
        @light.zoom_x = 1.0
        @light.zoom_y = 1.0
      end
      @light.tone.set($game_screen.tone.red,
                      $game_screen.tone.green,
                      $game_screen.tone.blue,
                      $game_screen.tone.gray)
    end
  end
end

class LightEffect_Abyss < LightEffect
  def initialize(event,viewport=nil,map=nil,filename=nil)
    @light = IconSprite.new(0,0,viewport)
    if filename!=nil && filename!="" && pbResolveBitmap("Graphics/Pictures/Light Effects/"+filename)
      @light.setBitmap("Graphics/Pictures/Light Effects/"+filename)
    else
      @light.setBitmap("Graphics/Pictures/Light Effects/abyssal_light")
    end
    @light.z = 1000
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
  end

  def update
    return if !@light || !@event
    super
    @light.opacity = 100
    @light.ox      = 32 * 4
    @light.oy      = 32 * 4.5
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event)
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
    else
      @light.x      = @event.screen_x
      @light.y      = @event.screen_y
      @light.zoom_x = 1.0
    end
    @light.zoom_y = @light.zoom_x
    @light.tone   = $game_screen.tone
    @light.blend_type = 1
  end
end

class LightEffect_Crystal < LightEffect
  def initialize(event,viewport=nil,map=nil)
    @light = IconSprite.new(0,0,viewport)
    @light.setBitmap("Graphics/Pictures/Light Effects/base_light")
    @light.z = 1000
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
    @opacityCounter = 0
    @opacityWavelength = 8.0
    @crystalDeactivated = false
  end

  def update
    return if !@light || !@event || @crystalDeactivated
    super

    if pbGetSelfSwitch(@event.id,'A')
      echoln("Turning this crystal light off since the #{@event.name}'s A switch is on")
      @light.opacity = 0
      @crystalDeactivated = true
      return
    end

    @opacityCounter += 1
    @light.opacity = (80 + 40 * Math.sin(@opacityCounter.to_f / @opacityWavelength)).floor
    @light.ox      = (@light.bitmap.width * 2) / 4
    @light.oy      = (@light.bitmap.height * 3) / 4
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event) - 8
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
    else
      @light.x      = @event.screen_x
      @light.y      = @event.screen_y - 8
      @light.zoom_x = 1.0
    end
    @light.zoom_y = @light.zoom_x
    @light.tone   = $game_screen.tone
  end
end

class LightEffect_GoldenGlow < LightEffect
  def initialize(event,viewport=nil,map=nil)
    @light = IconSprite.new(0,0,viewport)
    @light.setBitmap("Graphics/Pictures/Light Effects/totem_light")
    @light.z = 1000
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
    @opacityCounter = 0
    @opacityWavelength = 8.0
    @goldenglowDeactivated = false
  end

  def update
    return if !@light || !@event || @goldenglowDeactivated
    super

    if pbGetSelfSwitch(@event.id,'D')
      echoln("Turning this goldenglow off since the #{@event.name}'s D switch is on")
      @light.opacity = 0
      @goldenglowDeactivated = true
      return
    end

    @opacityCounter += 1
    @light.opacity = (80 + 40 * Math.sin(@opacityCounter.to_f / @opacityWavelength)).floor
    @light.ox      = (@light.bitmap.width * 2) / 4
    @light.oy      = (@light.bitmap.height * 3) / 4
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event)
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
    else
      @light.x      = @event.screen_x
      @light.y      = @event.screen_y
      @light.zoom_x = 1.0
    end
    @light.zoom_y = @light.zoom_x
    @light.tone   = $game_screen.tone
  end
end

class LightEffect_Totem < LightEffect
    def initialize(event,viewport=nil,map=nil)
      @light = IconSprite.new(0,0,viewport)
      @light.setBitmap("Graphics/Pictures/Light Effects/totem_light")
      @light.ox      = (@light.bitmap.width * 2) / 4
      @light.oy      = (@light.bitmap.height * 3) / 4

      @activationFrameCount = 32
      @activationSprite = AnimatedSprite.new(["Graphics/Pictures/Waypoints/waypoint_activation", @activationFrameCount, 1])
      @activationSprite.viewport = viewport
      pbSEPlay("Totem activation", 0) # silent preplay to cache it

      @event = event
      @map = (map) ? map : $game_map
      @disposed = false
      @opacityCounter = 0
      @opacityWavelength = 8.0
      @summonTotem = false

      # 0 basic glowing
      # 1 activation animation
      # 2 golden glow fading away
      @animationMode = 0
    end
    
    def switchAnimationMode(mode)
      @animationMode = mode
      @opacityCounter = 0 if mode == 0
      @animationComplete = false
      @activationSprite.play if mode == 1
    end

    def update
      return unless @event
      super

      if @light
        shouldBeBlue = pbGetSelfSwitch(@event.id,'A') || @event.name.include?("blue")
        if !@summonTotem && shouldBeBlue
          echoln("Setting this totem light to the summon version since the #{@event.name}'s A switch is on")
          @light.setBitmap("Graphics/Pictures/Light Effects/totem_light_blue")
          @summonTotem = true
          @opacityCounter = 0
          @opacifyWavelength = 4.0
        elsif @summonTotem && !shouldBeBlue
          echoln("Setting this totem light to the non-summon version since the #{@event.name}'s A switch is off")
          @light.setBitmap("Graphics/Pictures/Light Effects/totem_light")
          @summonTotem = false
          @opacityCounter = 0
          @opacifyWavelength = 8.0
        end

        genericUpdate(@light)
        @light.z      = @event.screen_z
      end
      
      if @activationSprite
        @activationSprite.visible = @animationMode == 1
        genericUpdate(@activationSprite, -48, -64)

        @activationSprite.z = @event.screen_z
      end

      unless @animationComplete
        case @animationMode
        when 0
          passiveGlowAnimation
        when 1
          activationAnimation
        when 2
          glowFadingAnimation
        end
      end
    end

    def genericUpdate(sprite,xOffset = 0,yOffset = 0)
      if (Object.const_defined?(:ScreenPosHelper) rescue false)
        sprite.x      = ScreenPosHelper.pbScreenX(@event) + xOffset
        sprite.y      = ScreenPosHelper.pbScreenY(@event) + yOffset
        sprite.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
      else
        sprite.x      = @event.screen_x + xOffset
        sprite.y      = @event.screen_y + yOffset
        sprite.zoom_x = 1.0
      end
      sprite.zoom_y = sprite.zoom_x
      sprite.tone   = $game_screen.tone
    end

    def animationComplete?
      return @animationComplete
    end

    def passiveGlowAnimation
      @opacityCounter += 1
      @light.opacity = (80 + 40 * Math.sin(@opacityCounter.to_f / @opacityWavelength)).floor
    end

    def activationAnimation
      @activationSprite.update
      if @activationSprite.frame >= @activationFrameCount - 1
        @animationComplete = true
        @activationSprite.stop
        @activationSprite.frame = 0
      end
    end

    def glowFadingAnimation
      @light.opacity -= 3
      @animationComplete = true if @light.opacity <= 0
    end
end

class LightEffect_SummonTotemAura < LightEffect
  def initialize(event,viewport=nil,map=nil)
    @light = IconSprite.new(0,0,viewport)
    @light.setBitmap("Graphics/Pictures/Light Effects/totem_light_blue")
    @light.z = 1000
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
    @opacityCounter = 0
    @opacityWavelength = 8.0
  end

  def update
    return if !@light || !@event
    super
    if !gameWon? || pbGetSelfSwitch(@event.id,'A')
      @light.opacity = 0
      return
    end
    @opacityCounter += 1
    @light.opacity = (80 + 40 * Math.sin(@opacityCounter.to_f / @opacityWavelength)).floor
    @event.opacity = @light.opacity
    @light.ox      = (@light.bitmap.width * 2) / 4
    @light.oy      = (@light.bitmap.height * 3) / 4
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event)
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
    else
      @light.x      = @event.screen_x
      @light.y      = @event.screen_y
      @light.zoom_x = 1.0
    end
    @light.zoom_y = @light.zoom_x
    @light.tone   = $game_screen.tone
  end
end

class LightEffect_DragonFlame < LightEffect
  def initialize(event,viewport=nil,map=nil)
    super
    @light.setBitmap("Graphics/Pictures/Light Effects/dragon_flame")
    @opacityCounter = 0
  end

  def update
    return if !@light || !@event
    super
    @light.opacity = 200
    t = @opacityCounter.to_f / 8.0
    @light.ox      = 32 + (12 * Math.cos(t)).floor
    @light.oy      = 96 + (8 * Math.sin(t) * Math.cos(t)).floor
    @light.x      = @event.screen_x
    @light.y      = @event.screen_y
    @light.zoom_x = 1.0
    @light.zoom_y = @light.zoom_x
    @light.tone   = $game_screen.tone
    @light.blend_type = 1
    @opacityCounter += 1
  end
end

class LightEffect_Condensed < LightEffect
  def initialize(event,viewport=nil,map=nil)
    super
    @light.setBitmap("Graphics/Pictures/Light Effects/halo_light")
    @opacityCounter = 0
    @light.ox      = (@light.bitmap.width * 2) / 4
    @light.oy      = (@light.bitmap.height * 2) / 4
    @light.blend_type = 1
  end

  def update
    return if !@light || !@event
    super
    if @event.character_name.blank? || $game_switches[80] # Lainie saved
      @light.opacity = 0
      return
    end
    @baseOpacity = 120
    @opacityCounter += 1
    @light.opacity = (@baseOpacity + (@baseOpacity / 6.0) * Math.sin(@opacityCounter.to_f / 12.0)).floor
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event) - 32
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
    else
      @light.x      = @event.screen_x
      @light.y      = @event.screen_y - 32
      @light.zoom_x = 1.0
    end
  end
end

class LightEffect_TVGlow < LightEffect
  def initialize(event,viewport=nil,map=nil,filename=nil)
    @light = IconSprite.new(0,0,viewport)
    if filename!=nil && filename!="" && pbResolveBitmap("Graphics/Pictures/Light Effects/"+filename)
      @light.setBitmap("Graphics/Pictures/Light Effects/"+filename)
    else
      @light.setBitmap("Graphics/Pictures/Light Effects/television_glow")
    end
    @light.z = 1000
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
    @opacityCounter = 0
    @opacityWavelength = 8.0
  end

  def update
    return if !@light || !@event
    unless televisionNewsEvent?
      @light.opacity = 0
      return
    end
    super
    @light.opacity = 100
    @light.ox      = 64
    @light.oy      = 107
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event)
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
    else
      @light.x      = @event.screen_x
      @light.y      = @event.screen_y
      @light.zoom_x = 1.0
    end
    @light.x -= 32
    @light.zoom_y = @light.zoom_x
    @light.tone   = $game_screen.tone

    @opacityCounter += 1
    @light.opacity = (100 + 50 * Math.sin(@opacityCounter.to_f / @opacityWavelength)).floor
  end
end

Events.onSpritesetCreate += proc { |_sender,e|
  spriteset = e[0]      # Spriteset being created
  viewport  = e[1]      # Viewport used for tilemap and characters
  map = spriteset.map   # Map associated with the spriteset (not necessarily the current map)
  for i in map.events.keys
    event = map.events[i]
    if event.name[/^outdoorlight\((\w+)\)$/i]
      filename = $~[1].to_s
      spriteset.addUserSprite(LightEffect_DayNight.new(event,viewport,map,filename))
    elsif event.name[/^outdoorlight$/i]
      spriteset.addUserSprite(LightEffect_DayNight.new(event,viewport,map))
    elsif event.name[/^abysslight$/i]
      spriteset.addUserSprite(LightEffect_Abyss.new(event,viewport,map))
    elsif event.name[/^light\((\w+)\)$/i]
      filename = $~[1].to_s
      spriteset.addUserSprite(LightEffect_Basic.new(event,viewport,map,filename))
    elsif event.name[/AvatarTotem/i]
      spriteset.addUserSprite(LightEffect_Totem.new(event,viewport,map),event.id)
    elsif event.name.include?("goldenglow")
      spriteset.addUserSprite(LightEffect_GoldenGlow.new(event,viewport,map))
    elsif event.name.include?("crystalglow")
      spriteset.addUserSprite(LightEffect_Crystal.new(event,viewport,map))
    elsif event.name[/^condensedlight$/i] || event.name.include?("condensedlight")
      spriteset.addUserSprite(LightEffect_Condensed.new(event,viewport,map))
    elsif event.name.include?("summontotemaura")
      spriteset.addUserSprite(LightEffect_SummonTotemAura.new(event,viewport,map))
    elsif event.name[/^light$/i] || event.name.include?("lighteffect")
      spriteset.addUserSprite(LightEffect_Basic.new(event,viewport,map))
    elsif event.name[/newstv/i] && televisionNewsEvent?
      spriteset.addUserSprite(LightEffect_TVGlow.new(event,viewport,map))
    end
  end
  $PokemonGlobal.dragonFlamesCount.times do
    createDragonFlameGraphic(spriteset)
  end
}