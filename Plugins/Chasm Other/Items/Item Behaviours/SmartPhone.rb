ItemHandlers::UseFromBag.add(:SMARTPHONE, proc { |_item|
    next 2
})

ItemHandlers::ConfirmUseInField.add(:SMARTPHONE, proc { |_item|
    next true
})

ItemHandlers::UseInField.add(:SMARTPHONE, proc { |_item|
    next takeSelfie
})
