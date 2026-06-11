module Compiler
    module_function

    #=============================================================================
    # Compile track data
    #=============================================================================
    def compile_tracks
        GameData::Track::DATA.clear
        schema = GameData::Track::SCHEMA
        baseFiles = ["PBS/tracks.txt"]
        trackTextFiles = []
        trackTextFiles.concat(baseFiles)
        trackExtensions = Compiler.get_extensions("tracks")
        trackTextFiles.concat(trackExtensions)
        trackTextFiles.each do |path|
            baseFile = baseFiles.include?(path)
            track_hash = nil
            pbCompilerEachPreppedLine(path) { |line, line_no|
                if line[/^\s*\[\s*(.+)\s*\]\s*$/]
                    GameData::Track.register(track_hash) if track_hash
                    track_id = $~[1].to_sym
                    if GameData::Track.exists?(track_id)
                        raise _INTL("Track ID '{1}' is used twice.\r\n{2}", track_id, FileLineData.linereport)
                    end
                    track_hash = {
                        :id                   => track_id,
                        :defined_in_extension => !baseFile,
                    }
                elsif line[/^\s*(\w+)\s*=\s*(.*)\s*$/]
                    if !track_hash
                        raise _INTL("Expected a section at the beginning of the file.\r\n{1}", FileLineData.linereport)
                    end
                    property_name = $~[1]
                    line_schema = schema[property_name]
                    next if !line_schema
                    property_value = pbGetCsvRecord($~[2], line_no, line_schema)
                    track_hash[line_schema[0]] = property_value
                end
            }
            GameData::Track.register(track_hash) if track_hash
        end
        GameData::Track.save
        Graphics.update
    end

    #=============================================================================
    # Save track data to PBS file
    #=============================================================================
    def write_tracks
        File.open("PBS/tracks.txt", "wb") do |f|
            add_PBS_header_to_file(f)
            GameData::Track.each_base do |track|
                write_track(f, track)
            end
        end
        Graphics.update
    end

    def write_track(f, track)
        f.write("\#-------------------------------\r\n")
        f.write("[#{track.id}]\r\n")
        f.write("Filename = #{track.filename}\r\n")
        f.write("Index = #{track.index}\r\n")
        f.write("DisplayName = #{track.real_name}\r\n")
        f.write("OfficialName = #{track.official_name}\r\n") if track.official_name
        f.write("SourceGame = #{track.source_game}\r\n") if track.source_game
        f.write("Composer = #{track.composer}\r\n")
        f.write("Category = #{track.category}\r\n") if track.category
    end
end

module GameData
    class Track
        attr_reader :id
        attr_reader :filename
        attr_reader :index
        attr_reader :real_name
        attr_reader :official_name
        attr_reader :source_game
        attr_reader :composer
        attr_reader :category

        DATA = {}
        DATA_FILENAME = "tracks.dat"

        extend ClassMethodsSymbols
        include InstanceMethods

        SCHEMA = {
            "Filename"     => [:filename,      "s"],
            "Index"        => [:index,         "u"],
            "DisplayName"  => [:real_name,     "s"],
            "OfficialName" => [:official_name, "s"],
            "SourceGame"   => [:source_game,   "s"],
            "Composer"     => [:composer,      "s"],
            "Category"     => [:category,      "s"],
        }

        def initialize(hash)
            @id            = hash[:id]
            @filename      = hash[:filename]      || ""
            @index         = hash[:index]         || 0
            @real_name     = hash[:real_name]     || "???"
            @official_name = hash[:official_name] || nil
            @source_game   = hash[:source_game]   || nil
            @composer      = hash[:composer]      || "???"
            @category      = hash[:category]      || nil
            @defined_in_extension = hash[:defined_in_extension] || false
        end

        # @return [String] the display name of this track
        def name
            return @real_name
        end

        # Yields all tracks in display order (by Index, then by id for ties).
        def self.each
            keys = self::DATA.keys.sort { |a, b|
                dataA = self::DATA[a]
                dataB = self::DATA[b]
                next dataA.index == dataB.index ? (dataA.id <=> dataB.id) : (dataA.index <=> dataB.index)
            }
            keys.each { |key| yield self::DATA[key] }
        end
    end
end
