ItemHandlers::UseFromBag.add(:BATTLEREPORT, proc { |_item|
    if levelCapMaxed?
        pbMessage(_INTL("You are too skilled to learn any more from a battle report."))
        next 0
    else
        increaseLevelCap(5)
        next 3
    end
})
