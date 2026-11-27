require_relative "../../support/test_helper"

class TrainerTest < Minitest::Test
    # The monument trainer list is a class instance variable, which the per-test reset doesn't
    # restore. No trainer is registered at load, so the list starts empty.
    def teardown
        GameData::Trainer.monumentTrainers.clear
    end

    def register_trainer(name, monument_trainer: true, lose_text: "...")
        return GameData::Trainer.register({
            id: [:LEADER, name, 0], id_number: name.length, trainer_type: :LEADER, name: name, version: 0,
            lose_text: lose_text, monument_trainer: monument_trainer
        })
    end

    def test_registering_a_monument_trainer_adds_it_to_the_monument_trainers
        ann = register_trainer("Ann")
        bert = register_trainer("Bert")

        assert_equal [ann, bert], GameData::Trainer.getMonumentTrainers
    end

    def test_a_trainer_registered_over_another_takes_its_place_among_the_monument_trainers
        register_trainer("Ann")

        replacement = register_trainer("Ann", lose_text: "Again!")

        assert_equal [replacement], GameData::Trainer.getMonumentTrainers
    end

    def test_a_replaced_monument_trainer_that_is_no_longer_one_leaves_the_monument_trainers
        register_trainer("Ann")

        register_trainer("Ann", monument_trainer: false)

        assert_empty GameData::Trainer.monumentTrainers
    end
end
