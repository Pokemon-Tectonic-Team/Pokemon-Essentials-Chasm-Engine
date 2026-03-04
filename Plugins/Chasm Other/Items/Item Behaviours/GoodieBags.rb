def getGoodieBagItemList
	return $GoodieBagContents unless $GoodieBagContents.nil?
	$GoodieBagContents = {}
	$GoodieBagContents[:EXP_CANDY] = {}
	$GoodieBagContents[:OTHER] = {}
	GameData::Item.each do |itemData|
		next unless itemData.is_in_goodie_bags?
		price = itemData.price
		if itemData.is_exp_candy?
			$GoodieBagContents[:EXP_CANDY][itemData.id] = price
		else
			$GoodieBagContents[:OTHER][itemData.id] = price
		end
	end
	$GoodieBagContents[:EXP_CANDY] = $GoodieBagContents[:EXP_CANDY].sort_by { |itemID, price| -price}.to_h
	$GoodieBagContents[:OTHER] 	   = $GoodieBagContents[:OTHER].sort_by { |itemID, price| -price}.to_h
	return $GoodieBagContents
end

def openGoodieBag(item,totalMoney,maxItemCount)
	pbUseItemMessage(item)
	
	# Randomize money amount
	totalMoney = randomizeGoodieBagValue(totalMoney)

	itemsReceived, moneyLeft = generateGoodieBagContents(totalMoney,maxItemCount)

	itemsReceived.each do |itemReceived, quantity|
		pbReceiveItem(itemReceived, quantity)
	end
	unless moneyLeft.zero?
		$Trainer.money += moneyLeft
		pbMessage(_INTL("The goodie bag also contained ${1}!", moneyLeft.to_s_formatted))
	end
	
	return 3
end

def generateGoodieBagContents(totalMoney,maxItemCount)
	itemLists = getGoodieBagItemList

	moneySpentOnCandy = 0

	moneyLeft = totalMoney
	itemsReceived = {}

	expCandyList = itemLists[:EXP_CANDY]
	expCandyList.each_pair do |expCandy, price|
		next if price > (moneyLeft / 4)
		amount = 1
		# If price low, add multiple
		moneyThreshold = [3.0,3.5,4.0].sample
		while (price * amount) < (moneyLeft / moneyThreshold)
			amount += 1
		end
		itemsReceived[expCandy] = amount
		moneySpending = price * amount # Account for spent money
		moneyLeft -= moneySpending
		moneySpentOnCandy = moneySpending
		break if moneyLeft < totalMoney / 2
	end

	moneySpentOnOther = 0
	possibleOtherItemList = itemLists[:OTHER].clone

	until possibleOtherItemList.empty? || itemsReceived.length >= maxItemCount
		# Reject items that are too expensive
		possibleOtherItemList.reject! { |itemID, price|
			price > moneyLeft
		}

		if possibleOtherItemList.keys.length == 0
			break
		elsif possibleOtherItemList.keys.length == 1
			chosenItem = possibleOtherItemList.keys[0]
		else
			mean = possibleOtherItemList.length * 0.3 # Left biased
			stddev = possibleOtherItemList.length / 2.0 # Relatively broad distribution
			gaussX, gaussY = gaussian(mean, stddev)

			gaussX = gaussX.floor
			gaussX = [0,gaussX].max
			gaussX = [gaussX,possibleOtherItemList.length - 1].min
			chosenItem = possibleOtherItemList.keys[gaussX]

			echoln("Random: #{gaussX} / #{possibleOtherItemList.length}")
		end

		amount = 1
		# If price low, add multiple
		while (possibleOtherItemList[chosenItem] * amount) < (moneyLeft / maxItemCount)
			amount += 1
		end
		itemsReceived[chosenItem] = amount

		moneySpending = possibleOtherItemList[chosenItem] * amount # Account for spent money
		moneyLeft -= moneySpending
		moneySpentOnOther += moneySpending
	end

	echoln("")
	echoln("Goodie bag: (value #{totalMoney})")
	itemsReceived.each do |itemReceived, quantity|
		echoln("  #{itemReceived} (#{quantity})")
	end
	echoln("  $#{moneyLeft}")
	echoln("#{((10_000 * moneySpentOnCandy / totalMoney.to_f).floor / 100).to_s_formatted} percent of money spent on candy.")

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
	totalMoney = randomizeGoodieBagValue(GOODIE_BAG_VALUES[bagTier])
	bagSize = GOODIE_BAG_SIZES[bagTier]
	generateGoodieBagContents(totalMoney,bagSize)
end

# Differ by +/- 20%
def randomizeGoodieBagValue(totalMoney)
	totalMoney *= (0.8 + (0.4 * Random.rand))
	totalMoney = (totalMoney/100.0).round * 100 # Round to nearest one hundred
	return totalMoney
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