DebugMenuCommands.register("jukeboxmarkallheard", {
    "parent"      => "othermenu",
    "name"        => _INTL("Mark all tracks heard"),
    "description" => _INTL("Add every track in the Jukebox database to the heard list."),
    "effect"      => proc {
        GameData::Track.each { |t| pbMarkTrackHeard(t.filename) }
        pbMessage(_INTL("All {1} tracks marked as heard.", $heard_tracks.length))
    }
})

DebugMenuCommands.register("jukeboxmarkallunheard", {
    "parent"      => "othermenu",
    "name"        => _INTL("Mark all tracks unheard"),
    "description" => _INTL("Clear the heard tracks list."),
    "effect"      => proc {
        $heard_tracks.clear
        pbMessage(_INTL("Heard tracks list cleared."))
    }
})
