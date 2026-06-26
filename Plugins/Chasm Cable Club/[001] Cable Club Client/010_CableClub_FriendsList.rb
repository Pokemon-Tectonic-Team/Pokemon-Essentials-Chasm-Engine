# Cable Club Friends List (issue #493): a saved list of opponents' public
# trainer IDs with editable name labels, for quick recall instead of
# re-typing a 5-digit ID every time. Reached from the Cable Club PC's
# "Customize" menu (pbCableClubCustomMenu, Plugins/Chasm Graphics and UI/
# Menus/PC/CableClubPC.rb) via pbManageFriendsList below, and also offered
# automatically after a battle (see pbOfferSaveFriend in 006_CableClub_UI.rb)
# and used as a picker when connecting (see pbAttemptConnection, same file).
# Plain global functions, same self-contained pattern as
# 009_CableClub_RulesetBuilder.rb, since this menu has no Cable Club
# connection active when managed from the PC.

# Engine-independent wrapper around the saved {id => name} pairs, so it can
# be unit-tested directly (see Tests/CableClubFriendsList) the same way
# PokeXRayRevealState is. Marshal-safe (plain Hash of Strings) since an
# instance of this lives on $PokemonGlobal and is saved with the game.
class CableClubFriendsList
  def self.valid_id?(str)
    return false if str.nil?
    return !!(str =~ /\A[0-9]{5}\z/)
  end

  def initialize
    @entries = {}
  end

  def add(id, name)
    @entries[id] = name
  end

  def rename(id, name)
    @entries[id] = name
  end

  # Re-keys an entry under a new id, preserving its name - for when the
  # same person's public ID changes (e.g. they're now playing from a
  # different save file).
  def update_id(old_id, new_id)
    return if old_id == new_id
    name = @entries.delete(old_id)
    @entries[new_id] = name
  end

  def remove(id)
    @entries.delete(id)
  end

  def include?(id)
    @entries.key?(id)
  end

  def name_for(id)
    @entries[id]
  end

  def each(&block)
    @entries.each(&block)
  end

  def to_a
    @entries.to_a
  end

  def empty?
    @entries.empty?
  end
end

def pbManageFriendsList
  command = 0
  loop do
    friends = $PokemonGlobal.cable_club_friends_list
    cmds = []
    cmdAdd = cmds.length; cmds.push(_INTL("Add Friend"))
    cmdEdit = -1
    if !friends.empty?
      cmdEdit = cmds.length
      cmds.push(_INTL("Edit Friends"))
    end
    cmds.push(_INTL("Cancel"))
    command = pbMessage(_INTL("What do you want to do with your Friends List?"), cmds, cmds.length, nil, command)
    if command == cmdAdd
      pbAddFriend(friends)
    elsif cmdEdit >= 0 && command == cmdEdit
      id = pbPickFriend(friends)
      pbEditFriendEntry(friends, id) if id
    else
      break
    end
  end
end

def pbPickFriend(friends)
  entries = friends.to_a
  cmds = entries.map { |id, name| _INTL("{1} ({2})", name, id) }
  idx = pbMessage(_INTL("Which friend?"), cmds, -1)
  return nil if idx < 0
  return entries[idx][0]
end

def pbAddFriend(friends)
  typed = pbEnterText(_INTL("Friend's ID"), 0, 5, "")
  return if typed.empty?
  if !CableClubFriendsList.valid_id?(typed)
    pbMessage(_INTL("Please enter a valid trainer ID of 5 digits."))
    return
  end
  if friends.include?(typed)
    msg = _INTL("{1} is already on your Friends List as \"{2}\". Overwrite?", typed, friends.name_for(typed))
    return unless pbConfirmMessage(msg)
  end
  name = pbEnterText(_INTL("Save this friend as?"), 0, Settings::MAX_PLAYER_NAME_SIZE, "")
  return if name.empty?
  friends.add(typed, name)
  pbMessage(_INTL("{1} was added to your Friends List.", name))
end

def pbEditFriendEntry(friends, id)
  command = 0
  loop do
    name = friends.name_for(id)
    cmds = [_INTL("Rename"), _INTL("Change ID"), _INTL("Remove"), _INTL("Back")]
    command = pbMessage(_INTL("{1} ({2})", name, id), cmds, cmds.length, nil, command)
    case command
    when 0
      typed = pbEnterText(_INTL("Save this friend as?"), 0, Settings::MAX_PLAYER_NAME_SIZE, name)
      friends.rename(id, typed) unless typed.empty?
    when 1
      typed = pbEnterText(_INTL("New ID for {1}", name), 0, 5, id)
      next if typed.empty?
      if !CableClubFriendsList.valid_id?(typed)
        pbMessage(_INTL("Please enter a valid trainer ID of 5 digits."))
      elsif typed != id
        if friends.include?(typed)
          msg = _INTL("{1} is already on your Friends List as \"{2}\". Overwrite?", typed, friends.name_for(typed))
          next unless pbConfirmMessage(msg)
        end
        friends.update_id(id, typed)
        id = typed
      end
    when 2
      if pbConfirmMessage(_INTL("Remove {1} from your Friends List?", name))
        friends.remove(id)
        break
      end
    else
      break
    end
  end
end
