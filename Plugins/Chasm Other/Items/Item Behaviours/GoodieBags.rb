def getGoodieBagItemList
	return $GoodieBagContents.clone unless $GoodieBagContents.nil?
	$GoodieBagContents = {}
	GameData::Item.each do |itemData|
		next unless itemData.is_in_goodie_bags?
		price = itemData.price
		price /= 2 if itemData.is_exp_candy? # Fudge the price of EXP candy
		$GoodieBagContents[itemData.id] = price
	end
	$GoodieBagContents = $GoodieBagContents.sort_by { |itemID, price| -price}.to_h
	return $GoodieBagContents.clone
end

def openGoodieBag(item,moneyLeft,maxItemCount)
	pbUseItemMessage(item)
	
	itemsReceived, moneyLeft = generateGoodieBagContents(moneyLeft,maxItemCount)

	itemsReceived.each do |itemReceived, quantity|
		pbReceiveItem(itemReceived, quantity)
	end
	unless moneyLeft.zero?
		$Trainer.money += moneyLeft
		pbMessage(_INTL("The goodie bag also contained ${1}!", moneyLeft.to_s_formatted))
	end
	
	return 3
end

def generateGoodieBagContents(moneyLeft,maxItemCount)
	possibleItemList = getGoodieBagItemList

	itemsReceived = {}
	until possibleItemList.empty? || itemsReceived.length >= maxItemCount

		# Reject items that are too expensive
		possibleItemList.reject! { |itemID, price|
			price > moneyLeft
		}

		if possibleItemList.keys.length == 0
			break
		elsif possibleItemList.keys.length == 1
			chosenItem = possibleItemList.keys[0]
		else
			mean = possibleItemList.length * 0.3 # Left biased
			stddev = possibleItemList.length / 2.0 # Relatively broad distribution
			gaussX, gaussY = gaussian(mean, stddev)

			gaussX = gaussX.floor
			gaussX = [0,gaussX].max
			gaussX = [gaussX,possibleItemList.length - 1].min
			chosenItem = possibleItemList.keys[gaussX]

			echoln("Random: #{gaussX} / #{possibleItemList.length}")
		end

		amount = 1
		# If price low, add multiple
		while (possibleItemList[chosenItem] * amount) < (moneyLeft / maxItemCount)
			amount += 1
		end
		itemsReceived[chosenItem] = amount

		moneyLeft -= possibleItemList[chosenItem] * amount # Account for spent money
	end

	echoln("")
	echoln("Goodie bag contents:")
	itemsReceived.each do |itemReceived, quantity|
		echoln("  #{itemReceived} (#{quantity})")
	end
	echoln("  $#{moneyLeft}")

	return itemsReceived, moneyLeft
end

def gaussian(mean, stddev)
	theta = 2 * Math::PI * Random.rand
	rho = Math.sqrt(-2 * Math.log(1 - Random.rand))
	scale = stddev * rho
	x = mean + scale * Math.cos(theta)
	y = mean + scale * Math.sin(theta)
	return x, y
end

def GGBC(bagTier = 1)
	bagTier -= 1
	generateGoodieBagContents(GOODIE_BAG_VALUES[bagTier],GOODIE_BAG_SIZES[bagTier])
end

GOODIE_BAG_VALUES = [3200,6400,12800,25_600,51_200]
GOODIE_BAG_SIZES = [4,4,5,5,6]
  
ItemHandlers::UseInField.add(:GOODIEBAGT1,proc { |item|
	next openGoodieBag(item,GOODIE_BAG_VALUES[0],GOODIE_BAG_SIZES[0])
})

ItemHandlers::UseInField.add(:GOODIEBAGT2,proc { |item|
	next openGoodieBag(item,GOODIE_BAG_VALUES[1],GOODIE_BAG_SIZES[1])
})

ItemHandlers::UseInField.add(:GOODIEBAGT3,proc { |item|
	next openGoodieBag(item,GOODIE_BAG_VALUES[2],GOODIE_BAG_SIZES[2])
})

ItemHandlers::UseInField.add(:GOODIEBAGT4,proc { |item|
	next openGoodieBag(item,GOODIE_BAG_VALUES[3],GOODIE_BAG_SIZES[3])
})

ItemHandlers::UseInField.add(:GOODIEBAGT5,proc { |item|
	next openGoodieBag(item,GOODIE_BAG_VALUES[4],GOODIE_BAG_SIZES[4])
})