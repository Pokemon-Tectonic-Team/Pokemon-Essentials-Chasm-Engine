require "fileutils"
require "tmpdir"

# A game folder for one test. The game looks images up relative to the working directory, so
# with(images) makes a temporary folder holding each named image, plus the default speech and
# menu windowskins, the working directory for the block. Each image is a PNG header of the given
# size, all the Bitmap stub reads. The image cache and the message skins remembered from an
# earlier folder are dropped first.
module GraphicsFolder
    module_function

    SKIN_SIZE = [128, 128].freeze

    # images maps a path without its extension ("Graphics/Faces/Val") to [width, height].
    def with(images = {})
        Dir.mktmpdir do |dir|
            skins = [MessageConfig.speechFrameName, MessageConfig.systemFrameName].to_h { |name| [name, SKIN_SIZE] }
            skins.merge(images).each do |name, (width, height)|
                path = File.join(dir, "#{name}.png")
                FileUtils.mkdir_p(File.dirname(path))
                File.binwrite(path, png(width, height))
            end
            Dir.chdir(dir) do
                RPG::Cache.instance_variable_get(:@cache).clear
                MessageConfig.pbSetSpeechFrame(MessageConfig.speechFrameName)
                MessageConfig.pbSetSystemFrame(MessageConfig.systemFrameName)
                yield dir
            end
        end
    end

    # A PNG signature and IHDR chunk, CRC left zero: what Bitmap.png_size reads.
    def png(width, height)
        ihdr = [width, height].pack("NN") + [8, 6, 0, 0, 0].pack("C5")
        return [Bitmap::PNG_SIGNATURE, [ihdr.bytesize].pack("N"), "IHDR", ihdr, "\0" * 4].join
    end
end
