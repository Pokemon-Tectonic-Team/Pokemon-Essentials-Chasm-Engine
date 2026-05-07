require 'stringio'

# Bytes required enum
module BytesRequired
  U8 = 1
  U16 = 2
  U32 = 4
end

POKE_PARTY_FORMAT_VERSION = 1
VERSION_BYTES = 4

# Byte protocol shift
ENCODING_SHIFT = 5 # The first 5 bits are reserved (unused in the new format, they represent the major version in the old one)
VERSION_MAJOR_SHIFT = 0
VERSION_MINOR_SHIFT = 5
VERSION_PATCH_SHIFT = 10
VERSION_DEV_SHIFT = 15 # End of header - u16
STYLE_HP_SHIFT = 0
STYLE_ATK_SHIFT = 5
STYLE_DEF_SHIFT = 10
STYLE_SDEF_SHIFT = 15
STYLE_SPEED_SHIFT = 20
LEVEL_SHIFT = 25 # Stats and level fit into one u32

# Byte protocol masks
ENCODING_MASK = 0xe0
VERSION_DEV_MASK = 0b1 << VERSION_DEV_SHIFT
STYLE_HP_MASK = 0b11111 << STYLE_HP_SHIFT
STYLE_ATK_MASK = 0b11111 << STYLE_ATK_SHIFT
STYLE_DEF_MASK = 0b11111 << STYLE_DEF_SHIFT
STYLE_SDEF_MASK = 0b11111 << STYLE_SDEF_SHIFT
STYLE_SPEED_MASK = 0b11111 << STYLE_SPEED_SHIFT
LEVEL_MASK = 0b1111111 << LEVEL_SHIFT

def load_team_code()
  code = encode_team($Trainer.party)
  domain = Settings::DEV_VERSION ? "tectonic-dev" : "tectonic"
  System.launch("https://#{domain}.alphakretin.com/teambuilder?team=#{code}")
  pbMessage(_INTL("Pokémon team opened in team builder website."))
end

# Encodes the string id as (num chars (u8)) (u8 value 1, 2, 3...)
def encode_string_id(id, u8s)
  id_str = id.to_s
  u8s.push(id_str.length)
  id_str.each_byte { |byte| u8s.push(byte) }
end

# Encodes style points and level into a u32
def encode_stats(mon)
  sp = mon.ev
  stats = 0
  stats |= (sp[:HP] << STYLE_HP_SHIFT) & STYLE_HP_MASK
  stats |= (sp[:ATTACK] << STYLE_ATK_SHIFT) & STYLE_ATK_MASK
  stats |= (sp[:DEFENSE] << STYLE_DEF_SHIFT) & STYLE_DEF_MASK
  stats |= (sp[:SPECIAL_DEFENSE] << STYLE_SDEF_SHIFT) & STYLE_SDEF_MASK
  stats |= (sp[:SPEED] << STYLE_SPEED_SHIFT) & STYLE_SPEED_MASK
  stats |= (mon.level << LEVEL_SHIFT) & LEVEL_MASK
  return stats
end

def encode_team(party)
  buffer = StringIO.new

  # Header
  poke_party_encoding_u8 = 0 # Encoding is always 0 in this context
  poke_party_version_u8 = POKE_PARTY_FORMAT_VERSION
  version_split = Settings::GAME_VERSION.split(".")
  version_u16 = Settings::DEV_VERSION ? VERSION_DEV_MASK : 0
  version_u16 |= (version_split[0].to_i & 0x1f) << VERSION_MAJOR_SHIFT
  version_u16 |= (version_split[1].to_i & 0x1f) << VERSION_MINOR_SHIFT
  version_u16 |= (version_split[2].to_i & 0x1f) << VERSION_PATCH_SHIFT

  data = [
    [poke_party_version_u8, BytesRequired::U8],
    [poke_party_encoding_u8, BytesRequired::U8],
    [version_u16, BytesRequired::U16]
  ]

  party.each do |mon|
    next if mon.nil?

    has_1_item = mon.items.length >= 1 && !mon.items[0].nil?
    has_2_items = mon.items.length == 2 && !mon.items[1].nil?
    stats_u32 = encode_stats(mon)

    u8s = []
    encode_string_id(mon.species, u8s)
    encode_string_id(GameData::Ability.get(mon.ability).id, u8s)
    encode_string_id(has_1_item ? mon.items[0] : "", u8s)
    encode_string_id(mon.itemTypeChosen || "", u8s)
    encode_string_id(has_2_items ? mon.items[1] : "", u8s)
    mon.moves.each do |move|
      encode_string_id(move ? move.id : "", u8s)
    end
    # Pad moves if less than 4
    (4 - mon.moves.length).times { encode_string_id("", u8s) } if mon.moves.length < 4
    u8s.push(mon.form)

    u8s.each { |x| data.push([x, BytesRequired::U8]) }
    data.push([stats_u32, BytesRequired::U32])
  end

  # Write data to buffer
  data.each do |value, bytes_required|
    case bytes_required
    when BytesRequired::U8
      buffer.write([value].pack('C'))
    when BytesRequired::U16
      buffer.write([value].pack('n'))
    when BytesRequired::U32
      buffer.write([value].pack('N'))
    end
  end

  # Convert to URL-safe base64
  code = [buffer.string].pack('m0')
  code.gsub!("+", "-")
  code.gsub!("/", "_")
  code.gsub!("=", "")

  return code
end

