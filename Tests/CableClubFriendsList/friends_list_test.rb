# Standalone test for CableClubFriendsList (issue #493 - the Cable Club's
# Friends List). Runs under plain `ruby`, outside the engine: the class itself
# only touches a plain Hash of Strings, so it's exercised here directly with
# no game stubs needed (the UI functions in the same file, which do call into
# the engine, aren't covered here - same testing boundary as the Ruleset
# Builder UI, which also isn't tested).
#
# Run with `ruby friends_list_test.rb`.

require "minitest/autorun"

REPO_ROOT = File.expand_path("../..", __dir__)
require_relative "#{REPO_ROOT}/Plugins/Chasm Cable Club/[001] Cable Club Client/010_CableClub_FriendsList.rb"

class CableClubFriendsListTest < Minitest::Test
  def test_valid_id_accepts_exactly_five_digits
    assert CableClubFriendsList.valid_id?("12345")
    assert CableClubFriendsList.valid_id?("00007") # leading zeros are kept, not stripped
  end

  def test_valid_id_rejects_bad_input
    refute CableClubFriendsList.valid_id?("1234")    # too short
    refute CableClubFriendsList.valid_id?("123456")  # too long
    refute CableClubFriendsList.valid_id?("12a45")   # non-numeric
    refute CableClubFriendsList.valid_id?("")        # cancelled entry
    refute CableClubFriendsList.valid_id?(nil)
  end

  def test_add_and_lookup
    list = CableClubFriendsList.new
    assert list.empty?

    list.add("12345", "Ash")

    refute list.empty?
    assert list.include?("12345")
    assert_equal "Ash", list.name_for("12345")
    assert_equal [["12345", "Ash"]], list.to_a
  end

  def test_add_again_overwrites_rather_than_duplicating
    list = CableClubFriendsList.new
    list.add("12345", "Ash")
    list.add("12345", "Red")

    assert_equal "Red", list.name_for("12345")
    assert_equal 1, list.to_a.length
  end

  def test_rename_changes_label_not_id
    list = CableClubFriendsList.new
    list.add("12345", "Ash")

    list.rename("12345", "Red")

    assert list.include?("12345")
    assert_equal "Red", list.name_for("12345")
  end

  def test_update_id_rekeys_while_preserving_name
    list = CableClubFriendsList.new
    list.add("12345", "Ash")

    list.update_id("12345", "54321")

    refute list.include?("12345")
    assert list.include?("54321")
    assert_equal "Ash", list.name_for("54321")
  end

  def test_update_id_to_an_existing_id_overwrites_that_entry
    list = CableClubFriendsList.new
    list.add("11111", "Ash")
    list.add("22222", "Misty")

    list.update_id("11111", "22222")

    refute list.include?("11111")
    assert_equal "Ash", list.name_for("22222") # caller is expected to confirm before doing this
    assert_equal 1, list.to_a.length
  end

  def test_remove_deletes_entry
    list = CableClubFriendsList.new
    list.add("12345", "Ash")

    list.remove("12345")

    refute list.include?("12345")
    assert list.empty?
  end

  def test_iteration_order_matches_insertion_order
    list = CableClubFriendsList.new
    list.add("11111", "Ash")
    list.add("22222", "Misty")
    list.add("33333", "Brock")

    assert_equal ["11111", "22222", "33333"], list.to_a.map(&:first)
  end
end
