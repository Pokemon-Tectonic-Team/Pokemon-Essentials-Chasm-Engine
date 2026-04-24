ItemHandlers::UseFromBag.add(:CARNATIONSIGIL,proc { |item|
    next 0 unless canTeleport?(true)
    showCarnationSigilUseMessage
    next 2
})

ItemHandlers::ConfirmUseInField.add(:CARNATIONSIGIL,proc { |item|
  next false unless canTeleport?(true)
  showCarnationSigilUseMessage
  next true
})

def showCarnationSigilUseMessage
    pbMessage(_INTL("You feel yourself being pulled away."))
end

ItemHandlers::UseInField.add(:CARNATIONSIGIL,proc { |item|
    next useCarnationSigil
})

def useCarnationSigil
    commands = []
    commands.push(_INTL("The Tower"))
    commands.push(_INTL("The Stockpile"))
    commands.push(_INTL("Cancel"))
    choiceNumber = pbMessage(_INTL("Where would you like to go?"),commands,commands.length)
    case choiceNumber
    when 0
        transferPlayerToEvent(30,Down,186)
        return 1
    when 1
        transferPlayerToEvent(13,Down,126)
        return 1
    when 2
        return 0
    end
end