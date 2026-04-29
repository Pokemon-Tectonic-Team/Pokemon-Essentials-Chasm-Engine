def incrementSuccessfulCaptureCount(ball)
    $PokemonGlobal.capture_counts_per_ball = {} if $PokemonGlobal.capture_counts_per_ball.nil?
    if $PokemonGlobal.capture_counts_per_ball.key?(ball)
        $PokemonGlobal.capture_counts_per_ball[ball] += 1
    else
        $PokemonGlobal.capture_counts_per_ball[ball] = 1
    end
    checkForCapturesWithBallsAchievements unless $battle.is_replayed
end

def checkForCapturesWithBallsAchievements

end


def checkForCaptureAchievements(ball, battle, pkmn)

end