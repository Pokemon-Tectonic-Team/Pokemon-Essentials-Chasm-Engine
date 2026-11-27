DebugMenuCommands.register("mysterygift", {
    "parent"      => "othermenu",
    "name"        => _INTL("Manage Mystery Gifts"),
    "description" => _INTL("Edit and enable/disable Mystery Gifts."),
    "always_show" => true,
    "effect"      => proc {
        pbManageMysteryGifts
    }
  })

DebugMenuCommands.register("extracttext", {
  "parent"      => "othermenu",
  "name"        => _INTL("Extract Text"),
  "description" => _INTL("Extract all text in the game to a single file for translating."),
  "always_show" => true,
  "effect"      => proc {
      pbExtractText
  }
})

DebugMenuCommands.register("extractuntranslatedtext", {
  "parent"      => "othermenu",
  "name"        => _INTL("Extract Untranslated Text"),
  "description" => _INTL("Extract all text in the game that isn't translated for the current language."),
  "always_show" => true,
  "effect"      => proc {
      pbExtractText(true)
  }
})

DebugMenuCommands.register("extractcombinedtext", {
  "parent"      => "othermenu",
  "name"        => _INTL("Extract Combined Text"),
  "description" => _INTL("Extract all text in the game, including both translated and untranslated text."),
  "always_show" => true,
  "effect"      => proc {
      pbExtractText(true, true)
  }
})

DebugMenuCommands.register("compiletext", {
  "parent"      => "othermenu",
  "name"        => _INTL("Compile Text"),
  "description" => _INTL("Import text and converts it into a language file."),
  "always_show" => true,
  "effect"      => proc {
      begin
          pbCompileTextUI
      rescue StandardError
          pbPrintException($!)
      end
  }
})

DebugMenuCommands.register("compiledata", {
  "parent"      => "othermenu",
  "name"        => _INTL("Compile Data"),
  "description" => _INTL("Fully compile all data."),
  "always_show" => true,
  "effect"      => proc {
      msgwindow = pbCreateMessageWindow
      Compiler.compile_all(true) { |msg|
          pbMessageDisplay(msgwindow, msg, false)
          echoln(msg)
      }
      pbMessageDisplay(msgwindow, _INTL("All game data was compiled."))
      pbDisposeMessageWindow(msgwindow)
  }
})

DebugMenuCommands.register("createpbs", {
  "parent"      => "othermenu",
  "name"        => _INTL("Create PBS File(s)"),
  "description" => _INTL("Choose one or all PBS files and create it."),
  "always_show" => true,
  "effect"      => proc {
      cmd = 0
      cmds = [
          _INTL("[Create all]"),
          "abilities.txt",
          "berryplants.txt",
          "connections.txt",
          "encounters.txt",
          "items.txt",
          "metadata.txt",
          "moves.txt",
          "phone.txt",
          "pokemon.txt",
          "pokemonforms.txt",
          "regionaldexes.txt",
          "ribbons.txt",
          "shadowmoves.txt",
          "townmap.txt",
          "trainerlists.txt",
          "trainers.txt",
          "trainertypes.txt",
          "types.txt"
      ]
      loop do
          cmd = pbShowCommands(nil, cmds, -1, cmd)
          case cmd
          when 0  then Compiler.write_all
          when 1  then Compiler.write_abilities
          when 2  then Compiler.write_berry_plants
          when 3  then Compiler.write_connections
          when 4  then Compiler.write_encounters
          when 5  then Compiler.write_items
          when 6  then Compiler.write_metadata
          when 7  then Compiler.write_moves
          when 8  then Compiler.write_phone
          when 9  then Compiler.write_pokemon
          when 10 then Compiler.write_pokemon_forms
          when 11 then Compiler.write_regional_dexes
          when 12 then Compiler.write_ribbons
          when 13 then Compiler.write_shadow_movesets
          when 14 then Compiler.write_town_map
          when 15 then Compiler.write_trainer_lists
          when 16 then Compiler.write_trainers
          when 17 then Compiler.write_trainer_types
          when 18 then Compiler.write_types
          else break
          end
          pbMessage(_INTL("File written."))
      end
  }
})

