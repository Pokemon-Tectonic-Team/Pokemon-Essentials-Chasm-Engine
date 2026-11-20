$BallTypes = {
  0  => :POKEBALL,
  1  => :GREATBALL,
  2  => :SAFARIBALL,
  3  => :ULTRABALL,
  4  => :MASTERBALL,
  5  => :NESTBALL,
  6  => :REPEATBALL,
  7  => :TIMERBALL,
  8 => :LUXURYBALL,
  9 => :PREMIERBALL,
  10 => :HEALBALL,
  11 => :QUICKBALL,
  12 => :CHERISHBALL,
  13 => :FASTBALL,
  14 => :HEAVYBALL,
  15 => :FRIENDBALL,
  16 => :SPORTBALL,
  17 => :DREAMBALL,
  18 => :BEASTBALL,
  19 => :BALLLAUNCHER,
  20 => :SLICEBALL,
  21 => :ROYALBALL,
  22 => :LEECHBALL,
  23 => :POTIONBALL,
  24 => :DISABLEBALL,
}

def pbBallTypeToItem(ball_type)
    ret = GameData::Item.try_get($BallTypes[ball_type])
    return ret if ret
    ret = GameData::Item.try_get($BallTypes[0])
    return ret if ret
    return GameData::Item.get(:POKEBALL)
end

def pbGetBallType(ball)
    ball = GameData::Item.try_get(ball)
    $BallTypes.keys.each do |key|
        return key if ball == $BallTypes[key]
    end
    return 0
end
