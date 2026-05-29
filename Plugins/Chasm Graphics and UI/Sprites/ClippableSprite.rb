class ClippableSprite < Sprite_Character
    def initialize(viewport, event, tilemap)
        @tilemap = tilemap
        @_src_rect = Rect.new(0, 0, 0, 0)
        super(viewport, event)
    end

    def update
        super
        @_src_rect = src_rect
        tmright = (@tilemap.map_data.xsize * Game_Map::TILE_WIDTH) - @tilemap.ox
        echoln("x=#{x},ox=#{ox},tmright=#{tmright},tmox=#{@tilemap.ox}")
        if @tilemap.ox - ox < -x
            # clipped on left
            diff = -x - @tilemap.ox + ox
            self.src_rect = Rect.new(@_src_rect.x + diff, @_src_rect.y,
                                     @_src_rect.width - diff, @_src_rect.height)
            echoln("clipped out left: #{diff} #{@tilemap.ox - ox} #{x}")
        elsif tmright - ox < x
            # clipped on right
            diff = x - tmright + ox
            self.src_rect = Rect.new(@_src_rect.x, @_src_rect.y,
                                     @_src_rect.width - diff, @_src_rect.height)
            echoln("clipped out right: #{diff} #{tmright + ox} #{x}")
        else
            echoln("-not- clipped out left: #{diff} #{@tilemap.ox - ox} #{x}")
        end
    end
end