DebugMenuCommands.register("renamesprites", {
  "parent"      => "othermenu",
  "name"        => _INTL("Rename Old Sprites"),
  "description" => _INTL("Renames and moves Pokémon/item/trainer sprites from their old places."),
  "always_show" => true,
  "effect"      => proc {
      SpriteRenamer.convert_files
  }
})

DebugMenuCommands.register("invalidtiles", {
  "parent"      => "othermenu",
  "name"        => _INTL("Fix Invalid Tiles"),
  "description" => _INTL("Scans all maps and erases non-existent tiles."),
  "always_show" => true,
  "effect"      => proc {
      pbDebugFixInvalidTiles
  }
})

DebugMenuCommands.register("settimetohour", {
  "parent"      => "othermenu",
  "name"        => _INTL("Set time to hour"),
  "description" => _INTL("Set the unreal time to the next instance of some hour on the 24-hour clock."),
  "effect"      => proc { |_sprites, _viewport|
      params = ChooseNumberParams.new
      params.setMaxDigits(2)
      params.setDefaultValue(0)
      params.setRange(1, 24)
      chosenHour = pbChooseNumber(nil, params)
      UnrealTime.advance_to(chosenHour - 1, 0, 0)
      pbMessage(_INTL("Advancing the unreal time system to hour #{chosenHour}"))
  }
}
)

DebugMenuCommands.register("deregisterpartner", {
  "parent"      => "othermenu",
  "name"        => _INTL("Reregister Partner"),
  "description" => _INTL("Get rid of any partner trainer joining your battles."),
  "effect"      => proc {
      pbDeregisterPartner
      pbMessage(_INTL("De-Registered partner."))
  }
})

DebugMenuCommands.register("renamemovefrominput", {
"parent"      => "othermenu",
"name"        => _INTL("Rename Move From Input"),
"description" => _INTL("Rename an existing move in moves, species, forms, and trainers PBS files based on user input."),
"effect"      => proc {
    oldMoveInternalName = pbEnterText(_INTL("Enter move internal name."), 0, 20)
    next if oldMoveInternalName == ""
    newMoveInternalName = pbEnterText(_INTL("Enter the move's new internal name."), 0, 20)
    next if newMoveInternalName == ""
    newMoveInternalName = newMoveInternalName.gsub(" ", "").upcase
    newMoveDisplayName = pbEnterText(_INTL("Enter the move's new display name."), 0, 20)
    next if newMoveDisplayName == ""

    renameMoves({ oldMoveInternalName => [newMoveInternalName, newMoveDisplayName] })

    Compiler.write_moves

    echoln("Compiling species data")
    Compiler.write_pokemon
    Compiler.write_pokemon_forms

    echoln("Compiling trainer data")
    Compiler.write_trainers

    echoln("Compiling avatar data")
    Compiler.write_avatars

    pbMessage(_INTL("Rename completed."))
}
})

DebugMenuCommands.register("renamemovefromfile", {
  "parent"      => "othermenu",
  "name"        => _INTL("Rename Moves From File"),
  "description" => _INTL("Rename an existing move in moves, species, forms, and trainers PBS files based on PBS/move_renames.txt."),
  "effect"      => proc {
      begin
          renamingHash = getRenamedMovesBatch

          renameMoves(renamingHash)

          Compiler.write_moves

          echoln("Writing species data")
          Compiler.write_pokemon
          Compiler.write_pokemon_forms

          echoln("Writing trainer data")
          Compiler.write_trainers

          echoln("Writing avatar data")
          Compiler.write_avatars
          pbMessage(_INTL("Mass rename completed."))

          pbMessage("Create a new move rename save conversion, and rename \"move_renames.txt\" to \"move_renames_{X}.txt\" " \
                    "where {X} is the next highest number of all files you see " \
                    "(e.g. If you see a \"move_renames_2.txt\", rename yours to \"move_renames_3\".txt)")
          pbMessage(_INTL("Or tell a programmer to do it for you :)"))
      rescue StandardError
          pbPrintException($!)
      end
  }
})

