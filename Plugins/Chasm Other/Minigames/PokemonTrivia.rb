TRIVIA_MAX_DIFFICULTY = 5
TRIVIA_CANDY_LEVELS_BY_DIFFICULTY = [10,25,40,55,70]
TRIVIA_CANDY_MULTIPLIER = 4

class PokemonTriviaScene
    def update
        pbUpdateSpriteHash(@sprites)
    end

    def pbStartScene(triviaQuestions)
        @sprites = {}
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        addBackgroundPlane(@sprites, "bg", addLanguageSuffix("Trivia/triviabg"), @viewport)

        @sprites["species_silhoette"] = PokemonSprite.new(@viewport)
        @sprites["species_silhoette"].setOffset(PictureOrigin::Center)
        @sprites["species_silhoette"].x = Graphics.width / 2
        @sprites["species_silhoette"].y = Graphics.height / 2
        @sprites["species_silhoette"].tone = Tone.new(-255,-255,-255)

        questionSectionHeight = 64
        @sprites["question_text"] = BitmapSprite.new(Graphics.width, questionSectionHeight, @viewport)
        @questionTextOverlay = @sprites["question_text"].bitmap
        pbSetSystemFont(@questionTextOverlay)

        @sprites["clues"] = BitmapSprite.new(Graphics.width, Graphics.height - questionSectionHeight, @viewport)
        @sprites["clues"].y = questionSectionHeight
        @clueOverlay = @sprites["clues"].bitmap
        pbSetSystemFont(@clueOverlay)

        @typebitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Pokedex/icon_types")))

        @triviaQuestions = triviaQuestions
        @questionIndex = 0

        update
        pbFadeInAndShow(@sprites)
    end

    def pbMain
        nextQuestionType = nil
        nextQuestionSpecies = nil

        gameVictory = true

        @triviaQuestions.each do |nextQuestion|
            nextQuestionType, nextQuestionSpecies = nextQuestion
            presentQuestion(nextQuestionType, nextQuestionSpecies)

            pbWait(20)

            loop do
                Graphics.update
                Input.update
                update

                if Input.trigger?(Input::USE)
                    result = checkAnswer(nextQuestionType, nextQuestionSpecies)
                    next if result.nil?
                    return false unless result
                    break
                end
            end

            break if gameVictory
        end

        return gameVictory
    end

    def presentQuestion(nextQuestionType, nextQuestionSpecies)
        @clueOverlay.clear

        case nextQuestionType
        when :SILHOUETTE
            presentSilhoetteQuestion(nextQuestionSpecies)
        when :CHARACTERISTICS
            presentCharacteristicsQuestion(nextQuestionSpecies)
        when :SIGNATURE_ABILITY
            presentSignatureAbilityQuestion(nextQuestionSpecies)
        when :SIGNATURE_MOVE
            presentSignatureMoveQuestion(nextQuestionSpecies)
        when :LEVEL_MOVES
            presentLevelMovesQuestion(nextQuestionSpecies)
        end
    end

    def setQuestionText(text)
        base = MessageConfig::LIGHT_TEXT_MAIN_COLOR
        shadow = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
        @questionTextOverlay.clear
        drawFormattedTextEx(@questionTextOverlay,16,24,Graphics.width,text,base,shadow)
    end

    def presentSilhoetteQuestion(questionSpecies)
        @sprites["bg"].setBitmap("Graphics/Pictures/Trivia/triviabg_silhoette")
        @sprites["species_silhoette"].setSpeciesBitmap(questionSpecies)
        setQuestionText(_INTL("Which species has this silhoette?"))
    end

    def presentCharacteristicsQuestion(questionSpecies)
        @sprites["bg"].setBitmap("Graphics/Pictures/Trivia/triviabg_characteristics")
        base = MessageConfig::LIGHT_TEXT_MAIN_COLOR
        shadow = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
        species_data = GameData::Species.get(questionSpecies)

        clueX = 20

        # Write the category
        drawTextEx(@clueOverlay, clueX, 68, 300, 1, _INTL("{1} Pokémon", species_data.category), base, shadow)

        # Draw the type icon(s)
        type1 = species_data.type1
        type2 = species_data.type2
        type1_number = GameData::Type.get(type1).id_number
        type2_number = GameData::Type.get(type2).id_number
        type1rect = Rect.new(0, type1_number * 32, 96, 32)
        type2rect = Rect.new(0, type2_number * 32, 96, 32)
        @clueOverlay.blt(clueX, 120, @typebitmap.bitmap, type1rect)
        @clueOverlay.blt(clueX + 100, 120, @typebitmap.bitmap, type2rect) if type1 != type2

        # Write the tribes
        if species_data.tribes.length == 0
            tribesDescription = _INTL("None")
        else
            tribes = []
            species_data.tribes.each do |tribe|
                tribes.push(getTribeName(tribe))
            end
            tribesDescription = tribes.join(", ")
        end
        drawTextEx(@clueOverlay, clueX+32, 166, 224, 2, tribesDescription, base, shadow)
        pbDrawImagePositions(@clueOverlay,[["Graphics/Pictures/icon_tribal_bonus",clueX,166+12]])

        # Write the stats
        baseStatHash = species_data.base_stats
        baseStats = []
        total = 0
        baseStatHash.each_with_index do |stat, index|
            next unless stat
            statValue = stat[1]
            total += statValue
            baseStats.push(statValue)
        end
        baseStatsX = 316
        baseStatsY = 28
        baseStatNames = [_INTL("HP"), _INTL("Attack"), _INTL("Defense"),  _INTL("Sp. Atk"), _INTL("Sp. Def"), _INTL("Speed")]
        baseStats.each_with_index do |statValue, index|
            # Draw stat line
            drawTextEx(@clueOverlay, baseStatsX, baseStatsY + 32 * index, 450, 1, baseStatNames[index], base, shadow)
            drawTextEx(@clueOverlay, baseStatsX + 106, baseStatsY + 32 * index, 450, 1, statValue.to_s, base, shadow)
        end
        drawTextEx(@clueOverlay, baseStatsX, baseStatsY + 32 * 6 + 16, 450, 1, _INTL("Total"), base, shadow)
        drawTextEx(@clueOverlay, baseStatsX + 106, baseStatsY + 32 * 6 + 16, 450, 1, total.to_s, base, shadow)

        setQuestionText(_INTL("Which species has these attributes?"))
    end

    def presentSignatureAbilityQuestion(questionSpecies)
        setQuestionText(_INTL("This Signature Ability belongs to which species?"))
    end

    def presentSignatureMoveQuestion(questionSpecies)
        setQuestionText(_INTL("This Signature Move belongs to which species?"))
    end

    def presentSignatureMoveQuestion(questionSpecies)
        setQuestionText(_INTL("Which species learns these moves at these levels?"))
    end

    def checkAnswer(questionType, questionSpecies)
        matchingSpecies = nil

        loop do
            inputText = pbEnterText(_INTL("Enter species name."),0,20).downcase

            # Return player to question
            if inputText.length == 0
                return nil
            end

            # Look for exact matches
            GameData::Species.each do |species|
                if species.name.downcase.eql?(inputText)
                    matchingSpecies = species.id
                    break
                end
            end

            # Look for partial matches
            if matchingSpecies.nil?
                GameData::Species.each do |species|
                    if species.name.downcase.include?(inputText)
                        matchingSpecies = species.id if pbConfirmMessage(_INTL("Did you mean {1}?",species.name))
                        break
                    end
                end
            end

            if matchingSpecies.nil?
                pbMessage(_INTL("Input didn't match any Pokemon species."))
                next
            end
            break
        end

        answerName = GameData::Species.get(questionSpecies).name
        if matchingSpecies == questionSpecies
            pbWait(5)
            @sprites["species_silhoette"].tone = Tone.new(0,0,0,0) if questionType            
            pbWait(5)
            pbMessage(_INTL("Correct! The answer was <imp>{1}</imp>!", answerName))
            return true
        else  
            pbMessage(_INTL("Incorrect... the correct answer was <imp>{1}</imp>.", answerName))
            return false
        end
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites)
        pbDisposeSpriteHash(@sprites)
        @viewport.dispose
        @typebitmap.dispose
    end
