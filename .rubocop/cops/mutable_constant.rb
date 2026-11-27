module RuboCop
    module Cop
        module Chasm
            # Style/MutableConstant, except for `DATA = {}`. GameData classes keep their records in
            # a DATA hash that `register` fills and `load` clears and refills, so freezing it
            # would break them. Only an empty hash literal named DATA is skipped, assigned with `=`
            # or `||=`, so a DATA constant holding fixed contents is still checked. The skip
            # applies to any DATA, in or outside GameData.
            #
            #     # good
            #     DATA = {}
            #
            #     # bad
            #     DATA_FILENAME = "trainer_types.dat"
            #     DATA = { a: 1 }
            class MutableConstant < Style::MutableConstant
                def on_casgn(node)
                    return if registry?(node)

                    super
                end

                private

                def registry?(node)
                    return false unless node.name == :DATA

                    value = assigned_value(node)
                    value&.hash_type? && value.pairs.empty?
                end

                # `DATA ||= {}` puts the value on the enclosing or_asgn, not the casgn
                def assigned_value(node)
                    return node.expression if node.expression

                    parent = node.parent
                    parent.children.last if parent&.or_asgn_type?
                end
            end
        end
    end
end