DebugMenuCommands.register("saveoldinator", {
  "parent"      => "othermenu",
  "name"        => _INTL("Set save to older version"),
  "description" => _INTL("Set this save to an older version, for conversion testing."),
  "always_show" => true,
  "effect"      => proc {
      versionNumber = pbEnterText(_INTL("Enter game version."), 0, 20)
      setSaveVersion(versionNumber)
      pbMessage(_INTL("Save has been converted to {1}, please close your game.", versionNumber))
  }
})

def setSaveVersion(versionNumber)
    save_data = SaveData.get_data_from_file(SaveData::FILE_PATH)
    save_data[:game_version] = versionNumber
    File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(save_data, file) }
end

def getRenamedMovesBatch(version = -1)
    renamingHash = {}
    if version == -1
        filename = "PBS/move_renames.txt"
    else
        filename = "PBS/move_renames_#{version}.txt"
    end
    File.open(filename, "rb") { |f|
        FileLineData.file = filename
        lineno = 1
        f.each_line { |line|
            if lineno == 1 && line[0].ord == 0xEF && line[1].ord == 0xBB && line[2].ord == 0xBF
                line = line[3, line.length - 3]
            end
            line.sub!(/\s*\#.*$/, "")
            line.sub!(/^\s+/, "")
            line.sub!(/\s+$/, "")
            if !line[/^\#/] && !line[/^\s*$/]
                FileLineData.setLine(line, lineno)
                line_items = line.split(",")
                renamingHash[line_items[0]] = [line_items[1], line_items[2]]
            end
            lineno += 1
        }
    }
    return renamingHash
end

def renameMoves(renamingHash)
    renamingHash.delete_if { |key, value|
        oldMoveData = nil
        begin
            oldMoveData = GameData::Move.get(key.to_sym)
        rescue StandardError
            # Nothing
        end
        if oldMoveData.nil?
            echoln("No move with the internal name #{key} was found.")
            next true
        end
        if !value[0][/^(?![0-9])\w+$/]
            echoln("New internal name #{value[0]} must contain only letters, digits, and underscores and can't begin with a number.")
        end
        next false
    }

    # Construct move hash
    renamingHash.each do |oldMoveName, newMoveNames|
        oldMoveData = GameData::Move.get(oldMoveName.to_sym)
        move_hash = {
          :id_number        => oldMoveData.id_number,
          :id               => newMoveNames[0].to_sym,
          :name             => newMoveNames[1],
          :function_code    => oldMoveData.function_code,
          :base_damage      => oldMoveData.base_damage,
          :type             => oldMoveData.type,
          :category         => oldMoveData.category,
          :accuracy         => oldMoveData.accuracy,
          :total_pp         => oldMoveData.total_pp,
          :effect_chance    => oldMoveData.effect_chance,
          :target           => oldMoveData.target,
          :priority         => oldMoveData.priority,
          :flags            => oldMoveData.flags,
          :description      => oldMoveData.description,
          :animation_move   => oldMoveData.animation_move,
          :primeval         => oldMoveData.primeval,
          :cut              => oldMoveData.cut,
          :tectonic_new     => oldMoveData.tectonic_new,
          :zmove            => oldMoveData.zmove,
        }
        # Add move's data to records
        GameData::Move::DATA.delete(oldMoveData.id)
        GameData::Move::DATA.delete(oldMoveData.id_number)
        GameData::Move.register(move_hash)
    end
    # GameData::Move.save

    renameMovesInArray = proc { |move|
        if renamingHash.key?(move.to_s)
            next renamingHash[move.to_s][0].to_sym
        else
            next move
        end
    }

    GameData::Species.each do |species_data|
        levelUpMoves = species_data.moves.map { |moveEntry| [moveEntry[0], renameMovesInArray.call(moveEntry[1])] }
        tutorMoves = species_data.tutor_moves.map(&renameMovesInArray)
        lineMoves = species_data.line_moves.map(&renameMovesInArray)
        next if levelUpMoves == species_data.moves && tutorMoves == species_data.tutor_moves && lineMoves == species_data.line_moves
        echoln("Modifying #{species_data.real_name}")

        new_moves = { :moves => levelUpMoves, :tutor_moves => tutorMoves, :line_moves => lineMoves }
        new_species_data = GameData::Species.register(species_data.registration_hash.merge(new_moves))
        new_species_data.earliest_available = species_data.earliest_available
        new_species_data.earliest_available_normal = species_data.earliest_available_normal
    end
    # GameData::Species.save

    GameData::Trainer.each do |trainer_data|
        new_pokemon = trainer_data.pokemon.map do |party_member|
            renamed_member = party_member.clone
            renamed_member[:moves] = party_member[:moves].map(&renameMovesInArray) if party_member[:moves]
            next renamed_member
        end
        new_trainer_hash = {
          :id                 => trainer_data.id,
          :id_number          => trainer_data.id_number,
          :trainer_type       => trainer_data.trainer_type,
          :name               => trainer_data.real_name,
          :name_for_hashing   => trainer_data.name_for_hashing,
          :trainer_type_label => trainer_data.trainer_type_label,
          :version            => trainer_data.version,
          :items              => trainer_data.items,
          :lose_text          => trainer_data.real_lose_text,
          :pokemon            => new_pokemon,
          :policies           => trainer_data.policies,
          :flags              => trainer_data.flags,
          :extends_class      => trainer_data.extendsClass,
          :extends_name       => trainer_data.extendsName,
          :extends_version    => trainer_data.extendsVersion,
          :removed_pokemon    => trainer_data.removedPokemon,
          :monument_trainer   => trainer_data.monumentTrainer,
          :defined_in_extension => trainer_data.defined_in_extension,
        }
        GameData::Trainer.register(new_trainer_hash)
    end
    # GameData::Trainer.save

    GameData::Avatar.each do |avatar_data|
        newMoves1 = avatar_data.moves1.map(&renameMovesInArray)
        newMoves2 = avatar_data.moves2.map(&renameMovesInArray)
        newMoves3 = avatar_data.moves3.map(&renameMovesInArray)
        newMoves4 = avatar_data.moves4.map(&renameMovesInArray)
        newMoves5 = avatar_data.moves5.map(&renameMovesInArray)
        new_avatar_hash = {
          :id                   => avatar_data.id,
          :id_number            => avatar_data.id_number,
          :species              => avatar_data.species,
          :version              => avatar_data.version,
          :turns                => avatar_data.num_turns,
          :form                 => avatar_data.form,
          :moves1               => newMoves1,
          :moves2               => newMoves2,
          :moves3               => newMoves3,
          :moves4               => newMoves4,
          :moves5               => newMoves5,
          :abilities            => avatar_data.abilities,
          :items                => avatar_data.items,
          :hp_mult              => avatar_data.hp_mult,
          :dmg_mult             => avatar_data.dmg_mult,
          :dmg_resist           => avatar_data.dmg_resist,
          :health_bars          => avatar_data.num_health_bars,
          :aggression           => avatar_data.aggression,
          :pit_avatar           => avatar_data.pit_avatar,
          :defined_in_extension => avatar_data.defined_in_extension,
        }
        GameData::Avatar.register(new_avatar_hash)
    end
    # GameData::Avatar.save
end
