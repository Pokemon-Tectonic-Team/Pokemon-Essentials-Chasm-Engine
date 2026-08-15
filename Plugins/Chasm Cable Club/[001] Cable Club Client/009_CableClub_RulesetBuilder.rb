# In-game UI for building/editing a Cable Club ruleset interactively (issue
# #528), then saving it to a LocalPresets/*.rules file via
# CableClub.write_rule_file. Reached from the Cable Club PC's "Customize"
# menu (pbCableClubCustomMenu, Plugins/Chasm Graphics and UI/Menus/PC/
# CableClubPC.rb) via pbManageCustomRulesets below - deliberately NOT from
# pbSelectBattleSettings's "Custom Rules" menu, since that only happens
# after already connecting to a partner, who'd otherwise be left waiting
# while one player messes around building a ruleset. Plain global functions
# (pbMessage/pbEnterText/pbMessageChooseNumber etc., the same self-contained
# pattern pbChangeOnlineTrainerType and friends already use in
# 002_UserFunctions.rb) rather than methods on a Scene, since this menu has
# no Cable Club connection - and so no CableClub_Scene instance - active
# when it runs.

# In-progress edit session. PokemonOnlineRules doesn't store a name/
# description/filename itself - those are only ever passed alongside it as
# a tuple (see CableClub.load_local_rule) - so this wraps them together
# while a ruleset is being built or edited. A brand new ruleset (no rules
# given) defaults to Free For All's own settings (PartySize 1-6, 30s team
# preview) rather than PokemonOnlineRules.new's bare party-size-0 default,
# which would otherwise make a freshly-started ruleset unsaveable until the
# player happened to think to set a party size themselves.
class RulesetBuilder
  attr_accessor :name, :description, :rules, :filename

  def initialize(name = "", description = "", rules = nil, filename = nil)
    @name        = name
    @description = description
    @filename    = filename
    if rules
      @rules = rules
    else
      @rules = PokemonOnlineRules.new
      @rules.setTeamPreview(30)
      @rules.setNumberRange(1, 6)
    end
    mark_saved!
  end

  # A plain-value snapshot of everything that ends up in the saved file.
  # Comparing two snapshots with == tells dirty? whether anything has
  # changed since the last save, without needing every single edit method
  # in this file to separately remember to set a "dirty" flag.
  def snapshot
    return [@name, @description, @rules.team_preview, @rules.ruleset.minLength, @rules.ruleset.maxLength,
            @rules.battle_mode, @rules.rules_hash[:level_adjust], @rules.rules_hash[:pokemon], @rules.rules_hash[:team]]
  end

  def dirty?
    return snapshot != @saved_snapshot
  end

  def mark_saved!
    @saved_snapshot = snapshot
  end
end

# Truncates text to at most max_length characters (including the trailing
# "..." once truncated), so one long description or one clause with a long
# list of arguments can't blow out a menu line - pbMessage's command window
# sizes itself to fit its longest entry, so a single very long string would
# otherwise widen (or overflow) the whole menu.
def pbTruncateForMenu(text, max_length = 20)
  return text if text.length <= max_length
  return "#{text[0, max_length - 3]}..."
end

# Entry point from the Cable Club PC's Customize menu: build a new ruleset
# from scratch, or pick one of the existing LocalPresets/*.rules files to
# edit. Reloads the list from disk after every session rather than tracking
# in-memory array mutations, since (unlike the old design) there's no
# longer a live battle-settings screen holding onto a local_rules array
# that needs to stay in sync.
def pbManageCustomRulesets
  command = 0
  loop do
    local_rules = CableClub.load_local_rules
    cmds = []
    cmdNew = cmds.length; cmds.push(_INTL("New Ruleset"))
    cmdEdit = -1
    if !local_rules.empty?
      cmdEdit = cmds.length
      cmds.push(_INTL("Edit Existing"))
    end
    cmds.push(_INTL("Cancel"))
    command = pbMessage(_INTL("What do you want to do with custom rulesets?"), cmds, cmds.length, nil, command)
    if command == cmdNew
      pbEditRuleset(RulesetBuilder.new)
    elsif cmdEdit >= 0 && command == cmdEdit
      entry = pbPickExistingRuleset(local_rules)
      pbEditRuleset(RulesetBuilder.new(*entry)) if entry
    else
      break
    end
  end
end