end

class PokemonTrivia
    def initialize(scene)
        @scene=scene
    end

    def pbStartScreen(difficulty)
        generatePokemonTriviaMetadata
        triviaQuestions = generatePokemonTriviaQuestions(difficulty)

        @scene.pbStartScene(triviaQuestions)
        result = @scene.pbMain
        @scene.pbEndScene

        return result
    end

    def generatePokemonTriviaQuestions(difficulty)
        numberOfQuestions = [1,1,2,2,3][difficulty-1]

        # Higher difficulties have more trivia types
        possibleQuestionTypes = [:SILHOUETTE, :CHARACTERISTICS, :SIGNATURE_ABILITY, :SIGNATURE_MOVE, :LEVEL_MOVES][0...difficulty]

        questions = []
        speciesUtilized = []
        numberOfQuestions.times do |i|
            questionType = possibleQuestionTypes.sample

            # Choose a random pokemon at the select species difficulty
            # but re-generate if it's already been picked for this set of trivia questions
            # but give up if you re-roll the same mon 3 times (infinite loop avoidance)
            attempts = 0
            speciesForQuestion = :PIKACHU
            loop do
                attempts += 1
                speciesForQuestion = $PokemonTriviaMetadata[difficulty-1].sample
                break if !speciesUtilized.include?(speciesForQuestion) || attempts > 3
            end

            speciesUtilized.push(speciesForQuestion)

            questions.push([questionType,speciesForQuestion])

            echoln("#{questionType}, #{speciesForQuestion}")
        end
        return questions
    end
