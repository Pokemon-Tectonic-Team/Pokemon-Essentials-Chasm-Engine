require_relative "harness_error"

# Registers real GameData records for a test, through each class's own register, with defaults
# for the fields a record can't do without. Included into every test, so a test calls
# create_type(id: :FIRE, ...) and gets back the registered record.
module RecordFactories
    def create_type(**attributes)
        RecordFactories.register(GameData::Type, { id_number: RecordFactories.next_id_number(GameData::Type) }, attributes)
    end

    def create_ability(**attributes)
        RecordFactories.register(GameData::Ability, {}, attributes)
    end

    def create_item(**attributes)
        RecordFactories.register(GameData::Item, {}, attributes)
    end

    def create_move(**attributes)
        RecordFactories.register(GameData::Move, { type: :NORMAL, category: 0, base_damage: 0 }, attributes)
    end

    def create_species(**attributes)
        RecordFactories.register(GameData::Species, { type1: :NORMAL }, attributes)
    end

    # Lists no form moves for each species. A species' learnable moves include its forms' form
    # moves, which compile_pokemon_forms lists for every species, so they can't be worked out
    # without the entry.
    def without_form_moves(*species)
        species.each { |id| GameData::Species::FORM_SPECIFIC_MOVES[id] = [] }
    end

    class << self
        # Registers a klass record from attributes over defaults, with the id capitalised as its
        # name unless one is given, and returns it as klass.get finds it. Refuses a missing id, and
        # an id or id_number klass already holds.
        def register(klass, defaults, attributes)
            id = attributes[:id]
            raise HarnessError, "a #{klass} record needs an id" if id.nil?

            hash = { name: id.to_s.capitalize }.merge(defaults, attributes)
            taken = [id, hash[:id_number]].compact.find { |key| klass::DATA.key?(key) }
            raise HarnessError, "#{klass} already has a record under #{taken.inspect}" unless taken.nil?

            klass.register(hash)
            klass.get(id)
        end

        # One above the highest id_number klass holds, or 0 when it holds none.
        def next_id_number(klass)
            (klass::DATA.keys.grep(Integer).max || -1) + 1
        end
    end
end
