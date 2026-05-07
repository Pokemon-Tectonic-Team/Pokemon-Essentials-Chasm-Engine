#===============================================================================
# Cursor
#===============================================================================
class PokemonBoxArrow < SpriteWrapper
    attr_accessor :quickswap
    attr_accessor :multiselect

    def initialize(viewport = nil)
        super(viewport)
        @frame         = 0
        @holding       = false
        @updating      = false
        @quickswap     = false
        @multiselect   = false
        @grabbingState = 0
        @placingState  = 0
        @heldpkmn      = nil
        @handsprite    = ChangelingSprite.new(0, 0, viewport)
        arrowGraphics = ["point_1","point_2","grab","fist"]
        suffixes = ["","_q","_m"]
        arrowGraphics.each do |graphicName|
            suffixes.each do |suffix|
                nameWithSuffix = "#{graphicName}#{suffix}"
                path = "Graphics/Pictures/Storage/cursor_#{nameWithSuffix}"
                @handsprite.addBitmap(nameWithSuffix, path) 
            end 
        end
        modifyHandSprite("fist")
        @spriteX = self.x
        @spriteY = self.y
    end

    def dispose
        @handsprite.dispose
        @heldpkmn.dispose if @heldpkmn
        super
    end

    def heldPokemon
        @heldpkmn = nil if @heldpkmn && @heldpkmn.disposed?
        @holding = false unless @heldpkmn
        return @heldpkmn
    end

    def visible=(value)
        super
        @handsprite.visible = value
        sprite = heldPokemon
        sprite.visible = value if sprite
    end

    def color=(value)
        super
        @handsprite.color = value
        sprite = heldPokemon
        sprite.color = value if sprite
    end

    def holding?
        return heldPokemon && @holding
    end

    def grabbing?
        return @grabbingState > 0
    end

    def placing?
        return @placingState > 0
    end

    def x=(value)
        super
        @handsprite.x = self.x
        @spriteX = x unless @updating
        heldPokemon.x = self.x if holding?
    end

    def y=(value)
        super
        @handsprite.y = self.y
        @spriteY = y unless @updating
        heldPokemon.y = self.y + 16 if holding?
    end

    def z=(value)
        super
        @handsprite.z = value
    end

    def setSprite(sprite)
        if holding?
            @heldpkmn = sprite
            @heldpkmn.viewport = viewport if @heldpkmn
            @heldpkmn.z = 1 if @heldpkmn
            @holding = false unless @heldpkmn
            self.z = 2
        end
    end

    def deleteSprite
        @holding = false
        if @heldpkmn
            @heldpkmn.dispose
            @heldpkmn = nil
        end
    end

    def grab(sprite)
        @grabbingState = 1
        @heldpkmn = sprite
        @heldpkmn.viewport = viewport
        @heldpkmn.z = 1
        self.z = 2
    end

    def place
        @placingState = 1
    end

    def release
        @heldpkmn.release if @heldpkmn
    end

    def modifyHandSprite(graphicName)
        graphicName += "_q" if @quickswap
        graphicName += "_m" if @multiselect
        @handsprite.changeBitmap(graphicName)
    end

    def update
        @updating = true
        super
        heldpkmn = heldPokemon
        heldpkmn.update if heldpkmn
        @handsprite.update
        @holding = false unless heldpkmn
        if @grabbingState > 0
            if @grabbingState <= 4 * Graphics.frame_rate / 20
                modifyHandSprite("grab")
                self.y = @spriteY + 4.0 * @grabbingState * 20 / Graphics.frame_rate
                @grabbingState += 1
            elsif @grabbingState <= 8 * Graphics.frame_rate / 20
                @holding = true
                modifyHandSprite("fist")
                self.y = @spriteY + 4 * (8 * Graphics.frame_rate / 20 - @grabbingState) * 20 / Graphics.frame_rate
                @grabbingState += 1
            else
                @grabbingState = 0
            end
        elsif @placingState > 0
            if @placingState <= 4 * Graphics.frame_rate / 20
                modifyHandSprite("fist")
                self.y = @spriteY + 4.0 * @placingState * 20 / Graphics.frame_rate
                @placingState += 1
            elsif @placingState <= 8 * Graphics.frame_rate / 20
                @holding = false
                @heldpkmn = nil
                modifyHandSprite("grab")
                self.y = @spriteY + 4 * (8 * Graphics.frame_rate / 20 - @placingState) * 20 / Graphics.frame_rate
                @placingState += 1
            else
                @placingState = 0
            end
        elsif holding?
            modifyHandSprite("fist")
        else
            self.x = @spriteX
            self.y = @spriteY
            if @frame < Graphics.frame_rate / 2
                modifyHandSprite("point_1")
            else
                modifyHandSprite("point_2")
            end
        end
        @frame += 1
        @frame = 0 if @frame >= Graphics.frame_rate
        @updating = false
    end
end