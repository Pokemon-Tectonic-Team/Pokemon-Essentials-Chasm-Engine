# What plugin code gets from the debug console and from mkxp-z, which plain Ruby doesn't have.

def echoln(*); end

class Color
    attr_accessor :red, :green, :blue, :alpha

    def initialize(red, green, blue, alpha = 255)
        @red = red
        @green = green
        @blue = blue
        @alpha = alpha
    end
end

class Rect
    attr_accessor :x, :y, :width, :height

    def initialize(x, y, width, height)
        @x = x
        @y = y
        @width = width
        @height = height
    end
end
