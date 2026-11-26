require_relative "../support/test_helper"

class GameDataClassMethodsTest < Minitest::Test
    def test_register_stores_the_record_under_its_id_and_id_number
        record = GameData::Type.register({ id: :FIRE, id_number: 3 })

        assert_same record, GameData::Type::DATA[:FIRE]
        assert_same record, GameData::Type::DATA[3]
    end

    def test_register_without_an_id_number_stores_the_record_under_its_id_only
        record = GameData::Type.register({ id: :FIRE })

        assert_equal [:FIRE], GameData::Type::DATA.keys
        assert_same record, GameData::Type::DATA[:FIRE]
    end

    def test_each_yields_each_record_once_in_order_of_id_number
        GameData::Type.register({ id: :FIRE, id_number: 5 })
        GameData::Type.register({ id: :WATER, id_number: 0 })

        yielded = []
        GameData::Type.each { |type| yielded << type.id } # rubocop:disable Style/MapIntoArray -- the test drives each itself; map would test something else

        assert_equal [:WATER, :FIRE], yielded
    end
end