# Decodes the string id from (num chars (u8)) (u8 value 1, 2, 3...). Returns [id, new_offset]
def decode_string_id(buffer)
  num_chars = buffer.read(1).unpack('C')[0]
  id = num_chars > 0 ? buffer.read(num_chars) : ""
  return id
end

# Decodes style points and level from a u32
def decode_stats(mon, buffer)
  stats = buffer.read(4).unpack('N')[0]
  style_hp = (stats & STYLE_HP_MASK) >> STYLE_HP_SHIFT
  style_atk = (stats & STYLE_ATK_MASK) >> STYLE_ATK_SHIFT
  style_def = (stats & STYLE_DEF_MASK) >> STYLE_DEF_SHIFT
  style_sdef = (stats & STYLE_SDEF_MASK) >> STYLE_SDEF_SHIFT
  style_speed = (stats & STYLE_SPEED_MASK) >> STYLE_SPEED_SHIFT
  level = (stats & LEVEL_MASK) >> LEVEL_SHIFT

  mon.ev[:HP] = style_hp
  mon.ev[:ATTACK] = style_atk
  mon.ev[:DEFENSE] = style_def
  mon.ev[:SPECIAL_ATTACK] = style_atk
  mon.ev[:SPECIAL_DEFENSE] = style_sdef
  mon.ev[:SPEED] = style_speed
  mon.level = level

  # force stats to recalculate
  mon.calc_stats
end

def decode_team(code)
  # Convert from URL-safe base64
  code = code.gsub("-", "+").gsub("_", "/")
  code += "=" * ((4 - code.length % 4) % 4)

  buffer = StringIO.new(code.unpack('m')[0])
  party = []

  return party if buffer.size < VERSION_BYTES

  # Read header
  encoding = (buffer.read(1).unpack('C')[0] & ENCODING_MASK) >> ENCODING_SHIFT
  poke_party_version = buffer.read(1).unpack('C')[0]
  version_u16 = buffer.read(2).unpack('n')[0]

  # Only encoding 0 is supported
  return nil if encoding != 0

  # Decode each Pokemon
  while buffer.pos < buffer.size
    mon_id = decode_string_id(buffer)
    ability_id = decode_string_id(buffer)
    item1_id = decode_string_id(buffer)
    item1_type_id = decode_string_id(buffer)
    item2_id = decode_string_id(buffer)
    move1_id = decode_string_id(buffer)
    move2_id = decode_string_id(buffer)
    move3_id = decode_string_id(buffer)
    move4_id = decode_string_id(buffer)
    form = buffer.read(1).unpack('C')[0]

    # Create Pokemon
    species = GameData::Species.get(mon_id.to_sym)
    mon = Pokemon.new(species.id, 1) # Level will be set by decode_stats

    # Set form
    mon.form = form

    # Set ability
    if ability_id.length > 0
      resolved_ability = GameData::Ability.get(ability_id.to_sym).id
      # Find the matching ability_index from species data so it stays consistent
      sp_data = mon.species_data
      index = sp_data.abilities.index(resolved_ability)
      if index
        mon.ability_index = index # Should also set ability automatically
      elsif 
        echoln(_INTL("WARNING: Illegal ability #{ability_id} for species #{mon_id} in team code."))
        mon.ability_index = 0 # Default to first ability index for consistent behaviour
        mon.ability = resolved_ability # Override with illegal ability anyway, but it may cause issues
      end
    else
      mon.ability_index = 0 # Default to first ability index if no ability specified
    end

    # Set items
    mon.items[0] = GameData::Item.get(item1_id.to_sym).id if item1_id.length > 0
    mon.items[1] = GameData::Item.get(item2_id.to_sym).id if item2_id.length > 0

    # Set item type
    mon.itemTypeChosen = GameData::Type.get(item1_type_id.to_sym).id if item1_type_id.length > 0

    # Set moves
    if move1_id.length > 0
      # If we have moves specified, remove level 1 moves so that the Pokemon has only the specified moves
      mon.forget_all_moves
    end
    mon.learn_move(GameData::Move.get(move1_id.to_sym).id) if move1_id.length > 0
    mon.learn_move(GameData::Move.get(move2_id.to_sym).id) if move2_id.length > 0
    mon.learn_move(GameData::Move.get(move3_id.to_sym).id) if move3_id.length > 0
    mon.learn_move(GameData::Move.get(move4_id.to_sym).id) if move4_id.length > 0
    

    # Decode stats (style points and level)
    decode_stats(mon, buffer)

    # roll any traits we have the happiness threshold for so it's not in limbo later
    # any we haven't unlocked will return nil as appropriate
    mon.trait1
    mon.trait2
    mon.trait3
    mon.like
    mon.dislike

    party.push(mon)
  end

  return party
end

def read_team_code()
  filename = "Analysis/teamcode.txt"
  code = IO.read(filename)
  if code.nil?
    pbMessage(_INTL("Could not read team code from file."))
    return
  end
  pokemon = decode_team(code)
  if pokemon.nil?
    pbMessage(_INTL("Unsupported team code format."))
    return
  end
  if pokemon.empty?
    pbMessage(_INTL("Could not decode team from code."))
    return
  end
  # Store current party in PC
  $Trainer.party.each do |mon|
    $PokemonStorage.pbStoreCaught(mon)
  end
  $Trainer.party.clear

  # Add new pokemon to party
  pokemon.each do |mon|
    pbAddToPartySilent(mon)
  end
  pbMessage(_INTL("Team code loaded into party."))
end