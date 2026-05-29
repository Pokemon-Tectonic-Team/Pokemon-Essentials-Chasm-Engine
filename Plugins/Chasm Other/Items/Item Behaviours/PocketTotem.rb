ItemHandlers::UseFromBag.add(:POCKETTOTEM, proc { |_item|
    next 2 if canTeleport?(true)
    next 0
})

ItemHandlers::ConfirmUseInField.add(:POCKETTOTEM, proc { |_item|
    next canTeleport?(true)
})

ItemHandlers::UseInField.add(:POCKETTOTEM, proc { |_item|
    $waypoints_tracker.warpByWaypoints(true)
    next 1
})
