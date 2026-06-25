# Shared setup for the standalone Cable Club Rules tests in this directory.
#
# These run under plain `ruby`, outside the actual game engine - there's a
# separate in-engine headless battle test framework ("Chasm Testing") on
# another branch, but hooking these tests into it would need CLI args added
# to the game itself, which is out of scope for now. So this
# file stubs just enough of Pokemon Essentials (Settings, GameData, _INTL,
# a minimal Pokemon double) for the actual Rules files to load and run.
#
# Run an individual file with `ruby some_test.rb`, or everything with
# `ruby run_all.rb`.

require "minitest/autorun"
require "tempfile"

def _INTL(*args)
  fmt = args.shift
  return fmt.gsub(/\{(\d+)\}/) { args[$1.to_i - 1].to_s }
end

module Settings
  MAX_PARTY_SIZE = 6
end

module GameData
  module GrowthRate
    def self.max_level; return 100; end
  end

  ItemRecord = Struct.new(:name)
  ITEM_DATA = {
    SOULDEW: ItemRecord.new("Soul Dew"),
    LEFTOVERS: ItemRecord.new("Leftovers"),
  }
  module Item
    def self.get(id); return GameData::ITEM_DATA.fetch(id, ItemRecord.new(id.to_s)); end
  end

  MoveRecord = Struct.new(:name, :is_empowered) do
    def empoweredMove?; return is_empowered; end
  end
  MOVE_DATA = {
    JUDGMENT: MoveRecord.new("Judgment", true),
    THUNDERBOLT: MoveRecord.new("Thunderbolt", false),
    SONICBOOM: MoveRecord.new("Sonic Boom", false),
    DRAGONRAGE: MoveRecord.new("Dragon Rage", false),
  }
  module Move
    def self.get(id); return GameData::MOVE_DATA.fetch(id, MoveRecord.new(id.to_s, false)); end
  end

  SpeciesRecord = Struct.new(:name, :isLegendary?)
  SPECIES_DATA = {
    PIKACHU: SpeciesRecord.new("Pikachu", false),
    CHARMANDER: SpeciesRecord.new("Charmander", false),
    MEWTWO: SpeciesRecord.new("Mewtwo", true),
    MEW: SpeciesRecord.new("Mew", true),
    ARCEUS: SpeciesRecord.new("Arceus", true),
  }
  module Species
    def self.get(id); return GameData::SPECIES_DATA.fetch(id, SpeciesRecord.new(id.to_s, false)); end
    def self.each; end
  end
end

class BattleTower; end
DISABLE_SKETCH_ONLINE = true

REPO_ROOT = File.expand_path("../..", __dir__)
CABLE_CLUB_DIR = File.join(REPO_ROOT, "Plugins", "Chasm Cable Club")
BATTLE_FRONTIER_DIR = File.join(REPO_ROOT, "Plugins", "Chasm Battle Frontier")

require_relative "#{REPO_ROOT}/Plugins/Chasm Other/Utilities/Utilities.rb"

# Load order matters here: Battle Frontier's meta.txt requires Chasm Cable
# Club, so its Rules subclass PokemonRuleSet/BattleRule etc. defined there.
require_relative "#{CABLE_CLUB_DIR}/Rules/LevelAdjustments.rb"
require_relative "#{CABLE_CLUB_DIR}/Rules/PokemonRules.rb"
require_relative "#{CABLE_CLUB_DIR}/Rules/TeamRules.rb"
require_relative "#{CABLE_CLUB_DIR}/Rules/Rulesets.rb"
require_relative "#{CABLE_CLUB_DIR}/[001] Cable Club Client/001_Connection_Communication.rb"
require_relative "#{CABLE_CLUB_DIR}/[001] Cable Club Client/007_CableClub_Rules.rb"
require_relative "#{CABLE_CLUB_DIR}/[001] Cable Club Client/002_CableClub.rb"
require_relative "#{CABLE_CLUB_DIR}/[001] Cable Club Client/005_CableClubAdditions.rb"

require_relative "#{BATTLE_FRONTIER_DIR}/Rules/Rulesets.rb"
require_relative "#{BATTLE_FRONTIER_DIR}/Rules/BattleRules.rb"
require_relative "#{BATTLE_FRONTIER_DIR}/Rules/LevelAdjustments.rb"
require_relative "#{BATTLE_FRONTIER_DIR}/Rules/ChallengeRules.rb"

# Minimal Pokemon test double - covers what the PokemonRules/TeamRules
# classes actually touch (name/species/level/item/moves), not a full
# Pokemon. Subclasses the Pokemon stub so HeightRestriction/WeightRestriction's
# `pkmn.is_a?(Pokemon)` branch behaves the same as it would for a real one.
class Pokemon; end

Move = Struct.new(:id)

class Pkmn < Pokemon
  attr_accessor :name, :species, :level, :firstItem, :moves

  def initialize(name, species, level: 50, firstItem: nil, moves: [])
    @name = name
    @species = species
    @level = level
    @firstItem = firstItem
    @moves = moves
  end

  def egg?; return false; end
  def hasItem?(check = nil); return check ? @firstItem == check : !@firstItem.nil?; end
  def hasMove?(move_id); return @moves.any? { |m| m.id == move_id }; end
  def isSpecies?(sym); return @species == sym; end
  def species_data; return GameData::Species.get(@species); end
  def able?(*); return true; end
end
