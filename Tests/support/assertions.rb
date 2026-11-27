# Assertions of the harness's own, included into every test.
module Assertions
    # Compares the readers named by expected's keys with the values given for them, as one
    # assertion, so a failure shows every reader that differs at once
    def assert_attributes(expected, object, message = nil)
        actual = expected.keys.to_h { |name| [name, object.public_send(name)] }
        assert_equal expected, actual, message
    end
end
