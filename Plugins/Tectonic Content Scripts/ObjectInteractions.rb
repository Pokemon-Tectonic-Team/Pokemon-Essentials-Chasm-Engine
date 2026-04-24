def ironcladPunchingBag(playerCompetent = false)
    choices = []
    choices.push(_INTL("Leave it."))
    choices.push(_INTL("Punch it!"))
    choices.push(_INTL("Kick it!"))
    choices.push(_INTL("Hug it?"))
    choice = pbMessage(_INTL("A hanging bag. Give it a hit?"),choices)
    case choice
    when 0
        pbMessage(_INTL("You decide to leave it alone."))
    when 1
        pbMessage(_INTL("...!"))
        if playerCompetent
            pbMessage(_INTL("Your fist makes a satisfying thud against the bag."))
        else
            pbMessage(_INTL("Oww, you hurt your wrist!"))
        end
    when 2
        pbMessage(_INTL("...!"))
        if playerCompetent
            pbMessage(_INTL("You thrust your hips at the right time, and send the 
bag swinging!"))
        else
            pbMessage(_INTL("You swing your leg at the bag, to little effect."))
        end
    when 3
        pbMessage(_INTL("You hug the bag."))
        pbMessage(_INTL("You get some strange looks from around the gym."))
    end
end