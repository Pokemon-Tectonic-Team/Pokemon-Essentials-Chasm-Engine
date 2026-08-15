module CableClub
  # Raised when an unexpected message is received from the other client, which
  # means the two sides have desynced and can no longer meaningfully communicate.
  # Subclasses Exception rather than StandardError, like Connection::Disconnected, so it
  # passes straight through bare `rescue`/`rescue StandardError` clauses elsewhere (e.g.
  # the core battle engine's own catch-all in pbStartBattle) instead of being intercepted
  # before it reaches the Cable Club-specific recovery handling (mostly local to wherever
  # it's raised; pbAttemptConnection is only the last-resort fallback via pbConnectServer).
  class DesyncError < Exception
    attr_accessor :log_path
    # True if this was raised locally because the *other* client already told us (via a
    # :desync message) that they desynced, rather than because we detected it ourselves.
    attr_accessor :remote
  end

  ACTIVITY_OPTIONS = {:battle => _INTL("battle"),
                      :trade => _INTL("trade"),
                      :record_mix => _INTL("mix records")}

  # Best-effort notice to the other client that we've hit a desync, so they don't sit
  # waiting forever on a connection/activity we're about to abandon or recover out of.
  # Deliberately swallows any error: failing to notify the peer shouldn't mask the
  # original desync we're already in the middle of handling. Skipped for errors that are
  # themselves a notice FROM the peer, so the two sides don't endlessly echo it back and
  # forth, each re-interrupting the other's recovery.
  def self.notify_desync(connection, error)
    return if error.remote
    connection.send do |writer|
      writer.sym(:desync)
      writer.str(error.message)
    end
  rescue StandardError
  end

  # Writes a standalone desync log for contexts with no battle (and so no RNG diagnostics)
  # to attach the error to, e.g. while still agreeing on an activity, picking teams, or
  # trading. Named and timestamped the same way as the in-battle log (PokeBattle_CableClub
  # #pbDumpDesyncLog), just without an RNG call history. Returns the log's path, or nil if
  # it couldn't be written.
  def self.write_desync_log(client_id, error)
    Dir.mkdir("Analysis") unless Dir.exist?("Analysis")
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    filename = "Analysis/desync_log_client#{client_id}_#{timestamp}.txt"
    File.open(filename, "w:UTF-8") do |f|
      f.puts("=== Cable Club Desync Log ===")
      f.puts("Context: Non-battle (no RNG diagnostics)")
      f.puts("Client ID: #{client_id}")
      f.puts("Error: #{error.message}")
      f.puts("Logged: #{Time.now}")
      f.puts("Backtrace:")
      (error.backtrace || []).each { |line| f.puts("  #{line}") }
    end
    return filename
  rescue StandardError
    return nil
  end

  # Shows the standard "please report this" messaging for a desync, given the log path
  # (or nil if none could be saved). Shared by every desync recovery point so the
  # guidance shown to players doesn't drift between them; callers show their own
  # context-specific opening line (e.g. "the battle has been ended early") beforehand.
  def self.show_desync_report(log_path)
    pbMessage(_INTL("Please visit the Discord through the main menu and report this issue to the developers."))
    if log_path
      msg = _INTL("A log of the issue has been saved to:")
      msg += "\n" + log_path
      pbMessage(msg)
      pbMessage(_INTL("Please ensure both players' logs are attached with your report."))
    else
      msg = _INTL("Unfortunately, a log of the error could not be saved.")
      msg += "\n" + _INTL("This will make diagnosing the issue difficult, so we may not be able to help.")
      pbMessage(msg)
    end
  end

  def self.pokemon_order(client_id)
    case client_id
    when 0; [0, 1, 2, 3, 4, 5]
    when 1; [1, 0, 3, 2, 5, 4]
    else; raise "Unknown client_id: #{client_id}"
    end
  end

  def self.pokemon_target_order(client_id)
    case client_id
    when 0..1; [1, 0, 3, 2, 5, 4]
    else; raise "Unknown client_id: #{client_id}"
    end
  end

  def self.do_battle(connection, client_id, seed, battle_rules, player_party, partner, partner_party, previewed_opponent_party: nil, opponent_standby_party: nil)
    $Trainer.heal_party # Avoids having to transmit damaged state.
    partner_party.each{|pkmn| pkmn.heal} # back to back battles desync without it.
    oldlevels = battle_rules.adjustLevels($Trainer.party,partner_party)
    olditems  = $Trainer.party.transform { |p| p.items.transform { |i| i } }
    olditems2 = partner_party.transform { |p| p.items.transform { |i| i }  }
    if !DISABLE_SKETCH_ONLINE
      oldmoves  = $player.party.transform { |p| p.moves.dup }
      oldmoves2 = partner_party.transform { |p| p.moves.dup }
    end
    scene = pbNewBattleScene
    battle = PokeBattle_CableClub.new(connection, client_id, scene, player_party, partner_party, partner, seed, previewed_opponent_party: previewed_opponent_party, opponent_standby_party: opponent_standby_party)
    battle.endSpeechesWin = [partner.win_text]
    battle.endSpeeches = [partner.lose_text]
    battle.items = []
    battle.internalBattle = false
    battle_rules.applyBattleMode(battle)
    trainerbgm = pbGetTrainerBattleBGM(partner)
    Events.onStartBattle.trigger(nil, nil)
    # XXX: Configuring Online Battle Rules
    setBattleRule("environment", :None)
    setBattleRule("weather", :None)
    setBattleRule("terrain", :None)
    setBattleRule("backdrop", "indoor1")
    pbPrepareBattle(battle)
    $PokemonTemp.clearBattleRules
    exc = nil
    pbBattleAnimation(trainerbgm, (battle.singleBattle?) ? 1 : 3, [partner]) {
      pbSceneStandby {
        begin
          battle.pbStartBattle
        rescue Connection::Disconnected
          scene.pbEndBattle(0)
          exc = $!
        rescue CableClub::DesyncError => e
          # Recover like a normal (aborted) battle end rather than tearing down the whole
          # Cable Club session, so both players can quickly try again with a rematch.
          e.log_path = battle.pbDumpDesyncLog(e)
          CableClub.notify_desync(connection, e)
          # Show the explanation before fading the battle out, so it's clear why the
          # battle suddenly ended, rather than after.
          pbMessage(_INTL("I'm sorry, the connection with the other trainer became out of sync, so the battle has been ended early."))
          CableClub.show_desync_report(e.log_path)
          scene.pbEndBattle(0)
        ensure
          $Trainer.party.each_with_index do |pkmn, i|
            pkmn.heal
            pkmn.makeUnmega
            pkmn.makeUnprimal
            pkmn.setItems(olditems[i])
            pkmn.moves = oldmoves[i] if !DISABLE_SKETCH_ONLINE
          end
          partner_party.each_with_index do |pkmn, i|
            pkmn.heal
            pkmn.makeUnmega
            pkmn.makeUnprimal
            pkmn.setItems(olditems2[i])
            pkmn.moves = oldmoves2[i] if !DISABLE_SKETCH_ONLINE
          end
          battle_rules.unadjustLevels($Trainer.party,partner_party,oldlevels)
          # Clear the standby_party set in PokeBattle_CableClub#initialize - otherwise it'd keep
          # pointing at this battle's roster snapshot, going stale once $Trainer.party is next
          # reassigned wholesale (rather than just mutated) elsewhere, e.g. Battle Frontier.
          $Trainer.standby_party = nil
        end
      }
    }
    raise exc if exc
  end

  def self.do_trade(index, you, your_pkmn)
    my_pkmn = $Trainer.party[index]
    $Trainer.pokedex.register(your_pkmn)
    $Trainer.pokedex.set_owned(your_pkmn.species)
    pbFadeOutInWithMusic(99999) {
      scene = PokemonTrade_Scene.new
      scene.pbStartScreen(my_pkmn, your_pkmn, $Trainer.name, you.name)
      scene.pbTrade
      scene.pbEndScreen
    }
    $Trainer.party[index] = your_pkmn
  end

  def self.choose_pokemon
    chosen = -1
    pbFadeOutIn(99999) {
      scene = PokemonParty_Scene.new
      screen = PokemonPartyScreen.new(scene, $Trainer.party)
      screen.pbStartScene(_INTL("Choose a Pokémon."), false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    }
    return chosen
  end
  
  def self.choose_team(ruleset)
    team_order = nil
    pbFadeOutIn(99999) {
      scene = PokemonParty_Scene.new
      screen = PokemonPartyScreen.new(scene, $Trainer.party)
      team_order = screen.pbPokemonMultipleEntryScreenOrder(ruleset)
    }
    return team_order
  end
  
  def self.check_pokemon(pkmn)
    pbFadeOutIn(99999) {
      scene = PokemonSummary_Scene.new
      screen = PokemonSummaryScreen.new(scene,true)
      screen.pbStartScreen([pkmn],0)
    }
  end

  def self.write_party(writer)
    writer.int($Trainer.party_count)
    $Trainer.party.each do |pkmn|
      write_pkmn(writer, pkmn)
    end
  end

  def self.write_pkmn(writer, pkmn)
    writer.sym(pkmn.species)
    writer.int(pkmn.level)
    writer.int(pkmn.personalID)
    writer.int(pkmn.owner.id)
    writer.str(pkmn.owner.safe_name)
    writer.int(pkmn.owner.gender)
    writer.int(pkmn.exp)
    writer.int(pkmn.form)
    writer.nil_or(:sym, pkmn.items[0])
    writer.nil_or(:sym, pkmn.items[1])
    writer.sym(pkmn.itemTypeChosen) # don't need nil_or because defaults to normal
    writer.int(pkmn.numMoves)
    pkmn.moves.each do |move|
      writer.sym(move.id)
      writer.int(move.ppup)
    end
    writer.int(pkmn.first_moves.length)
    pkmn.first_moves.each do |move|
      writer.sym(move)
    end
    writer.int(pkmn.gender)
    writer.nil_or(:bool,pkmn.shiny?)
    writer.nil_or(:sym, pkmn.ability_id)
    writer.nil_or(:int, pkmn.ability_index)
    writer.nil_or(:sym, pkmn.nature_id)
    writer.nil_or(:sym, pkmn.nature_for_stats_id)
    GameData::Stat.each_main do |s|
      writer.int(pkmn.ev[s.id])
    end
    writer.int(pkmn.happiness)
    writer.str(pkmn.safe_name)
    writer.sym(pkmn.poke_ball)
    writer.int(pkmn.steps_to_hatch)
    writer.int(pkmn.obtain_method)
    writer.int(pkmn.obtain_map)
    writer.nil_or(:str,pkmn.obtain_text)
    writer.int(pkmn.obtain_level)
    writer.int(pkmn.hatched_map)
    writer.int(pkmn.cool)
    writer.int(pkmn.beauty)
    writer.int(pkmn.cute)
    writer.int(pkmn.smart)
    writer.int(pkmn.tough)
    writer.int(pkmn.sheen)
    writer.int(pkmn.numRibbons)
    pkmn.ribbons.each do |ribbon|
      writer.sym(ribbon)
    end
    writer.bool(!!pkmn.fused)
    if pkmn.fused
      write_pkmn(writer, pkmn.fused)
    end
    if defined?(EliteBattle) # EBDX compat
      # this looks so dumb I know, but the variable can be nil, false, or an int.
      writer.str(pkmn.superHue.to_s)
      writer.nil_or(:bool,pkmn.superVariant)
    end
  end

  def self.parse_party(record)
    party = []
    record.int.times do
      party << parse_pkmn(record)
    end
    return party
  end

  def self.parse_pkmn(record)
    species = record.sym
    level = record.int
    pkmn = Pokemon.new(species, level, $Trainer)
    pkmn.personalID = record.int
    pkmn.owner.id = record.int
    pkmn.owner.name = record.str
    pkmn.owner.gender = record.int
    pkmn.exp = record.int
    form = record.int
    #pkmn.forced_form = form if MultipleForms.hasFunction?(pkmn.species,"getForm")
    pkmn.form_simple = form
    items = [record.sym,record.sym]
    # filter out blank items
    items = items.select {|i| i.length > 0}
    pkmn.setItems(items)
    pkmn.itemTypeChosen = record.sym
    pkmn.forget_all_moves
    record.int.times do |i|
      pkmn.moves[i] = Pokemon::Move.new(record.sym)
      pkmn.moves[i].ppup = record.int
    end
    pkmn.moves.compact!
    pkmn.clear_first_moves
    record.int.times do |i|
      pkmn.add_first_move(record.sym)
    end
    pkmn.gender = record.int
    pkmn.shiny = record.nil_or(:bool)
    pkmn.ability = record.nil_or(:sym)
    pkmn.ability_index = record.nil_or(:int)
    pkmn.nature = record.sym
    pkmn.nature_for_stats = record.nil_or(:sym)
    GameData::Stat.each_main do |s|
      pkmn.ev[s.id] = record.int
    end
    pkmn.happiness = record.int
    pkmn.name = record.str
    pkmn.poke_ball = record.sym
    pkmn.steps_to_hatch = record.int
    pkmn.obtain_method = record.int
    pkmn.obtain_map = record.int
    pkmn.obtain_text = record.nil_or(:str)
    pkmn.obtain_level = record.int
    pkmn.hatched_map = record.int
    pkmn.cool = record.int
    pkmn.beauty = record.int
    pkmn.cute = record.int
    pkmn.smart = record.int
    pkmn.tough = record.int
    pkmn.sheen = record.int
    record.int.times do |i|
      pkmn.giveRibbon(record.sym)
    end
    if record.bool() # fused
      pkmn.fused = parse_pkmn(record)
    end
    if defined?(EliteBattle) # EBDX compat
      # this looks so dumb I know, but the variable can be nil, false, or an int.
      superhue = record.str
      if superhue == ""
        pkmn.superHue = nil
      elsif superhue=="false"
        pkmn.superHue = false
      else
        pkmn.superHue = superhue.to_i
      end
      pkmn.superVariant = record.nil_or(:bool)
    end
    pkmn.calc_stats
    return pkmn
  end

  def self.parse_battle_rules(record)
    rules = []
    record.int.times do
      rules << parse_battle_rule(record)
    end
    return rules
  end
  
  def self.parse_battle_rule(record)
    name = record.str
    desc = record.str
    rule = PokemonOnlineRules.new
    rule.setTeamPreview(record.int)
    rule.setNumberRange(record.int,record.int)
    # level adjustment
    level_adjustment = record.nil_or(:str)
    if level_adjustment
      level_adjustment_data = level_adjustment.split(";")
      level_adjustmentClass = level_adjustment_data.shift
      level_adjustment_args = process_args_type_hint(*level_adjustment_data)
      if Object.const_defined?(level_adjustmentClass)
        rule.setLevelAdjustment(Kernel.const_get(level_adjustmentClass),*level_adjustment_args)
      end
    end
    # battle mode
    battle_mode = record.nil_or(:str)
    rule.setBattleMode(battle_mode) if battle_mode
    # pokemon rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addPokemonRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    # team rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addTeamRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    return [name,desc,rule]
  end
  
  def self.write_battle_rule(writer,battle_rule)  
    name,desc,rule = battle_rule
    writer.str(name)
    writer.str(desc)
    writer.int(rule.team_preview)
    writer.int(rule.ruleset.minLength)
    writer.int(rule.ruleset.maxLength)
    if rule.rules_hash[:level_adjust]
      writer.str(rule.rules_hash[:level_adjust].join(";"))
    else
      writer.nil_or(:str,nil)
    end
    writer.nil_or(:str, rule.rules_hash[:battle_mode])
    writer.int(rule.rules_hash[:pokemon].length)
    rule.rules_hash[:pokemon].each do |pr|
      writer.str(pr.join(";"))
    end
    writer.int(rule.rules_hash[:team].length)
    rule.rules_hash[:team].each do |tr|
      writer.str(tr.join(";"))
    end
  end
  
  def self.get_server_info
    ret = [HOST,PORT]
    if safeExists?("serverinfo.ini")
      File.foreach("serverinfo.ini") do |line|
        case line
        when /^\s*[Hh][Oo][Ss][Tt]\s*=\s*(.+)$/
          ret[0]=$1 if !nil_or_empty?($1)
        when /^\s*[Pp][Oo][Rr][Tt]\s*=\s*(\d{1,5})$/
          if !nil_or_empty?($1)
            port = $1.to_i
            ret[1]= port if port>0 && port<=65535
          end
        end
      end
    end
    return ret
  end
  
  # only handles int, bool, sym, and str
  def self.apply_args_type_hint(*args)
    ret = []
    args.each do |arg|
      case arg
      when Integer; ret.push([:int,arg])
      when TrueClass,FalseClass; ret.push([:bool,arg])
      when String; ret.push([:str,arg])
      when Symbol; ret.push([:sym,arg])
      end
    end
    return ret
  end
  
  # takes a long chain of args, every second element is the original argument
  def self.process_args_type_hint(*args)
    ret = []
    r = nil
    args.each do |arg|
      if r
        case r
        when :int; ret.push(arg.to_i)
        when :bool
          if arg == "true"
            ret.push(true)
          elsif arg == "false"
            ret.push(false)
          else
            raise "expected bool, got #{arg}"
          end
        when :str; ret.push(arg)
        when :sym; ret.push(arg.to_sym)
        end
        r = nil
      else
        r = arg.to_sym
      end
    end
    return ret
  end

  # Splits a single rule clause's comma-separated fields (its class name
  # followed by any arguments) from the PBS-style rule file format,
  # respecting quotes so that a quoted string argument can itself contain a
  # comma (e.g. 'Foo,"a,b"' splits into ["Foo", "\"a,b\""]).
  def self.split_rule_fields(str)
    parts = []
    current = String.new
    in_quotes = false
    str.each_char do |c|
      case c
      when '"'
        in_quotes = !in_quotes
        current << c
      when ','
        if in_quotes
          current << c
        else
          parts.push(current.strip)
          current = String.new
        end
      else
        current << c
      end
    end
    parts.push(current.strip)
    return parts
  end

  # Infers the Ruby type of a single rule clause argument as written in a
  # PBS-style rule file: bare digits become an Integer, "true"/"false"
  # become a Boolean, "quoted text" becomes a String, and anything else
  # becomes a Symbol (the common case for species/move/item internal names).
  def self.infer_rule_arg(str)
    str = str.strip
    case str
    when /\A-?\d+\z/; return str.to_i
    when "true"; return true
    when "false"; return false
    when /\A"(.*)"\z/; return $1
    else; return str.to_sym
    end
  end

  # Parses a single rule clause, e.g. "NoLegendaryRestriction" or
  # "FixedLevelAdjustment,70", into the rule class's name and its
  # type-inferred arguments.
  def self.parse_rule_clause(str)
    class_name,*args = split_rule_fields(str.strip)
    raise "invalid rule clause \"#{str}\"" if !class_name || !/\A\w+\z/.match(class_name)
    return [class_name, args.map { |a| infer_rule_arg(a) }]
  end

  # Parses a PBS-style Cable Club rule file into a hash of its raw "Key =
  # Value" pairs, with the ruleset's display name taken from its "[Name]"
  # header. A key may be repeated to give it multiple values (used by the
  # rule clause categories below); every key's value is an array of one
  # entry per line it appeared on. Blank lines and "#" comments are ignored.
  def self.parse_rule_file(path)
    name = nil
    data = Hash.new { |hash,key| hash[key] = [] }
    File.foreach(path) do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#")
      header = /\A\[(.+)\]\z/.match(line)
      if header
        raise "multiple [Name] headers found" if name
        name = header[1]
        next
      end
      key, sep, value = line.partition("=")
      raise "invalid line \"#{line}\"" if sep.empty?
      data[key.strip].push(value.strip)
    end
    raise "missing [Name] header" if !name
    data["Name"] = [name]
    return data
  end

  # Adds the rules described by one or more repeated "Key = Clause" lines
  # (each already split into its own array entry by parse_rule_file) to a
  # PokemonOnlineRules using the given add-method (:addPokemonRule or
  # :addTeamRule). Unrecognized rule classes are skipped, matching the old
  # format's behavior.
  def self.add_rule_clauses(rules, add_method, clauses)
    clauses.each do |clause|
      class_name, args = parse_rule_clause(clause)
      next if !Object.const_defined?(class_name)
      rules.send(add_method, Kernel.const_get(class_name), *args)
    end
  end

  # Builds a PokemonOnlineRules from any .rules file at the given path.
  # Returns [name, desc, rules], or nil if the file is missing required keys
  # or otherwise fails to parse. Doesn't care where the file lives - see
  # load_local_rule below for the LocalPresets/-specific wrapper around this
  # that the rest of Cable Club actually uses.
  def self.load_rule_file(path)
    data = parse_rule_file(path)
    name = data["Name"].first
    desc = data["Description"].first
    raise "missing Description" if !desc
    raise "missing PartySize" if data["PartySize"].empty?
    rules = PokemonOnlineRules.new
    rules.setTeamPreview((data["TeamPreview"].first || "0").to_i)
    minValue, maxValue = data["PartySize"].first.split(",").map(&:to_i)
    rules.setNumberRange(minValue, maxValue)
    if !data["LevelAdjustment"].empty?
      level_adjustmentClass, level_adjustment_args = parse_rule_clause(data["LevelAdjustment"].first)
      if Object.const_defined?(level_adjustmentClass)
        rules.setLevelAdjustment(Kernel.const_get(level_adjustmentClass), *level_adjustment_args)
      end
    end
    rules.setBattleMode(data["BattleMode"].first.downcase) if !data["BattleMode"].empty?
    add_rule_clauses(rules, :addPokemonRule, data["PokemonRules"])
    add_rule_clauses(rules, :addTeamRule, data["TeamRules"])
    return [name, desc, rules]
  rescue
    return nil
  end

  # Builds a PokemonOnlineRules from one LocalPresets/*.rules file. Returns
  # [name, desc, rules, filename] - the filename (not just [name, desc,
  # rules]) is threaded through so the in-game ruleset builder's "Edit" can
  # save back to the same file instead of always prompting for a new name.
  # Returns nil under the same conditions as load_rule_file. Lives here
  # (rather than on CableClubScreen, where it used to live) so it's callable
  # from CableClub_Scene too, with no dependency on either owning a
  # reference to the other.
  def self.load_local_rule(filename)
    found = load_rule_file(sprintf("%s/%s", FOLDER_FOR_BATTLE_PRESETS, filename))
    return nil if !found
    return found + [filename]
  end

  # Returns every ruleset found in LocalPresets/*.rules, as
  # [name, desc, rules, filename] tuples (see load_local_rule above).
  def self.load_local_rules
    files = []
    begin
      Dir.chdir("#{FOLDER_FOR_BATTLE_PRESETS}/") { Dir.glob("*.rules") { |f| files.push(f) } }
    rescue
      return []
    end
    rules = []
    files.each do |f|
      r = load_local_rule(f)
      rules.push(r) if r
    end
    return rules
  end

  # Inverse of infer_rule_arg: renders a single Ruby value back into the
  # PBS-style text an argument needs to be written as for infer_rule_arg/
  # split_rule_fields to read it back unchanged. Symbols and bare-word
  # booleans/integers are written without quotes (matching how every
  # existing .rules file writes them); only String falls back to a quoted
  # literal, since it's the one type infer_rule_arg can't otherwise
  # distinguish from a Symbol.
  def self.format_rule_arg(value)
    case value
    when Integer, TrueClass, FalseClass, Symbol; return value.to_s
    when String; return "\"#{value}\""
    else; raise "unwritable rule argument #{value.inspect} (#{value.class})"
    end
  end

  # Inverse of parse_rule_clause: renders a rule class plus its arguments
  # back into one "ClassName,arg1,arg2" line.
  def self.format_rule_clause(klass, *args)
    return ([klass.to_s] + args.map { |a| format_rule_arg(a) }).join(",")
  end

  # rules_hash entries store each argument as an [:type_tag, value] pair
  # (apply_args_type_hint's output, e.g. [:int, 50]) rather than the bare
  # value - this strips the tags back off so format_rule_clause can be
  # given plain Ruby values, the same as parse_rule_clause produces.
  def self.untag_rule_args(tagged_args)
    return tagged_args.map { |_tag, value| value }
  end

  # Inverse of load_rule_file: writes battle_rule (a [name, desc,
  # PokemonOnlineRules] tuple) out to the given path, in the same PBS-style
  # format the reader above expects. Doesn't care where the file lives -
  # see write_rule_file below for the LocalPresets/-specific wrapper around
  # this that the rest of Cable Club actually uses.
  def self.write_rule_file_to_path(path, battle_rule)
    name, desc, rules = battle_rule
    File.open(path, "w:UTF-8") do |f|
      f.puts("[#{name}]")
      f.puts("Description = #{desc}")
      f.puts("TeamPreview = #{rules.team_preview}") if rules.team_preview > 0
      f.puts("PartySize = #{rules.ruleset.minLength},#{rules.ruleset.maxLength}")
      if rules.rules_hash[:level_adjust]
        klass, *tagged_args = rules.rules_hash[:level_adjust]
        f.puts("LevelAdjustment = #{format_rule_clause(klass, *untag_rule_args(tagged_args))}")
      end
      f.puts("BattleMode = #{rules.battle_mode.capitalize}") if rules.battle_mode
      rules.rules_hash[:pokemon].each do |klass, *tagged_args|
        f.puts("PokemonRules = #{format_rule_clause(klass, *untag_rule_args(tagged_args))}")
      end
      rules.rules_hash[:team].each do |klass, *tagged_args|
        f.puts("TeamRules = #{format_rule_clause(klass, *untag_rule_args(tagged_args))}")
      end
    end
    return path
  end

  # Writes battle_rule out to "#{FOLDER_FOR_BATTLE_PRESETS}/#{filename}",
  # creating that directory first if it doesn't exist yet (it isn't checked
  # into the repo, so a fresh install has none until the first save).
  # filename should already end in ".rules" and contain no path separators -
  # sanitizing/overwrite-confirming it is the caller's (the ruleset
  # builder's) job, not this pure writer's.
  def self.write_rule_file(filename, battle_rule)
    Dir.mkdir(FOLDER_FOR_BATTLE_PRESETS) unless Dir.exist?(FOLDER_FOR_BATTLE_PRESETS)
    return write_rule_file_to_path(sprintf("%s/%s", FOLDER_FOR_BATTLE_PRESETS, filename), battle_rule)
  end
end