# What plugin code gets from the debug console and from mkxp-z, which plain Ruby doesn't have.
require "tmpdir"

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

# The game's screen size and frame rate. Settings loads after this file, but before any call.
module Graphics
    def self.width
        return Settings::SCREEN_WIDTH
    end

    def self.height
        return Settings::SCREEN_HEIGHT
    end

    def self.frame_rate
        return 60
    end
end

# Where saves go; core SaveData reads it at load. Nothing in the tests saves.
module System
    def self.data_directory
        return Dir.tmpdir
    end
end
