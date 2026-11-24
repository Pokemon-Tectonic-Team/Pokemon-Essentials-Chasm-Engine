require_relative "../support/test_helper"

class GameDataClassMethodsTest < Minitest::Test
    def test_register_stores_the_record_under_its_id_and_id_number
        record = GameData::Type.register({ id: :FIRE, id_number: 3 })

        assert_same record, GameData::Type::DATA[:FIRE]
        assert_same record, GameData::Type::DATA[3]
    end

    def test_register_without_an_id_number_stores_the_record_under_its_id_only
        record = GameData::Type.register({ id: :FIRE })

        assert_equal({ FIRE: record }, GameData::Type::DATA)
    end

    def test_each_yields_each_record_once
        GameData::Type.register({ id: :FIRE })
        GameData::Type.register({ id: :WATER, id_number: 1 })

        yielded = []
        GameData::Type.each { |type| yielded << type.id }

        assert_equal [:FIRE, :WATER], yielded.sort
    end
end
