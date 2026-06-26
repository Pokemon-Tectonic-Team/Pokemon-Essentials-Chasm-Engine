class CableClub_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    @frames += 1
    @sprites["messagebox"].text    = @dots_message + "...".slice(0..(@frames/8) % 3) if @dots_message
  end
  
  def change_state(text=nil); @frames = 0; end
  
  def pbDisplay(text)
    @dots_message = nil
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    @sprites["messagebox"].letterbyletter = true
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::C)
          pbPlayDecisionSE if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      else
        if Input.trigger?(Input::B) || Input.trigger?(Input::C)
          break
        end
      end
    end
  end
  
  def pbDisplayDots(text)
    @sprites["messagebox"].text    = text + "...".slice(0..(@frames/8) % 3)
    @sprites["messagebox"].visible = true
    @sprites["messagebox"].letterbyletter = false
    @dots_message = text
  end
  
  def pbHideMessageBox
    @dots_message = nil
    @sprites["messagebox"].visible = false
  end
  
  # def pbEnterText(helptext,starttext,passwordbox,maxlength)
  #   @dots_message = nil
  #   @sprites["messagebox"].text    = helptext
  #   @sprites["messagebox"].visible = true
  #   @sprites["messagebox"].letterbyletter = false
  #   ret=""
  #   using(window = Window_TextEntry_Keyboard.new(starttext,0,0,240,64)){
  #     window.maxlength=maxlength
  #     window.visible=true
  #     pbPositionNearMsgWindow(window,@sprites["messagebox"],:right)
  #     window.z = @viewport.z+1
  #     window.text=starttext
  #     window.passwordChar="*" if passwordbox
  #     Input.text_input = true
  #     loop do
  #       Graphics.update
  #       Input.update
  #       pbUpdate
  #       if !@sprites["messagebox"].busy?
  #         if Input.triggerex?(:ESCAPE)
  #           ret=""
  #           break
  #         elsif Input.triggerex?(:RETURN)
  #           ret=window.text
  #           break
  #         end
  #       end
  #       window.update
  #     end
  #     Input.text_input = false
  #     window.dispose
  #     Input.update
  #   }
  #   return ret
  # end
  
  def pbShowCommands(helptext,commands,cmdIfCancel=0)
    ret = -1
    @dots_message = nil
    @sprites["messagebox"].text    = helptext
    @sprites["messagebox"].visible = true
    @sprites["messagebox"].letterbyletter = false
    using(cmdwindow = Window_CommandPokemon.new(commands)) {
      cmdwindow.z     = @viewport.z+1
      pbPositionNearMsgWindow(cmdwindow,@sprites["messagebox"],:right)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        pbUpdate
        if Input.trigger?(Input::B)
          pbPlayCancelSE if cmdIfCancel!=0
          if cmdIfCancel>0
            ret=cmdIfCancel-1
            break
          elsif cmdIfCancel<0
            ret=cmdIfCancel
            break
          end
        elsif Input.trigger?(Input::C)
          pbPlayDecisionSE
          ret = cmdwindow.index
          break
        end
      end
    }
    return ret
  end

  def pbStartScene
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"],2)
    @frames = 0
    @dots_message = nil
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
  
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  
  # Shows msg, then an itemized list of ruleset.registrationErrors(party) (if
  # any) the same way pbAttemptConnection reports the Cable Club server's own
  # party errors, so a custom ruleset rejecting a team is explained just as
  # clearly as a server-side rejection.
  def pbDisplayTeamIssues(msg,ruleset,party)
    pbDisplay(msg)
    errors = ruleset.registrationErrors(party)
    pbMessage("Issues:\n" + errors.map { |e| "- #{e}" }.join("\n")) unless errors.empty?
  end

  def pbSelectBattleSettings(partner_party,local_rules,server_rules)
    ret = nil
    type=0
    commands = []
    cmdFreeForAll    = -1
    cmdLocalRule     = -1
    cmdServerRule    = -1
    commands[cmdFreeForAll = commands.length]    = _INTL("Free For All")
    commands[cmdServerRule = commands.length]    = _INTL("Official Rules") if server_rules && !server_rules.empty?
    commands[cmdLocalRule = commands.length]     = _INTL("Custom Rules") if local_rules && !local_rules.empty?
    loop do
      break if ret
      cmd = pbShowCommands(_INTL("Select Battle Ruleset"),commands,-1)
      if cmdFreeForAll>=0 && cmd==cmdFreeForAll
        battle_cmds = [_INTL("Single Battle"),_INTL("Double Battle"),_INTL("Triple Battle")]
        battle_cmd = pbShowCommands(_INTL("Free For All"),battle_cmds,-1)
        if battle_cmd>=0
          rules=PokemonOnlineRules.new
          rules.setTeamPreview(30)
          rules.setNumberRange(1,6)
          if battle_cmd == 1 # double battle
            rules.setNumberRange(2,6)
            rules.setBattleMode("double")
          elsif battle_cmd == 2 # triple battle
            rules.setNumberRange(3,6)
            rules.setBattleMode("triple")
          end
          if !rules.ruleset.hasValidTeam?($Trainer.party)
            pbDisplayTeamIssues(_INTL("I'm sorry, you do not have a valid Pokémon team with these rules."),rules.ruleset,$Trainer.party)
          elsif !rules.ruleset.hasValidTeam?(partner_party)
            pbDisplayTeamIssues(_INTL("I'm sorry, your partner does not have a valid Pokémon team with these rules."),rules.ruleset,partner_party)
          else
            bracket_cmds = [_INTL("FFA"),_INTL("Lv. 70")]
            bracket = pbShowCommands(_INTL("Choose a bracket."),bracket_cmds, -1)
            if bracket >= 0
              case bracket
              when 1; rules.setLevelAdjustment(FixedLevelAdjustment,70)
              end
              desc = sprintf("%s (%s)",battle_cmds[battle_cmd],bracket_cmds[bracket])
              ret = [desc,desc,rules]
              break
            end
          end
        end
      elsif (cmdLocalRule>=0 && cmd==cmdLocalRule) ||
            (cmdServerRule>=0 && cmd==cmdServerRule)
        rule_commands = []
        rule_array = []
        rule_array = local_rules if cmd == cmdLocalRule
        rule_array = server_rules if cmd == cmdServerRule
        rule_array.each do |r|
          rule_commands.push(r[0])
        end
        r_cmd = pbShowCommands(_INTL("Select Battle Ruleset"),rule_commands,-1)
        if r_cmd>=0
          loop do
            conf_cmd = pbShowCommands(_INTL("Ruleset: {1}",rule_array[r_cmd][0]),[_INTL("See Details"),_INTL("Yes"),_INTL("No")],3)
            case conf_cmd
            when 0
              pbDisplay(rule_array[r_cmd][1])
            when 1
              rules = rule_array[r_cmd][2]
              if !rules.ruleset.hasValidTeam?($Trainer.party)
                pbDisplayTeamIssues(_INTL("I'm sorry, you do not have a valid Pokémon team with these rules."),rules.ruleset,$Trainer.party)
              elsif !rules.ruleset.hasValidTeam?(partner_party)
                pbDisplayTeamIssues(_INTL("I'm sorry, your partner does not have a valid Pokémon team with these rules."),rules.ruleset,partner_party)
              else
                ret = rule_array[r_cmd]
                type = ((cmd==cmdLocalRule) ? 1 : 2)
                break
              end
            when 2
              break
            end
          end
        end
      else
        break
      end
    end
    return ret,type
  end
  
  def pbTeamPreview(partner_trainer,partner_party,timer)
    dummy_trainer = NPCTrainer.new($Trainer.name,$Trainer.online_trainer_type)
    pbFadeOutIn(99999){
      scene = TeamPreview_Scene.new
      screen = TeamPreviewScreen.new(scene)
      screen.pbStartScreen(dummy_trainer,$Trainer.party,partner_trainer,partner_party,timer)
    }
  end
