# What plugin code gets from the debug console and from mkxp-z, which plain Ruby doesn't have.
# Drawing draws nothing: a Bitmap records what was drawn onto it instead.
require "fileutils"
require "minitest"
require "tmpdir"
require_relative "harness_error"
require_relative "plugin_loader"

def echoln(*); end

# Core MKXP_Compatibility's, which titles mkxp-z's window. The compilers and PBS writers call it.
def pbSetWindowText(_string); end

# RGSS's save_data: Marshals the object into the file, as the GameData classes' save does
def save_data(object, filename)
    File.binwrite(filename, Marshal.dump(object))
end

class Color
    attr_accessor :red, :green, :blue, :alpha

    def initialize(red = 0, green = 0, blue = 0, alpha = 255)
        set(red, green, blue, alpha)
    end

    def set(red, green, blue, alpha = 255)
        @red = red
        @green = green
        @blue = blue
        @alpha = alpha
        return self
    end
end

class Tone
    attr_accessor :red, :green, :blue, :gray

    def initialize(red = 0, green = 0, blue = 0, gray = 0)
        set(red, green, blue, gray)
    end

    def set(red, green, blue, gray = 0)
        @red = red
        @green = green
        @blue = blue
        @gray = gray
        return self
    end
end

class Rect
    attr_accessor :x, :y, :width, :height

    # Not through set, which the game's WindowCursorRect overrides.
    def initialize(x = 0, y = 0, width = 0, height = 0)
        @x = x
        @y = y
        @width = width
        @height = height
    end

    def set(x, y, width, height)
        @x = x
        @y = y
        @width = width
        @height = height
        return self
    end

    def empty
        set(0, 0, 0, 0)
    end
end

class Font
    class << self
        attr_accessor :default_name, :default_size, :default_bold, :default_italic, :default_shadow,
            :default_outline, :default_color, :default_out_color
    end

    attr_accessor :name, :size, :bold, :italic, :shadow, :outline, :color, :out_color

    def self.exist?(_name)
        return true
    end

    def initialize(name = Font.default_name, size = Font.default_size || 24)
        @name = name
        @size = size
        @bold = false
        @italic = false
        @shadow = false
        @outline = false
        @color = Color.new(255, 255, 255)
        @out_color = Color.new(0, 0, 0, 128)
    end
end

# A bitmap is either blank at a size or read from an image file, whose size comes from its PNG
# header. It records each blt (as [x, y, source bitmap, source rect]) and each text drawn, and
# measures text at TEXT_CHAR_WIDTH a character.
class Bitmap
    TEXT_CHAR_WIDTH = 10
    PNG_SIGNATURE = "\x89PNG\r\n\x1A\n".b.freeze

    attr_reader :width, :height, :path, :blts, :texts, :clears
    attr_accessor :font

    def initialize(*args)
        if args.length == 1
            @path = args[0]
            @width, @height = Bitmap.png_size(@path)
        else
            @width, @height = args
        end
        @font = Font.new
        @blts = []
        @texts = []
        @clears = 0
        @disposed = false
    end

    # A PNG's width and height. Raises as mkxp-z does for a file it can't open.
    def self.png_size(path)
        header = File.binread(path, 24)
        raise Errno::ENOENT, path unless header&.start_with?(PNG_SIGNATURE)

        return header[16, 8].unpack("NN")
    end

    def rect
        return Rect.new(0, 0, @width, @height)
    end

    def blt(x, y, source, sourceRect, _opacity = 255)
        @blts.push([x, y, source, sourceRect])
    end

    def stretch_blt(destRect, source, sourceRect, _opacity = 255)
        @blts.push([destRect.x, destRect.y, source, sourceRect])
    end

    def fill_rect(*); end
    def gradient_fill_rect(*); end
    def clear_rect(*); end
    def hue_change(_hue); end

    def clear
        @clears += 1
    end

    # Drawn as draw_text(x, y, width, height, text, align = 0) or draw_text(rect, text, align = 0).
    def draw_text(*args)
        @texts.push((args[0].is_a?(Rect) ? args[1] : args[4]).to_s)
    end

    def text_size(text)
        return Rect.new(0, 0, text.to_s.length * TEXT_CHAR_WIDTH, @font.size || 24)
    end

    def get_pixel(_x, _y)
        return Color.new(0, 0, 0, 255)
    end

    def set_pixel(*); end

    # A still image, as mkxp-z reports one. A test sets frame_count and frame_rate to make a
    # bitmap animated, as mkxp-z reports a GIF.
    attr_writer :frame_count, :frame_rate

    def frame_count
        return @frame_count || 1
    end

    def frame_rate
        return @frame_rate || 0
    end

    def animated?
        return frame_count > 1
    end

    def current_frame
        return 0
    end

    def play; end
    def stop; end
    def goto_and_stop(_frame); end

    def dispose
        @disposed = true
    end

    def disposed?
        return @disposed
    end
