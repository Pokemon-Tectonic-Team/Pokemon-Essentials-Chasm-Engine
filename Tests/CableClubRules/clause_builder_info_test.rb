# Covers the in-game ruleset builder's metadata contract: every class listed
# in POKEMON_RULE_CLASSES/TEAM_RULE_CLASSES/LEVEL_ADJUSTMENT_CLASSES
# (PokemonRules.rb/TeamRules.rb/LevelAdjustments.rb) must respond to
# self.builder_name/self.builder_desc/self.builder_args with well-formed
# values, and those lists themselves must be populated by the
# PokemonRuleMetadata/TeamRuleMetadata/LevelAdjustmentMetadata
# extend-to-register hooks rather than a hand-maintained array - cheap
# regression coverage that catches a class missing its metadata methods, or
# a metadata module that silently stopped registering, without needing to
# exercise the actual (untestable-here) interactive UI built on top of it.
require_relative "test_helper"

class ClauseBuilderInfoTest < Minitest::Test
  ALL_MANIFESTS = {
    "POKEMON_RULE_CLASSES" => POKEMON_RULE_CLASSES,
    "TEAM_RULE_CLASSES" => TEAM_RULE_CLASSES,
    "LEVEL_ADJUSTMENT_CLASSES" => LEVEL_ADJUSTMENT_CLASSES,
  }
  VALID_ARG_TYPES = [:int, :level, :tenths, :species_list, :item_list, :move_list]

  def test_every_manifest_class_has_well_formed_builder_metadata
    ALL_MANIFESTS.each do |manifest_name, classes|
      classes.each do |klass|
        assert klass.respond_to?(:builder_name), "#{klass} (in #{manifest_name}) has no builder_name"
        assert klass.respond_to?(:builder_desc), "#{klass} (in #{manifest_name}) has no builder_desc"
        assert klass.respond_to?(:builder_args), "#{klass} (in #{manifest_name}) has no builder_args"
        refute_empty klass.builder_name, "#{klass}'s builder_name is empty"
        refute_empty klass.builder_desc, "#{klass}'s builder_desc is empty"
        args = klass.builder_args
        assert_kind_of Array, args, "#{klass}'s builder_args isn't an Array"
        args.each do |arg|
          assert_kind_of Array, arg, "#{klass} has a malformed arg entry"
          arg_type, label = arg
          assert_includes VALID_ARG_TYPES, arg_type, "#{klass} has an unrecognized arg type #{arg_type.inspect}"
          refute_empty label, "#{klass} has an arg with no label"
        end
      end
    end
  end

  # PokemonRuleMetadata/TeamRuleMetadata/LevelAdjustmentMetadata's whole
  # point is that nothing needs to remember to add a class to these lists by
  # hand - so confirm they're actually non-empty (a typo'd "extend" that
  # silently failed to register anything would otherwise pass every other
  # test in this file vacuously, since an empty list has no classes to fail
  # the metadata checks above).
  def test_manifests_are_actually_populated
    ALL_MANIFESTS.each do |manifest_name, classes|
      refute_empty classes, "#{manifest_name} is empty - did its extend-to-register hook break?"
    end
  end

  def test_manifests_have_no_duplicate_classes
    ALL_MANIFESTS.each do |manifest_name, classes|
      assert_equal classes.uniq.length, classes.length, "#{manifest_name} lists the same class twice"
    end
  end
end
