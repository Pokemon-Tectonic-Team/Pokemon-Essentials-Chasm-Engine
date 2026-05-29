ItemHandlers::ConfirmUseInField.add(:BOXLINK, proc { |_item|
    next teamEditingAllowed?
})

ItemHandlers::UseInField.add(:BOXLINK, proc { |_item|
    estateDisablementBefore = getGlobalSwitch(ESTATE_DISABLED_SWITCH)
    setGlobalSwitch(ESTATE_DISABLED_SWITCH, true)
    pbPokeCenterPC
    setGlobalSwitch(ESTATE_DISABLED_SWITCH, estateDisablementBefore)
    next 1
})