def pbPickExistingRuleset(local_rules)
  cmds = local_rules.map { |entry| entry[0] }
  idx = pbMessage(_INTL("Edit which ruleset?"), cmds, -1)
  return nil if idx < 0
  return local_rules[idx]
end

# The main "what do you want to edit" loop for one builder session. Returns
# the final [name, desc, rules, filename] tuple if the player saved at
# least once before leaving, or nil if they left without ever saving.
def pbEditRuleset(builder)
  saved_once = false
  command = 0
  loop do
    cmds = [
      _INTL("Name: {1}", builder.name.empty? ? _INTL("(none)") : builder.name),
      _INTL("Description: {1}", builder.description.empty? ? _INTL("(none)") : pbTruncateForMenu(builder.description)),
      _INTL("Party Size: {1}", pbDescribePartySize(builder.rules)),
      _INTL("Team Preview: {1}", pbDescribeTeamPreview(builder.rules)),
      _INTL("Battle Mode: {1}", builder.rules.battle_mode || "single"),
      _INTL("Level Adjustment: {1}", pbDescribeLevelAdjustment(builder.rules)),
      _INTL("Pokémon Rules ({1})", builder.rules.rules_hash[:pokemon].length),
      _INTL("Team Rules ({1})", builder.rules.rules_hash[:team].length),
    ]
    cmdSave = cmds.length; cmds.push(_INTL("Save"))
    # Save As only makes sense once there's already a saved file to fork
    # from - before that first save, it's indistinguishable from Save.
    cmdSaveAs = -1
    if builder.filename
      cmdSaveAs = cmds.length
      cmds.push(_INTL("Save As"))
    end
    cmds.push(_INTL("Back"))
    msgName = builder.name.empty? ? _INTL("this ruleset") : builder.name
    command = pbMessage(_INTL("What rules do you want {1} to contain?", msgName), cmds, cmds.length, nil, command)
    case command
    when 0
      # minlength 0 here (and below) is deliberate, not a typo - pbEnterText
      # only lets the player press Escape to cancel when minlength is 0;
      # with any higher minlength, Escape is silently ignored and they're
      # stuck typing something. An empty result means they cancelled (or
      # blanked the field and confirmed, which amounts to the same thing
      # here), so it's treated as "leave the existing value alone."
      typed = pbEnterText(_INTL("Ruleset name"), 0, 36, builder.name)
      builder.name = typed unless typed.empty?
    when 1
      typed = pbEnterText(_INTL("Ruleset description"), 0, 64, builder.description)
      builder.description = typed unless typed.empty?
    when 2; pbEditPartySize(builder.rules)
    when 3; pbEditTeamPreview(builder.rules)
    when 4; pbEditBattleMode(builder.rules)
    when 5; pbEditLevelAdjustment(builder.rules)
    when 6; pbEditClauseList(builder.rules, :pokemon, :addPokemonRule, POKEMON_RULE_CLASSES, _INTL("Pokémon Rules"))
    when 7; pbEditClauseList(builder.rules, :team, :addTeamRule, TEAM_RULE_CLASSES, _INTL("Team Rules"))
    else
      if command == cmdSave
        saved_once = true if pbSaveRuleset(builder, false)
      elsif cmdSaveAs >= 0 && command == cmdSaveAs
        saved_once = true if pbSaveRuleset(builder, true)
      elsif !builder.dirty? || pbConfirmMessage(_INTL("Discard unsaved changes?"))
        break
      end
    end
  end
  return nil if !saved_once
  return [builder.name, builder.description, builder.rules, builder.filename]
end

def pbDescribePartySize(rules)
  return _INTL("{1}-{2}", rules.ruleset.minLength, rules.ruleset.maxLength)
end

def pbDescribeTeamPreview(rules)
  return rules.team_preview > 0 ? _INTL("{1}s", rules.team_preview) : _INTL("Off")
end

def pbDescribeLevelAdjustment(rules)
  adjustment = rules.levelAdjustment
  return adjustment ? adjustment.class.builder_name : _INTL("None")
end

def pbEditPartySize(rules)
  params = ChooseNumberParams.new
  params.setRange(1, Settings::MAX_PARTY_SIZE)
  params.setInitialValue(rules.ruleset.minLength)
  minValue = pbMessageChooseNumber(_INTL("Minimum party size"), params)
  params.setRange(minValue, Settings::MAX_PARTY_SIZE)
  params.setInitialValue([rules.ruleset.maxLength, minValue].max)
  maxValue = pbMessageChooseNumber(_INTL("Maximum party size"), params)
  rules.setNumberRange(minValue, maxValue)