end

class CableClubScreen
  def initialize(scene)
    @scene = scene
    @state = nil
    @client_id = 0
    @partner_name = nil
    @partner_trainertype = nil
    @partner_party = nil
    @partner_win_text = nil
    @partner_lose_text = nil
    @local_rules = nil
    @server_rules = nil
    @chosen_pokemon = nil
    @partner_chosen = nil
    @battle_settings = nil
    @local_rules = CableClub.load_local_rules
    @asked_to_save_friend = false
  end
  
  def change_state(new_state)
    if @state != new_state
      @scene.change_state
    end
    @state = new_state
    if block_given?
      loop do
        break if self.update
        yield
      end
    end
  end
  
  def update
    Graphics.update
    Input.update
    @scene.pbUpdate
    if Input.press?(Input::B)
      message = case @state
      when :await_server; _INTL("Abort connection?")
      when :await_partner; _INTL("Abort search?")
      else; _INTL("Disconnect?")
      end
      return true if pbConfirmSerious(message)
    end
    return false
  end
  
  def pbDisplay(text); @scene.pbDisplay(text); end
  def pbDisplayDots(text); @scene.pbDisplayDots(text); end
  def pbHideMessageBox; @scene.pbHideMessageBox; end
  # def pbEnterText(helptext,starttext,passwordbox,maxlength)
  #   @scene.pbEnterText(helptext,starttext,passwordbox,maxlength)
  # end
  def pbShowCommands(helptext,commands,cmdIfCancel=0)
    return @scene.pbShowCommands(helptext,commands,cmdIfCancel)
  end
  def pbConfirm(helptext); return (@scene.pbShowCommands(helptext,[_INTL("Yes"), _INTL("No")],2)==0); end
  def pbConfirmSerious(helptext); return (@scene.pbShowCommands(helptext,[_INTL("No"), _INTL("Yes")],1)==1); end

  # Recovers from a desync that happened before any battle started (e.g. while agreeing
  # on an activity, picking teams, or trading), by notifying the peer and dropping back
  # to the activity hub on the same connection, rather than disconnecting entirely.
  def pbRecoverFromDesync(connection, error)
    CableClub.notify_desync(connection, error)
    error.log_path ||= CableClub.write_desync_log(@client_id, error)
    pbMessage(_INTL("I'm sorry, the connection became out of sync, so that could not be completed."))
    CableClub.show_desync_report(error.log_path)
    if @client_id == 0
      choose_activity(connection)
    else
      await_choose_activity(connection)
    end
  end

  def pbStartScreen
    @scene.pbStartScene
    pbConnectDisconnectSetup
    ret = pbAttemptConnection
    pbConnectDisconnectSetup(true)
    @scene.pbEndScene
    return ret
  end
  
  def pbConnectDisconnectSetup(disconnect=false)
    $Trainer.heal_party if disconnect
  end
  
  def pbAttemptConnection
    if $Trainer.party_count == 0
      pbDisplay(_INTL("I'm sorry, you must have a Pokémon to enter the Cable Club."))
      return false
    end
    begin
      partner_id = pbChooseConnectionID
      return false if !partner_id
      pbConnectServer(partner_id)
      raise Connection::Disconnected.new("disconnected")
    rescue Connection::Disconnected => e
      case e.message
      when "disconnected"
        pbDisplay(_INTL("Thank you for using the Cable Club. We hope to see you again soon."))
        return true
      when /\Ainvalid party/
        msg = _INTL("I'm sorry, your party contains Pokémon not allowed in the Cable Club.")
        details = e.message.split("\n")[1..-1]
        issuesMsg = "Issues:\n" + details.map { |d| "- #{d}" }.join("\n") unless details.empty?
        pbDisplay(msg)
        pbMessage(issuesMsg) # cable club's own pbDisplay override doesn't support multiple lines
        return false
      when "peer disconnected"
        pbDisplay(_INTL("I'm sorry, the other trainer has disconnected."))
        return true
      when "peer already connected"
        pbDisplay(_INTL("I'm sorry, that trainer connected to someone else with the same ID as you."))
        return false
      when "invalid version"
        pbDisplay(_INTL("I'm sorry, your game version is out of date compared to the Cable Club."))
        return false
      else
        pbDisplay(_INTL("I'm sorry, the Cable Club server has malfunctioned!"))
        return false
      end
    rescue Errno::ECONNABORTED
      pbDisplay(_INTL("I'm sorry, the other trainer has disconnected."))
      return true
    rescue Errno::ECONNREFUSED
      pbDisplay(_INTL("I'm sorry, the Cable Club server is down at the moment."))
      return false
    rescue CableClub::DesyncError => e
      e.log_path ||= CableClub.write_desync_log(@client_id, e)
      pbMessage(_INTL("I'm sorry, the connection with the other trainer became out of sync and the Cable Club could not continue."))
      CableClub.show_desync_report(e.log_path)
      return false
    rescue
      pbPrintException($!)
      pbDisplay(_INTL("I'm sorry, the Cable Club has malfunctioned!"))
      return false
    ensure
      pbHideMessageBox
    end
  end

  # Offers a saved friend (picked by name, no retyping) ahead of manual entry,
  # but only if any are saved - so a player who's never used the Friends List
  # sees the exact same manual-entry prompt as before.
  def pbChooseConnectionID
    friends = $PokemonGlobal.cable_club_friends_list
    return pbEnterConnectionID if friends.empty?
    entries = friends.to_a
    cmds = entries.map { |id, name| _INTL("{1} ({2})", name, id) }
    cmds.push(_INTL("Manual Entry"))
    cmds.push(_INTL("Cancel"))
    cmd = pbMessage(_ISPRINTF("Connect to whom? (Yours: {1:05d})",$Trainer.public_ID($Trainer.id)), cmds, cmds.length)
    return entries[cmd][0] if cmd >= 0 && cmd < entries.length
    return pbEnterConnectionID if cmd == entries.length
    return nil
  end

  def pbEnterConnectionID
    msg = _ISPRINTF("Opponent's ID (Yours: {1:05d})",$Trainer.public_ID($Trainer.id))
    partner_id = $PokemonGlobal.last_partner_id || ""
    partner_id = pbEnterText(msg, 0, 5, partner_id)
    if CableClubFriendsList.valid_id?(partner_id)
      $PokemonGlobal.last_partner_id = partner_id
      return partner_id
    else
      pbDisplay(_INTL("Please enter a valid trainer ID of 5 digits."))
      return nil
    end
  end

  def pbConnectServer(partner_id)
    host,port = CableClub::get_server_info
    Connection.open(host,port) do |connection|
      begin
        await_server(connection,partner_id)
      rescue CableClub::DesyncError => e
        # Reached only for desyncs with no recoverable state to fall back to (e.g. while
        # still searching for a partner). Let the other client know before disconnecting,
        # rather than leaving them waiting forever on a connection we're about to abandon.
        CableClub.notify_desync(connection, e)
        raise
      end
    end
  end
  
  # These states handle the connection process itself
  def await_server(connection,partner_id)
    change_state(:await_server){
      if connection.can_send?
        connection.send do |writer|
          writer.sym(:find)
          writer.str(Settings::GAME_VERSION)
          writer.int(partner_id)
          writer.str($Trainer.name)
          writer.int($Trainer.id)
          writer.sym($Trainer.online_trainer_type)
          writer.int($Trainer.online_win_text)
          writer.int($Trainer.online_lose_text)
          CableClub::write_party(writer)
        end
        break
      else
        pbDisplayDots(_ISPRINTF("Your ID: {1:05d}\nConnecting",$Trainer.public_ID($Trainer.id)))
      end
    }
    await_partner(connection)
  end
  
  def await_partner(connection)
    partner_found = false
    change_state(:await_partner){  
      pbDisplayDots(_ISPRINTF("Your ID: {1:05d}\nSearching",$Trainer.public_ID($Trainer.id)))
      connection.update do |record|
        case (type = record.sym)
        when :found
          @client_id = record.int
          @partner_name = record.str
          @partner_trainertype = record.sym
          @partner_win_text = record.int
          @partner_lose_text = record.int
          @partner_party = CableClub::parse_party(record)
          @server_rules = CableClub::parse_battle_rules(record)
          partner_found = true
        else
          raise CableClub::DesyncError, "Unknown message: #{type}"
        end
      end
      break if partner_found
    }
    if partner_found
      pbDisplay(_INTL("{1} connected!", @partner_name))
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
    end
  end
  
  def choose_activity(connection)
    # Disable trades, but still go through this menu, because skipping it causes sync issues when disconnecting
    cmds = [_INTL("Battle")]#, _INTL("Trade")]
    cmds.push(_INTL("Mix Records")) if CableClub::ENABLE_RECORD_MIXER
    cmd = -1
    change_state(:choose_activity){
      cmd = pbShowCommands(_INTL("Choose an activity."), cmds, -1)
      break
    }
    case cmd
    when 0 # Battle
      @battle_settings = nil
      choose_battle_settings(connection)
    when 1 # Trade
      connection.send do |writer|
        writer.sym(:trade)
      end
      await_accept_activity(connection,:trade,:choose_trade_pokemon)
    when 2 # # Mix Records
      connection.send do |writer|
        writer.sym(:record_mix)
      end
      await_accept_activity(connection,:record_mix,:do_mix_records)
    else # Cancel/Disconnect
      # TODO: Confirmation box?
    end
  end
  
  def await_accept_activity(connection,activity,method_on_accept)
    accepted = nil
    begin
      change_state(:await_accept_activity){
        pbDisplayDots(_INTL("Waiting for {1} to accept", @partner_name))
        connection.update do |record|
          case (type = record.sym)
          when :ok
            accepted = true
          when :cancel
            accepted = false
          else
            raise CableClub::DesyncError, "Unknown message: #{type}"
          end
        end
        break unless accepted.nil?
      }
    rescue CableClub::DesyncError => e
      return pbRecoverFromDesync(connection, e)
    end
    if accepted
      self.send(method_on_accept,connection)
    else
      activity_name = _INTL(CableClub::ACTIVITY_OPTIONS[activity])
      pbDisplay(_INTL("I'm sorry, {1} doesn't want to {2}.", @partner_name, activity_name))
      choose_activity(connection)
    end
  end
  
  def await_choose_activity(connection)
    method_for_accepting = nil
    begin
      change_state(:await_accept_activity){
        pbDisplayDots(_INTL("Waiting for {1} to pick an activity", @partner_name))
        connection.update do |record|
          case (type = record.sym)
          when :battle
            method_for_accepting = :partner_accept_battle
            seed = record.int
            battle_origin = record.int
            battle_rule = CableClub::parse_battle_rule(record)
            @battle_settings = [seed,battle_rule,battle_origin]
          when :trade
            method_for_accepting = :partner_accept_trade
          when :record_mix
            method_for_accepting = :partner_accept_record_mix
          else
            raise CableClub::DesyncError, "Unknown message: #{type}"
          end
        end
        break if method_for_accepting
      }
    rescue CableClub::DesyncError => e
      return pbRecoverFromDesync(connection, e)
    end
    self.send(method_for_accepting,connection) if method_for_accepting
  end
  
  # These methods handle battles
  def choose_battle_settings(connection)
    battle_rule,battle_origin = @scene.pbSelectBattleSettings(@partner_party,@local_rules,@server_rules)
    if battle_rule
      connection.send do |writer|
        writer.sym(:battle)
        seed = rand(2**31)
        writer.int(seed)
        writer.int(battle_origin)
        CableClub::write_battle_rule(writer,battle_rule)
        @battle_settings = [seed,battle_rule,battle_origin]
      end
      await_accept_activity(connection,:battle,:battle_check_team_preview)
    else
      choose_activity(connection)
    end
  end
  
  def partner_accept_battle(connection)
    accepted = false
    origin_string = [_INTL("Quick Ruleset"),_INTL("Local Ruleset"),_INTL("Server Ruleset")][@battle_settings[2]]
    loop do
      cmd = pbShowCommands(_INTL("{1} wants to battle!\n{2}: {3}", @partner_name,origin_string,@battle_settings[1][0]),[_INTL("See Details"),_INTL("Yes"),_INTL("No")],3)
      case cmd
      when 0
        pbDisplay(@battle_settings[1][1])
      when 1
        accepted = true
        connection.send do |writer|
          writer.sym(:ok)
        end
        break
      when 2
        connection.send do |writer|
          writer.sym(:cancel)
        end
        break
      end
    end
    if accepted
      battle_check_team_preview(connection)
    else
      await_choose_activity(connection)
    end
  end
  
  def battle_check_team_preview(connection)
    team_order = nil
    partner_order = nil
    cancel_battle = false
    cancel_partner = false
    battle_rules = @battle_settings[1][2]
    if battle_rules.team_preview?
      level_adjust=battle_rules.rules_hash[:level_adjust]
      level_string=_INTL("FFA")
      if level_adjust
        level_string=_INTL("Cust.")
        if level_adjust[0] == FixedLevelAdjustment
          level_string=sprintf("%d",level_adjust[1][1])
        end
      end
      partner = NPCTrainer.new(@partner_name, @partner_trainertype)
      @scene.pbTeamPreview(partner,@partner_party,battle_rules.team_preview)
    end
    team_order = CableClub::choose_team(battle_rules.ruleset)
    connection.send do |writer|
      if team_order.nil?
        writer.sym(:cancel)
      else
        writer.sym(:ok)
        writer.int(team_order.length)
        team_order.length.times do |i|
          writer.int(team_order[i])
        end
      end
    end
    if team_order
      begin
        change_state(:await_battle_order){
          pbDisplayDots(_INTL("Waiting for {1} to pick their team", @partner_name))
          connection.update do |record|
            case (type = record.sym)
            when :ok
              partner_order = []
              record.int.times do
                partner_order.push(record.int)
              end
            when :cancel
              cancel_partner = true
            else
              raise CableClub::DesyncError, "Unknown message: #{type}"
            end
          end
          break if partner_order || cancel_partner
        }
      rescue CableClub::DesyncError => e
        return pbRecoverFromDesync(connection, e)
      end
    else
      connection.discard(1)
      cancel_battle = true
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
    end
    if cancel_battle || cancel_partner
      pbDisplay(_INTL("I'm sorry, {1} doesn't want to battle.", @partner_name)) if cancel_partner
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
    else
      do_battle(connection,team_order,partner_order)
    end
  end
  
  def do_battle(connection,team_order,partner_order)
    partner = NPCTrainer.new(@partner_name, @partner_trainertype)
    partner.win_text =  _INTL(CableClub::ONLINE_WIN_SPEECHES_LIST[@partner_win_text])
    partner.lose_text = _INTL(CableClub::ONLINE_LOSE_SPEECHES_LIST[@partner_lose_text])
    seed,battle_rules = @battle_settings
    party_player = $Trainer.party
    if team_order
      party_player=[]
      team_order.each do |i|
        party_player.push($Trainer.party[i])
      end
    end
    party_partner = @partner_party
    if partner_order
      party_partner=[]
      partner_order.each do |i|
        party_partner.push(@partner_party[i])
      end
    end
    # Team preview (if shown) reveals the partner's whole brought roster, not just the subset
    # they end up using - carry that through so the Poké X-Ray's notes can still list the rest
    # as "Not Brought" once the pick cap is reached, instead of forgetting they were ever seen.
    previewed_opponent_party = battle_rules[2].team_preview? ? @partner_party.clone : nil
    decision = CableClub::do_battle(connection, @client_id, seed, battle_rules[2], party_player, partner, party_partner, previewed_opponent_party: previewed_opponent_party, opponent_standby_party: @partner_party)
    pbOfferSaveFriend
    @battle_settings = nil
    if @client_id == 0
      choose_activity(connection)
    else
      await_choose_activity(connection)
    end
  end

  # Offers to save the just-battled opponent to the Friends List, defaulting
  # the label to their in-game name but never forcing it (issue #493). Only
  # asks once per connection (not after every rematch against the same
  # partner), and not at all if they're already saved.
  def pbOfferSaveFriend
    return if @asked_to_save_friend
    @asked_to_save_friend = true
    friends = $PokemonGlobal.cable_club_friends_list
    partner_id = $PokemonGlobal.last_partner_id
    return if partner_id.nil? || friends.include?(partner_id)
    return unless pbConfirmMessage(_INTL("Save {1} to your Friends List?", @partner_name))
    typed = pbEnterText(_INTL("Save this friend as?"), 0, Settings::MAX_PLAYER_NAME_SIZE, @partner_name)
    name = typed.empty? ? @partner_name : typed
    friends.add(partner_id, name)
    pbMessage(_INTL("{1} was added to your Friends List.", name))
  end

  # These methods handle trading pokemon
  def partner_accept_trade(connection)
    if pbConfirm(_INTL("{1} wants to trade!", @partner_name))
      connection.send do |writer|
        writer.sym(:ok)
      end
      choose_trade_pokemon(connection)
    else
      connection.send do |writer|
        writer.sym(:cancel)
      end
      await_choose_activity(connection)
    end
  end
  
  def choose_trade_pokemon(connection)
    @chosen_pokemon = CableClub.choose_pokemon
    if @chosen_pokemon >= 0
      connection.send do |writer|
        writer.sym(:ok)
        writer.int(@chosen_pokemon)
      end
      confirm_trade_pokemon(connection)
    else
      connection.send do |writer|
        writer.sym(:cancel)
      end
      connection.discard(1)
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
    end
  end
  
  def confirm_trade_pokemon(connection)
    @partner_chosen = nil
    begin
      change_state(:await_trade){
        pbDisplayDots(_INTL("Waiting for {1} to pick a Pokémon", @partner_name))
        connection.update do |record|
          case (type = record.sym)
          when :ok
            @partner_chosen = record.int
          when :cancel
            @partner_chosen = -1
          else
            raise CableClub::DesyncError, "Unknown message: #{type}"
          end
        end
        break if !@partner_chosen.nil?
      }
    rescue CableClub::DesyncError => e
      return pbRecoverFromDesync(connection, e)
    end
    trade_state = :waiting
    if @partner_chosen>=0
      $Trainer.heal_party
      @partner_party.each {|pkmn| pkmn.heal}
      partner_pkmn = @partner_party[@partner_chosen]
      your_pkmn = $Trainer.party[@chosen_pokemon]
      abort=$Trainer.able_pokemon_count==1 && your_pkmn==$Trainer.able_party[0] && partner_pkmn.egg?
      able_party=@partner_party.find_all { |p| p && !p.egg? && p.hp>0 }
      abort|=able_party.length==1 && partner_pkmn==able_party[0] && your_pkmn.egg?
      unless abort
        partner_speciesname = (partner_pkmn.egg?) ? _INTL("Egg") : partner_pkmn.speciesName
        your_speciesname = (your_pkmn.egg?) ? _INTL("Egg") : your_pkmn.speciesName
        loop do
          cmd = pbShowCommands(_INTL("{1} has offered {2} ({3}) for your {4} ({5}).",
                                      @partner_name,partner_pkmn.name,partner_speciesname,your_pkmn.name,your_speciesname),
                                      [_INTL("Check {1}'s offer",@partner_name), _INTL("Check My Offer"), _INTL("Accept Trade"),_INTL("Deny Trade")],-1)
          case cmd
          when 0 # Partner offer
            CableClub::check_pokemon(partner_pkmn)
          when 1 # Your offer
            CableClub::check_pokemon(your_pkmn)
          when 2 # Accept Trade
            trade_state = :ok
            connection.send do |writer|
              writer.sym(:ok)
            end
            break
          when 3 # Deny Trade
            trade_state = :denied
            connection.send do |writer|
              writer.sym(:cancel)
            end
            connection.discard(1)
            break
          end
        end
        await_trade_partner(connection) if trade_state == :ok
      else
        trade_state = :abort
      end
    else
      trade_state = :cancel
    end
    @chosen_pokemon = nil
    @partner_chosen = nil
    case trade_state
    when :cancel; pbDisplay(_INTL("I'm sorry, {1} doesn't want to trade.", @partner_name))
    when :abort; pbDisplay(_INTL("I'm sorry, the trade was unable to be completed.", @partner_name))
    end
    if @client_id == 0
      choose_activity(connection)
    else
      await_choose_activity(connection)
    end
  end
  
  def await_trade_partner(connection)
    partner_confirm = nil
    begin
      change_state(:confirm_trade){
        pbDisplayDots(_INTL("Waiting for {1} to confirm the trade", @partner_name))
        connection.update do |record|
          case (type = record.sym)
          when :ok
            partner_confirm = true
          when :cancel
            partner_confirm = false
          else
            raise CableClub::DesyncError, "Unknown message: #{type}"
          end
        end
        break if !partner_confirm.nil?
      }
    rescue CableClub::DesyncError => e
      return pbRecoverFromDesync(connection, e)
    end
    if partner_confirm
      do_trade(connection)
    else
      pbDisplay(_INTL("I'm sorry, {1} denied the trade.", @partner_name))
    end
  end
  
  def do_trade(connection)
    partner = NPCTrainer.new(@partner_name, @partner_trainertype)
    pkmn = @partner_party[@partner_chosen]
    CableClub::do_trade(@chosen_pokemon, partner, pkmn)
    connection.send do |writer|
      writer.sym(:update)
      CableClub::write_pkmn(writer, $Trainer.party[@chosen_pokemon])
    end
    resync=false
    begin
      change_state(:resync_trade){
        pbDisplayDots(_INTL("Waiting for {1} to resynchronize", @partner_name))
        connection.update do |record|
          case (type = record.sym)
          when :update
            @partner_party[@partner_chosen] = CableClub::parse_pkmn(record)
            resync = true
          else
            raise CableClub::DesyncError, "Unknown message: #{type}"
          end
        end
        break if resync
      }
    rescue CableClub::DesyncError => e
      return pbRecoverFromDesync(connection, e)
    end
  end

  # these methods are for record mixing
  def partner_accept_record_mix(connection)
    if pbConfirm(_INTL("{1} wants to mix records!", @partner_name))
      connection.send do |writer|
        writer.sym(:ok)
      end
      do_mix_records(connection)
    else
      connection.send do |writer|
        writer.sym(:cancel)
      end
      await_choose_activity(connection)
    end
  end
  
  def do_mix_records(connection)
    begin
      CableClub::do_mix_records(connection) do |text|
        pbDisplayDots(text)
      end
    rescue CableClub::DesyncError => e
      return pbRecoverFromDesync(connection, e)
    end
    pbDisplay(_INTL("Record Mixing Completed!"))
    if @client_id == 0
      choose_activity(connection)
    else
      await_choose_activity(connection)
    end
  end
