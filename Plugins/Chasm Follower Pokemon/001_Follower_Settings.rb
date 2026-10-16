module FollowerSettings
  # Common event that contains "pbTalkToFollower" in  a script command
  # Change this if you are not using the CommonEvents.rxdata provided in the script.
  FOLLOWER_COMMON_EVENT         = 5

  # Animation IDs from followers
  # Change this if you are not using the Animations.rxdata provided in the script.
  Animation_Come_Out  = 30
  Animation_Come_In   = 29
  Emo_Happy           = 10
  Emo_Normal          = 13
  Emo_Sad             = 14
  Emo_Hate            = 15
  Emo_Poison          = 17
  Emo_Sing            = 12
  Emo_Love            = 9
  Emo_Confused        = 4

  #Status tones to be used, if this is true (Red,Green,Blue,Gray)
  APPLYSTATUSTONES = true
  BURNTONE         = [150,40,40,120]
  POISONTONE       = [153,71,112,120]
  NUMBTONE         = [120,120,72,120]
  FROSTBITETONE    = [112,150,150,120]
  SLEEPTONE        = [0,0,0,120]
  DIZZYTONE        = [140,70,120,120]
  LEECHEDTONE      = [80,100,50,120]
  WATERLOGTONE  = [60,60,100,120]

  def self.getToneFromStatus(status)
    case status
    when :BURNED
      return BURNTONE
    when :FROSTBITE
      return FROSTBITETONE
    when :POISON
      return POISONTONE
    when :NUMB
      return NUMBTONE
    when :SLEEP
      return SLEEPTONE
    when :DIZZY
      return DIZZYTONE
    when :LEECHED
      return LEECHEDTONE
    when :WATERLOG
      return WATERLOGTONE
    end
    return nil
  end
end
#===============================================================================
# DO NOT TOUCH THIS UNDER ANY CIRCUMSTANCES
#===============================================================================
class FollowerEvent < Event
  def trigger(*arg)
    for callback in @callbacks
      ret = callback.call(*arg)
      return ret if ret == true || ret == false
    end
    return -1
  end
end

module Events
  @@OnTalkToFollower = FollowerEvent.new
  def self.OnTalkToFollower;     @@OnTalkToFollower;     end
  def self.OnTalkToFollower=(v); @@OnTalkToFollower = v; end

  @@FollowerRefresh = FollowerEvent.new
  def self.FollowerRefresh;     @@FollowerRefresh;     end
  def self.FollowerRefresh=(v); @@FollowerRefresh = v; end
end

echoln("Loaded plugin: Overworld Shadows EX") if Essentials::VERSION != "19.1"