end

def pbEditTeamPreview(rules)
  params = ChooseNumberParams.new
  params.setRange(0, 999)
  params.setInitialValue(rules.team_preview)
  rules.setTeamPreview(pbMessageChooseNumber(_INTL("Team preview duration in seconds (0 to disable)"), params))
end

def pbEditBattleMode(rules)
  cmds = [_INTL("Single"), _INTL("Double"), _INTL("Triple")]
  modes = ["single", "double", "triple"]
  cmd = pbMessage(_INTL("Battle Mode"), cmds, -1)
  rules.setBattleMode(modes[cmd]) if cmd >= 0
end

def pbEditLevelAdjustment(rules)
  cmds = [_INTL("None")]
  classes = [nil]
  LEVEL_ADJUSTMENT_CLASSES.each do |klass|
    cmds.push(klass.builder_name)
    classes.push(klass)
  end
  cmds.push(_INTL("Back"))
  command = 0
  loop do
    command = pbMessage(_INTL("Level Adjustment"), cmds, cmds.length, nil, command)
    return if command == cmds.length - 1
    klass = classes[command]
    if klass.nil?
      rules.setLevelAdjustment(nil)
      return
    end
    detail_cmd = pbMessage(klass.builder_desc, [_INTL("Use This"), _INTL("Back")], 2)
    next if detail_cmd != 0
    args = pbPromptClauseArgs(klass)
    next if !args
    rules.setLevelAdjustment(klass, *args)
    return
  end
end

# Shared by Pokémon Rules and Team Rules - identical shape, just a
# different rules_hash key/add-method/class list.
def pbEditClauseList(rules, hash_key, add_method, classes, title)
  command = 0
  loop do
    current = rules.rules_hash[hash_key]
    cmds = current.map { |entry| pbDescribeClauseEntry(entry) }
    cmds.push(_INTL("Add Clause"))
    cmds.push(_INTL("Back"))
    command = pbMessage(title, cmds, cmds.length, nil, command)
    break if command == cmds.length - 1
    if command == current.length
      pbAddClause(rules, add_method, classes)
    else
      pbEditExistingClauseEntry(rules, hash_key, command, cmds[command])
    end
  end
end

def pbDescribeClauseEntry(entry)
  klass, *tagged_args = entry
  values = CableClub.untag_rule_args(tagged_args)
  full = values.empty? ? klass.builder_name : "#{klass.builder_name} (#{values.join(', ')})"
  return pbTruncateForMenu(full)
end

def pbAddClause(rules, add_method, classes)
  cmds = classes.map { |k| k.builder_name }
  cmds.push(_INTL("Back"))
  command = 0
  loop do
    command = pbMessage(_INTL("Add which clause?"), cmds, cmds.length, nil, command)
    break if command == cmds.length - 1
    klass = classes[command]
    detail_cmd = pbMessage(klass.builder_desc, [_INTL("Add This"), _INTL("Back")], 2)
    next if detail_cmd != 0
    args = pbPromptClauseArgs(klass)
    next if !args
    rules.send(add_method, klass, *args)
    break
  end
end

def pbEditExistingClauseEntry(rules, hash_key, index, description)
  cmd = pbMessage(description, [_INTL("Remove"), _INTL("Back")], 2)
  return if cmd != 0
  rules.rules_hash[hash_key].delete_at(index)
  pbRebuildRuleset(rules)
end

# PokemonRuleSet has no per-index removal, and addPokemonRule/addTeamRule
# only ever push - so after the builder removes an entry from rules_hash,
# the live ruleset instance needs rebuilding from rules_hash (the single
# source of truth) by replaying it back through the existing add methods,
# rather than needing a new removal primitive on PokemonRuleSet/
# PokemonOnlineRules itself.
def pbRebuildRuleset(rules)
  pokemon_recipe = rules.rules_hash[:pokemon].dup
  team_recipe    = rules.rules_hash[:team].dup
  rules.ruleset.clearPokemonRules
  rules.ruleset.clearTeamRules
  rules.rules_hash[:pokemon] = []
  rules.rules_hash[:team]    = []
  pokemon_recipe.each { |klass, *tagged_args| rules.addPokemonRule(klass, *CableClub.untag_rule_args(tagged_args)) }
  team_recipe.each { |klass, *tagged_args| rules.addTeamRule(klass, *CableClub.untag_rule_args(tagged_args)) }