end

class TeamPreview_Scene
  def update
    pbUpdateSpriteHash(@sprites)
    if @enable_timer
      curtime=@timer-(Time.now-@start)
      if curtime != @total_sec
        # Calculate total number of seconds
        @total_sec = curtime
        # Make a string for displaying the timer
        min = @total_sec / 60
        sec = @total_sec % 60
        @sprites["timer"].text = _ISPRINTF("{1:02d}:{2:02d}", min, sec) + "<r>" + _INTL("Press ESC to skip")
      end
    end
  end

  def pbStartScene(left_trainer,left_party,right_trainer,right_party,timer)
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    addBackgroundPlane(@sprites,"background","CableClub/bg_team_preview",@viewport)
    @sprites["card"]=IconSprite.new(0,16,@viewport)
    @sprites["card"].setBitmap("Graphics/Pictures/CableClub/overlay_team_preview")
    left_party.each_with_index do |pkmn, i|
      base_x = ((i%2)*128)
      base_y = ((i/2)*80)
      @sprites["party_l#{i}"] = PokemonIconSprite.new(pkmn,@viewport)
      @sprites["party_l#{i}"].x = base_x + 32
      @sprites["party_l#{i}"].y = base_y + 52
      @sprites["item_l#{i}"] = HeldItemIconSprite.new((base_x+72),(base_y+96),pkmn.items[0],@viewport)
      @sprites["item_l2#{i}"] = HeldItemIconSprite.new((base_x+80),(base_y+100),pkmn.items[1],@viewport)
    end
    right_party.each_with_index do |pkmn, i|
      base_x = ((i%2)*128)
      base_y = ((i/2)*80)
      @sprites["party_r#{i}"] = PokemonIconSprite.new(pkmn,@viewport)
      @sprites["party_r#{i}"].x = base_x + 288
      @sprites["party_r#{i}"].y = base_y + 52
      @sprites["item_r#{i}"] = HeldItemIconSprite.new((base_x+328),(base_y+96),pkmn.items[0],@viewport)
      @sprites["item_r2#{i}"] = HeldItemIconSprite.new((base_x+336),(base_y+100),pkmn.items[1],@viewport)
    end
    @sprites["timer"] = Window_AdvancedTextPokemon.newWithSize("",0,Graphics.height-64,Graphics.width,64)
    @sprites["timer"].viewport = @viewport
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTeamPreviewText(left_trainer.name,right_trainer.name,left_party,right_party)
    @start=Time.now
    @timer=timer
    @total_sec=@timer
    @enable_timer = false
    pbFadeInAndShow(@sprites) { update }
  end

  def pbDrawTeamPreviewText(left_name,right_name,left_party,right_party)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor=Color.new(216,216,216)
    shadowColor=Color.new(80,80,80)
    text_pos = [
      [left_name,114,10,2,baseColor,shadowColor],
      [right_name,398,10,2,baseColor,shadowColor],
    ]
    left_party.each_with_index do |pkmn, i|
      base_x = ((i%2)*128)
      base_y = ((i/2)*74)
      text_pos.push([pkmn.name,(base_x+64),(base_y+110),2,baseColor,shadowColor])
      if pkmn.male?
        text_pos.push([_INTL("♂"),(base_x+96),(base_y+58),false,Color.new(0,112,248),Color.new(120,184,232)])
      elsif pkmn.female?
        text_pos.push([_INTL("♀"),(base_x+96),(base_y+58),false,Color.new(232,32,16),Color.new(248,168,184)])
      end
    end
    right_party.each_with_index do |pkmn, i|
      base_x = ((i%2)*128)
      base_y = ((i/2)*74)
      text_pos.push([pkmn.name,(base_x+320),(base_y+110),2,baseColor,shadowColor])
      if pkmn.male?
        text_pos.push([_INTL("♂"),(base_x+350),(base_y+58),false,Color.new(0,112,248),Color.new(120,184,232)])
      elsif pkmn.female?
        text_pos.push([_INTL("♀"),(base_x+350),(base_y+58),false,Color.new(232,32,16),Color.new(248,168,184)])
      end
    end
    pbDrawTextPositions(overlay,text_pos)
  end
  
  def pbPreviewTeam
    @enable_timer = true
    loop do
      Graphics.update
      Input.update
      self.update
      if Input.trigger?(Input::B) || @total_sec <= 0
        @enable_timer = false
        @sprites["timer"].text = "00:00<r>" + _INTL("Press ESC to skip")
        break
      end
    end 
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class TeamPreviewScreen
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(left_trainer,left_party,right_trainer,right_party,timer)
    @scene.pbStartScene(left_trainer,left_party,right_trainer,right_party,timer)
    @scene.pbPreviewTeam
    @scene.pbEndScene
  end
end