end

def generatePokemonTriviaMetadata
    return if $PokemonTriviaMetadata
    $PokemonTriviaMetadata = []
    for score in 0...TRIVIA_MAX_DIFFICULTY
        $PokemonTriviaMetadata[score] = []
    end

    echoln("GENERATING POKEMON TRIVIA METADATA")
    GameData::Species.each do |species|
        # Do not include alt forms that aren't accessible via the Universal Formalizer
        next if species.form != 0 && !species.formalizer.include?(species.form)
        
        speciesDifficulty = 0

        # Legendary pokemon are more difficult
        speciesDifficulty += 1 if species.isLegendary?

        # Non-starter pokemon are more difficult
        speciesDifficulty += 1 unless species.isStarter?

        # Lower stage pokemon are more difficult
        if species.get_evolutions.length != 0
            speciesDifficulty += 1

            # Mid evos are even more difficult
            if species.get_prevolutions.length != 0
                speciesDifficulty += 1  
            end
        end

        # Pokemon introduced in the Chasm Engine are more difficult
        speciesDifficulty += 1 if species.generation == 0

        $PokemonTriviaMetadata[speciesDifficulty].push(species.id)

        echoln("#{species.name}: #{speciesDifficulty}")
    end
end

def triviaMachine(difficulty = 1)
    if getMySwitch("A") && false # TO DO: Remove this line
        pbMessage(_INTL("Thank you for playing Pokemon Trivia!"))
    else
        pbFadeOutIn do
            scene = PokemonTriviaScene.new
            screen = PokemonTrivia.new(scene)
            victorious = screen.pbStartScreen(difficulty)
            if victorious
                candyLevel = TRIVIA_CANDY_LEVELS_BY_DIFFICULTY[difficulty-1]
                receiveCandyBatch(candyLevel,TRIVIA_CANDY_MULTIPLIER)
                setMySwitch('A')
            else
                pbMessage(_INTL("Feel free to try again!"))
            end
        end
    end
end
