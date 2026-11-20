def battlePointsShop
	# Generate the shop
	shopEntries = {
		:EXPCANDYXL => 2,
		:FIGMENT => 5,
		:MASTERBALL => 15,
		:GLEAMPOWDER => 50,
		:RELICCROWN => 100,
		:BOXLINK => 50,
		:STYLINGKIT => 50,
		:SWEETTOOTH => 75,
	}

	stock = shopEntries.keys
	shopEntries.each do |key, value|
		setPrice(key, value)
	end

	pbBattlePointsMart(stock,_INTL("Welcome to the battle points shop!"))
end