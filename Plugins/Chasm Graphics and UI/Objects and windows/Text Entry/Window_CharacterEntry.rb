#===============================================================================
#
#===============================================================================
class Window_CharacterEntry < Window_DrawableCommand
    XSIZE = 13
    YSIZE = 4

    def initialize(charset, viewport = nil)
        @viewport = viewport
        @charset = charset
        @othercharset = ""
        super(0, 96, 480, 192)
        colors = getDefaultTextColors(windowskin)
        self.baseColor = colors[0]
        self.shadowColor = colors[1]
        self.columns = XSIZE
        refresh
    end

    def setOtherCharset(value)
        @othercharset = value.clone
        refresh
    end

    def setCharset(value)
        @charset = value.clone
        refresh
    end

    def character
        if index < 0 || index >= @charset.length
            return ""
        else
            return @charset[index]
        end
    end

    def command
        return -1 if index == @charset.length
        return -2 if index == @charset.length + 1
        return -3 if index == @charset.length + 2
        return index
    end

    def itemCount
        return @charset.length + 3
    end

    def drawItem(index, _count, rect)
        rect = drawCursor(index, rect)
        if index == @charset.length # -1
            pbDrawShadowText(contents, rect.x, rect.y, rect.width, rect.height, "[ ]",
               baseColor, shadowColor)
        elsif index == @charset.length + 1 # -2
            pbDrawShadowText(contents, rect.x, rect.y, rect.width, rect.height, @othercharset,
               baseColor, shadowColor)
        elsif index == @charset.length + 2 # -3
            pbDrawShadowText(contents, rect.x, rect.y, rect.width, rect.height, _INTL("OK"),
               baseColor, shadowColor)
        else
            pbDrawShadowText(contents, rect.x, rect.y, rect.width, rect.height, @charset[index],
               baseColor, shadowColor)
        end
    end
end
