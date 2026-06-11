$heard_tracks = []

SaveData.register(:heard_tracks) do
    save_value { $heard_tracks }
    load_value { |value| $heard_tracks = value || [] }
    new_game_value { [] }
end

def pbMarkTrackHeard(filename)
    $heard_tracks.push(filename) unless $heard_tracks.include?(filename)
end

def pbTrackHeard?(filename)
    return $heard_tracks.include?(filename)
end
