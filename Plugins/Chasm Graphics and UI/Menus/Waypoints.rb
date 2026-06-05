SaveData.register(:waypoints_tracker) do
	ensure_class :WaypointsTracker
	save_value { $waypoints_tracker }
	load_value { |value| $waypoints_tracker = value }
	new_game_value { WaypointsTracker.new }
end

class WaypointsTracker
	attr_reader :activeWayPoints
	attr_reader :legendsMaterialized
	
	def initialize()
		@activeWayPoints = {}
		@legendsMaterialized = []
		resetMapPositionHash
	end

	def overwriteWaypoint(waypointName,event,newName=nil)
		if @activeWayPoints.has_key?(waypointName) || debugControl
			addWaypoint(newName || waypointName,event)
			deleteWaypoint(waypointName) if newName
		end
	end

	def setWaypoint(waypointName,mapID,wayPointInfo)
		@activeWayPoints[waypointName] = [mapID,wayPointInfo]
		resetMapPositionHash
	end

	def deleteWaypoint(waypointName)
		@activeWayPoints.delete(waypointName)
		resetMapPositionHash
	end

	def deleteAllWaypoints
		@activeWayPoints = {}
		resetMapPositionHash
	end

	def resetMapPositionHash
		@positionHash = nil
	end

	def mapPositionHash
		generateMapPositionHash if @positionHash.nil?
		return @positionHash
	end

	def generateMapPositionHash
		mapPositionHash = {}
		mapInfos = pbLoadMapInfos
		activeWayPoints.each do |waypointName,waypointInfo|
			mapID = waypointInfo[0]
			next unless mapInfos[mapID] # Skip map if it somehow doesn't exist anymore
			eventID = waypointInfo[1]
			mapInfo = mapInfos[mapID]
			event = getEventByID(eventID,mapID)
			next if event.nil?
			eventX = event.x
			eventY = event.y
			
			# Get the most relevant map metadata
			recursiveMapID = mapID
			displayedPosition = nil
			while recursiveMapID >= 1 && displayedPosition.nil?
				map_metadata = GameData::MapMetadata.try_get(recursiveMapID)
				if map_metadata.nil? || map_metadata.town_map_position.nil?
					recursiveMapID = mapInfos[recursiveMapID].parent_id
				else
				  	displayedPosition = map_metadata.town_map_position.clone
				end
			end

			if displayedPosition.nil?
				echoln("ERROR: Cannot figure out where to place waypoint #{waypointName} on map.")
				next
			end

			mapX    = displayedPosition[1]
			mapY    = displayedPosition[2]

			# Shift display position based on event position on map
            unless map_metadata.nil?
                mapsize = map_metadata.town_map_size
                if !mapsize.nil? && mapsize[0] && mapsize[0] > 0
                    sqwidth  = mapsize[0]
                    sqheight = (mapsize[1].length * 1.0 / mapsize[0]).ceil

					mapWidth, mapHeight = MapFactoryHelper.getMapDims(mapID)

                    mapX += (eventX * sqwidth / mapWidth).floor if sqwidth > 1
                    mapY += (eventY * sqheight / mapHeight).floor if sqheight > 1
                end
            end

			displayedPosition[1] = mapX
			displayedPosition[2] = mapY

			mapPositionHash[waypointName] = displayedPosition 
		end

		dupes = mapPositionHash.keys.group_by do |waypointName|
			mapPositionHash[waypointName]
		end.select do |k, v|
			v.length > 1
		end.map(&:last)

		dupes.each do |dupeGroup|
			echoln("Multiple waypoints are rendering on the same map tile!")
			dupeGroup.each do |dupe|
				echoln(dupe)
			end
		end

		@positionHash = mapPositionHash
	end
	
	def getWaypointAtMapPosition(x,y)
		mapPositionHash.each do |waypointName,displayedPosition|
			if displayedPosition[1] == x && displayedPosition[2] == y
				return waypointName
			end
		end
		return nil
	end

	def addWaypoint(waypointName,event)
		if event.is_a?(Array)
			@activeWayPoints[waypointName] = event
		else
			@activeWayPoints[waypointName] = [event.map_id,event.id]
		end
		resetMapPositionHash
	end

	def summonPokemonFromWaypoint(avatarSpecies,waypointEvent)
		$PokemonGlobal.respawnPoint = waypointEvent.id
		speciesDisplayName = GameData::Species.get(avatarSpecies).name
		pbMessage(_INTL("A {1} was created!", speciesDisplayName))
		level = [50,getLevelCap].min
		if pbWildBattleCore(avatarSpecies, level) == 4 # Caught
			$PokemonGlobal.respawnPoint = nil
			return true
		end
		return false
	end
	
	def accessWaypoint(waypointName,waypointEvent,alternateMessage=false)
		if WAYPOINT_REQUIRED_ITEM && !pbHasItem?(WAYPOINT_REQUIRED_ITEM)
			pbMessage(waypointLackingItemMessage)
			return
		end

		@activeWayPoints = {} if @activeWayPoints.nil?
		
		if alternateMessage
			pbMessage(waypointAccessMessageAlternative)
		else
			pbMessage(waypointAccessMessage)
		end
		
		unless @activeWayPoints.has_key?(waypointName)
			pbMessage(waypointRegisterMessage)

			totemGlowSprite = $scene.spriteset.getAnimationForEvent(waypointEvent.id)

			totemGlowSprite.switchAnimationMode(2)

			# Pause for fading
			loop do
				Graphics.update
				Input.update
				pbUpdateSceneMap
				break if totemGlowSprite.animationComplete?
			end

			totemGlowSprite.switchAnimationMode(1)

			# Pause for cool animation
			framesWaited = 0
			loop do
				Graphics.update
				Input.update
				# Intentionally duplicated
				Graphics.update
				Input.update
				pbUpdateSceneMap
				pbSEPlay("Totem activation") if framesWaited == 2
				framesWaited += 1
				break if totemGlowSprite.animationComplete?
			end

			totemGlowSprite.switchAnimationMode(0)

			pbWait(10)
			
			addWaypoint(waypointName,waypointEvent)

            checkForWaypointsAchievement
		end
		
		if @activeWayPoints.length <= 1
			pbMessage(waypointUnableMessage)
		else
			warpByWaypoints
		end
	end

	def warpByWaypoints(skipMessage = false)
		if @activeWayPoints.empty?
			pbMessage(noWaypointsMessage)
			return
		end

		chosenLocation = nil
		chosenKey = nil
		if CHOOSE_BY_LIST
			commands = [_INTL("Cancel")]
			names = @activeWayPoints.sort_by {|key,value| value[0]}.map {|value| value[0]}
			names.delete_if{|name| name == waypointName}
			names.each do |name|
				commands.push(_INTL(name))
			end
			chosen = pbMessage(waypointChooseMessage,commands,0)
			if chosen != 0
				chosenKey = names[chosen-1]
				chosenLocation = @activeWayPoints[chosenKey]
			end
		else
			pbMessage(waypointChooseMessage) unless skipMessage
			chosenKey = nil
			pbFadeOutIn {
				scene = PokemonRegionMap_Scene.new(-1,false)
				screen = PokemonRegionMapScreen.new(scene)
				chosenKey = screen.pbStartWaypointScreen
			}
			chosenLocation = @activeWayPoints[chosenKey] if !chosenKey.nil?
		end

		unless chosenLocation.nil?
			mapID = chosenLocation[0]
			waypointInfo = chosenLocation[1]

			# Old system of storing the specific location
			if waypointInfo.is_a?(Array)
				$game_temp.player_new_map_id = mapID
				$game_temp.player_new_x = waypointInfo[0]
				$game_temp.player_new_y = waypointInfo[1]
				$game_temp.player_new_direction = 2
				$game_temp.transition_processing = true
				$game_temp.transition_name       = ""
			else
				event = getEventByID(waypointInfo,mapID)
				if event.nil? || !event.name.include?(WAYPOINT_EVENT_NAME)
					pbMessage(_INTL("The chosen waypoint is somehow invalid."))
					pbMessage(_INTL("Removing access."))
					@activeWayPoints.delete(chosenKey)
					return
				end
				transferPlayerToEvent(waypointInfo,Up,mapID,[0,1])
			end
			pbSEPlay("Anim/PRSFX- Teleport",100,100)
			$scene.transfer_player
			$game_map.autoplay
			$game_map.refresh
		end
	end

    def checkForWaypointsAchievement(listMissing = false)
        unlockedAll = true
        $waypoints_tracker.eachWaypoint do |event, mapID, waypointName|
            next if @activeWayPoints.has_key?(waypointName)
            unlockedAll = false
            break unless listMissing
			echoln("Missing waypoint: #{waypointName}, #{event.name} (#{event.id}), #{mapID}")
        end
        return unless unlockedAll
        unlockAchievement(:UNLOCK_ALL_WAYPOINTS)
    end

	def isWaypointUnlocked?(waypointName)
		return @activeWayPoints.has_key?(waypointName)
	end

    def eachWaypoint
        mapData = Compiler::MapData.new
        for map_id in mapData.mapinfos.keys.sort
            map = mapData.getMap(map_id)
            next if !map || !mapData.mapinfos[map_id]
            mapName = mapData.mapinfos[map_id].name
            for key in map.events.keys
                event = map.events[key]
                next if !event || event.pages.length == 0
                next if event.name != WAYPOINT_EVENT_NAME
                event.pages.each do |page|
                    page.list.each do |eventCommand|
                        eventCommand.parameters.each do |parameter|
                            next unless parameter.is_a?(String)
                            match = parameter.match(/accessWaypoint\("([a-zA-Z0-9 ']+)"/)
                            if match
                                waypointName = match[1]
                                yield event, map_id, waypointName
                            end
                        end
                    end
                end
            end
        end
    end
end

# Should only be called by the waypoint events themselves
def accessWaypoint(waypointName,avatarSpecies=nil)
	waypointEvent = get_self

	alternate = false

	if avatarSpecies
		alternate = true

		speciesName = GameData::Species.get(avatarSpecies).name
		if pbHasItem?(LEGEND_SUMMONING_KEY_ITEM) || pbHasItem?(LEGEND_SUMMONING_CONSUMABLE_ITEM)
			pbMessage(_INTL("The totem pulses with the frequency of {1}.",speciesName))
		end

		if pbHasItem?(LEGEND_SUMMONING_KEY_ITEM)
			if pbConfirmMessage(_INTL("\\i[{1}]Activate the {2} to summon {3}?", LEGEND_SUMMONING_KEY_ITEM, getItemName(LEGEND_SUMMONING_KEY_ITEM), speciesName))
				if $waypoints_tracker.summonPokemonFromWaypoint(avatarSpecies,waypointEvent)
					pbMessage(_INTL("The totem returns to its original state."))
					pbSetSelfSwitch(waypointEvent.id,'A',false)
					return true
				end
				return false
			end
		elsif pbHasItem?(LEGEND_SUMMONING_CONSUMABLE_ITEM)
			if pbConfirmMessage(_INTL("\\i[{1}]Expend the {2} to summon {3}?", LEGEND_SUMMONING_CONSUMABLE_ITEM, getItemName(LEGEND_SUMMONING_CONSUMABLE_ITEM), speciesName))
				if $waypoints_tracker.summonPokemonFromWaypoint(avatarSpecies,waypointEvent)
					pbMessage(_INTL("The {1} was consumed in the summoning.", getItemName(LEGEND_SUMMONING_CONSUMABLE_ITEM)))
					pbDeleteItem(LEGEND_SUMMONING_CONSUMABLE_ITEM)
					pbMessage(_INTL("The totem returns to its original state."))
					pbSetSelfSwitch(waypointEvent.id,'A',false)
					return true
				end
				return false
			end
		end
	end
	
	$waypoints_tracker.accessWaypoint(waypointName,waypointEvent,alternate)
end

def setWaypoint(waypointName,mapID,wayPointInfo)
	$waypoints_tracker.setWaypoint(waypointName,mapID,wayPointInfo)
end

def overwriteWaypoint(waypointName,event,newName=nil)
	$waypoints_tracker.overwriteWaypoint(waypointName,event,newName=nil)
end

def deleteWaypoint(waypointName)
	$waypoints_tracker.deleteWaypoint(waypointName)
end

def setWaypointSummonable(waypointEventID)
	pbSetSelfSwitch(waypointEventID,'A',true)
end

def isWaypointUnlocked?(waypointName)
	return $waypoints_tracker.isWaypointUnlocked?(waypointName)
end

def totemAuraSummon(species)
	unless pbHasItem?(LEGEND_SUMMONING_KEY_ITEM) || pbHasItem?(LEGEND_SUMMONING_CONSUMABLE_ITEM)
		pbMessage(_INTL("You sense an powerful presence trying to manifest on this spot."))
		pbMessage(_INTL("However, you seem to lack a way to interact with it."))
		return
	end

	speciesName = GameData::Species.get(species).name
	pbMessage(_INTL("An Avatar Totem is partially manifested on this spot."))
	pbMessage(_INTL("It pulses with the frequency of {1}.",speciesName))
	if pbHasItem?(LEGEND_SUMMONING_KEY_ITEM)
		if pbConfirmMessage(_INTL("\\i[{1}]Activate the {2} to summon {3}?", LEGEND_SUMMONING_KEY_ITEM, getItemName(LEGEND_SUMMONING_KEY_ITEM), speciesName))
			if $waypoints_tracker.summonPokemonFromWaypoint(species,get_character(0))
				pbMessage(_INTL("The summoning spot exhausted its energy."))
				setMySwitch('A')
				return true
			end
			return false
		end
	elsif pbHasItem?(LEGEND_SUMMONING_CONSUMABLE_ITEM)
		if pbConfirmMessage(_INTL("\\i[{1}]Expend the {2} to summon {3}?", LEGEND_SUMMONING_CONSUMABLE_ITEM, getItemName(LEGEND_SUMMONING_CONSUMABLE_ITEM), speciesName))
			if $waypoints_tracker.summonPokemonFromWaypoint(species,get_character(0))
				pbMessage(_INTL("The summoning spot exhausted its energy."))
				setMySwitch('A')
				return true
			end
			return false
		end
	end
end

def waypointLackingItemMessage
    return _INTL("A mystical Avatar Totem. You sense it has some purpose, long lost to time.")
end

def waypointAccessMessage
    return _INTL("A mystical Avatar Totem. It pulses with ancient vital energy.")
end

def waypointAccessMessageAlternative
    return _INTL("A mystical Avatar Totem. It pulses with an unusual frequency.")
end

def waypointRegisterMessage
    return _INTL("\\i[SPANNINGBAND]The Spanning Bands glow in sync with the totem.")
end

def waypointUnableMessage
    return _INTL("However, it does not react further. Perhaps you must find more like it?")
end

def waypointChooseMessage
    return _INTL("You sense the connection to the other totems. Choose your warp location.")
end

def noWaypointsMessage
    return _INTL("There are no active totems to warp to.")
end

CHOOSE_BY_LIST = false
WAYPOINT_EVENT_NAME = "AvatarTotem"
WAYPOINT_REQUIRED_ITEM = :SPANNINGBAND
LEGEND_SUMMONING_CONSUMABLE_ITEM = :PRIMALBEAD
LEGEND_SUMMONING_KEY_ITEM = :PRIMALCLAY