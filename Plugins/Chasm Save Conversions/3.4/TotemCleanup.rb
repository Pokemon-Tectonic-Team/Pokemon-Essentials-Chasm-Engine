SaveData.register_conversion(:waypoints_cleanup_340) do
  game_version '3.4.0'
  display_title 'Cleaning up totem waypoints.'
  to_all do |save_data|
     if save_data.has_key?(:waypoints_tracker)
      tracker = save_data[:waypoints_tracker]
      tracker.resetMapPositionHash
     end
  end
end