end

# The generic metadata-driven prompt driver: walks klass.builder_args and
# dispatches each to a number prompt or a multi-pick picker loop. Returns
# nil (caller aborts adding the clause) if any arg's prompt is cancelled.
def pbPromptClauseArgs(klass)
  args = []
  klass.builder_args.each do |arg_type, label|
    value = pbPromptClauseArg(arg_type, label)
    return nil if value.nil?
    value.is_a?(Array) ? args.concat(value) : args.push(value)
  end
  return args
end

def pbPromptClauseArg(arg_type, label)
  case arg_type
  when :int
    params = ChooseNumberParams.new
    params.setRange(0, 9999)
    return pbMessageChooseNumber(label, params)
  when :level
    params = ChooseNumberParams.new
    params.setRange(1, GameData::GrowthRate.max_level)
    params.setInitialValue(GameData::GrowthRate.max_level)
    return pbMessageChooseNumber(label, params)
  when :tenths
    params = ChooseNumberParams.new
    params.setRange(1, 999)
    return pbMessageChooseNumber(label, params) / 10.0
  when :species_list
    return pbPickMultiple(label, GameData::Species) { pbChooseSpeciesList }
  when :item_list
    return pbPickMultiple(label, GameData::Item) { pbListScreen(label, ItemLister.new) }
  when :move_list
    return pbPickMultiple(label, GameData::Move) { pbChooseMoveList }
  end
end

# Repeatedly calls the given picker block (one of the pbChoose*List/
# pbListScreen calls above) to build up an array of chosen IDs, asking Add
# Another/Done/Cancel Clause after each pick - showing the names picked so
# far each time, via gamedata_class (GameData::Species/Item/Move), so the
# player isn't adding to a list they can no longer see. Cancelling the very
# first pick aborts the whole clause (returns nil); cancelling a later one
# just stops adding more and keeps what's already been picked.
def pbPickMultiple(label, gamedata_class)
  picked = []
  loop do
    choice = yield
    break if choice.nil? && picked.empty?
    picked.push(choice) if choice
    names = picked.map { |id| gamedata_class.get(id).name }.join(", ")
    prompt = _INTL("{1}\nSo far: {2}", label, names)
    next_cmd = pbMessage(prompt, [_INTL("Add Another"), _INTL("Done"), _INTL("Cancel Clause")], 3)
    return picked if next_cmd == 1
    return nil if next_cmd == 2
  end
  return nil
end

# Validates the two mandatory fields (matching CableClub.load_rule_file's
# own "missing Description"/"missing PartySize" requirements, so a
# builder-produced file always loads back successfully) and a non-zero
# party size, then writes the file - prompting for a filename if there
# isn't one yet or this is an explicit Save As, otherwise overwriting
# (with confirmation) the file this session was opened from.
def pbSaveRuleset(builder, save_as)
  if builder.name.strip.empty?
    pbMessage(_INTL("Give this ruleset a name first."))
    return false
  end
  if builder.description.strip.empty?
    pbMessage(_INTL("Give this ruleset a description first."))
    return false
  end
  if builder.rules.ruleset.maxLength <= 0
    pbMessage(_INTL("Set a party size first."))
    return false
  end
  filename = builder.filename
  if save_as || !filename
    suggested = builder.name.gsub(/[^A-Za-z0-9 _-]/, "").strip.gsub(/\s+/, "_")
    suggested = "ruleset" if suggested.empty?
    typed = pbEnterText(_INTL("File name (without .rules)"), 0, 32, suggested)
    return false if typed.empty?
    filename = "#{typed}.rules"
    full_path = sprintf("%s/%s", CableClub::FOLDER_FOR_BATTLE_PRESETS, filename)
    return false if File.exist?(full_path) && !pbConfirmMessage(_INTL("{1} already exists. Overwrite?", filename))
  else
    return false if !pbConfirmMessage(_INTL("Overwrite {1}?", filename))
  end
  CableClub.write_rule_file(filename, [builder.name, builder.description, builder.rules])
  builder.filename = filename
  builder.mark_saved!
  pbMessage(_INTL("Ruleset saved."))
  return true
end