end

# The parts every drawable shares: a viewport, position, depth and visibility.
class Viewport
    attr_accessor :rect, :ox, :oy, :z, :visible, :color, :tone

    def initialize(*args)
        @rect = args.length == 1 ? args[0] : Rect.new(*args)
        @ox = 0
        @oy = 0
        @z = 0
        @visible = true
        @color = Color.new(0, 0, 0, 0)
        @tone = Tone.new
        @disposed = false
    end

    def update; end
    def flash(*); end

    def dispose
        @disposed = true
    end

    def disposed?
        return @disposed
    end
end

class Sprite
    attr_reader :bitmap
    attr_accessor :src_rect, :viewport, :x, :y, :z, :ox, :oy, :zoom_x, :zoom_y, :angle, :mirror,
        :visible, :opacity, :blend_type, :color, :tone, :bush_depth

    def initialize(viewport = nil)
        @viewport = viewport
        @src_rect = Rect.new
        @x = 0
        @y = 0
        @z = 0
        @ox = 0
        @oy = 0
        @zoom_x = 1.0
        @zoom_y = 1.0
        @angle = 0
        @mirror = false
        @visible = true
        @opacity = 255
        @blend_type = 0
        @bush_depth = 0
        @color = Color.new(0, 0, 0, 0)
        @tone = Tone.new
        @disposed = false
    end

    def bitmap=(value)
        @bitmap = value
        @src_rect = value ? value.rect : Rect.new
    end

    def width
        return @src_rect.width
    end

    def height
        return @src_rect.height
    end

    def update; end
    def flash(*); end

    def dispose
        @disposed = true
    end

    def disposed?
        return @disposed
    end
end

# mkxp-z's window. SpriteWindow.rb subclasses it before the game's Window.rb, which reopens it,
# loads; SpriteWindow never calls its initialize.
class Window; end # rubocop:disable Lint/EmptyClass

# The game's screen size and frame rate. Settings loads after this file, but before any call.
# update counts frames. Called while PluginLoader works out the load order, it can only be core
# PluginManager.error waiting to exit the process, so it raises instead.
module Graphics
    @frame_count = 0

    class << self
        attr_accessor :frame_count
    end

    def self.width
        return Settings::SCREEN_WIDTH
    end

    def self.height
        return Settings::SCREEN_HEIGHT
    end

    def self.frame_rate
        return 60
    end

    def self.update
        raise HarnessError, "a plugin's meta.txt is malformed (PluginManager.error)" if PluginLoader.ordering?

        @frame_count += 1
    end
end

module Input
    def self.update; end
end

# mkxp-z's own RPG::Cache starts the cache the game's RPG_Cache.rb fills.
module RPG
    module Cache
        @cache = {}
    end
end

# Where saves and options go: a folder of the run's own, removed when it ends. Core SaveData reads
# it at load, and the game's Options.rb writes its options file there.
module System
    @data_directory = Dir.mktmpdir("chasm-tests")
    # Not at_exit: minitest runs the tests from an at_exit hook, after any registered later.
    Minitest.after_run { FileUtils.remove_entry(@data_directory) }

    def self.data_directory
        return @data_directory
    end

    def self.platform
        return "Linux"
    end
end
