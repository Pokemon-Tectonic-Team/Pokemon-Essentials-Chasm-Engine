TRIVIA_MAX_DIFFICULTY = 5
TRIVIA_CANDY_LEVELS_BY_DIFFICULTY = [10,25,40,55,70]
TRIVIA_NUMBER_QUESTIONS_BY_DIFFICULTY = [1,1,2,2,3]
TRIVIA_CANDY_MULTIPLIER = 4
TRIVIA_QUESTION_TYPES = [:SILHOUETTE, :CHARACTERISTICS, :SIGNATURE_ABILITY, :SIGNATURE_MOVE, :LEVEL_MOVES]
TRIVIA_LEVEL_MOVES_AMOUNT = 4 # How many level moves to show for that type of trivia question

class PokemonTriviaScene

    def update
        pbUpdateSpriteHash(@sprites)
    end

    def pbStartScene(difficulty, triviaQuestions)
        @sprites = {}
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        addBackgroundPlane(@sprites, "bg", addLanguageSuffix("Trivia/triviabg"), @viewport)

        @sprites["species_silhoette"] = PokemonSprite.new(@viewport)
        @sprites["species_silhoette"].setOffset(PictureOrigin::Center)
        @sprites["species_silhoette"].x = Graphics.width / 2
        @sprites["species_silhoette"].y = Graphics.height / 2
        @sprites["species_silhoette"].tone = Tone.new(-255,-255,-255)

        questionSectionHeight = 86
        @sprites["question_text"] = BitmapSprite.new(Graphics.width, questionSectionHeight, @viewport)
        @questionTextOverlay = @sprites["question_text"].bitmap
        pbSetSystemFont(@questionTextOverlay)

        @sprites["clues"] = BitmapSprite.new(Graphics.width, Graphics.height - questionSectionHeight, @viewport)
        @sprites["clues"].y = questionSectionHeight
        @clueOverlay = @sprites["clues"].bitmap
        pbSetSystemFont(@clueOverlay)

        # Create overlay for move info (shows move's BP, description)
        moveInfoDisplayFileName = addLanguageSuffix(("Graphics/Pictures/move_info_display_3x3"))
        moveInfoDisplayFileName += "_dark" if darkMode?
        @moveInfoDisplayBitmap  = AnimatedBitmap.new(moveInfoDisplayFileName)
        moveInfoDisplay = SpriteWrapper.new(@viewport)
        moveInfoDisplay.bitmap = @moveInfoDisplayBitmap.bitmap
        moveInfoDisplay.x      = 0
        moveInfoDisplay.y      = Graphics.height - @moveInfoDisplayBitmap.height
        @sprites["move_info_display"] = moveInfoDisplay
        # Create overlay for selected move's extra info (shows move's BP, description)
        moveInfoSprite = BitmapSprite.new(Graphics.width, @moveInfoDisplayBitmap.height, @viewport)
        moveInfoSprite.y = moveInfoDisplay.y
        pbSetNarrowFont(moveInfoSprite.bitmap)
        @sprites["move_info_overlay"] = moveInfoSprite
        @moveInfoOverlay = moveInfoSprite.bitmap

        @typebitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Pokedex/icon_types")))

        @triviaQuestions = triviaQuestions
        @difficulty = difficulty

        wipeQuestionGraphics

        pbMessage(_INTL("Welcome to Pokemon Trivia, tier {1}!",@difficulty))
        pbMessage(_INTL("Answer {1} questions correctly to earn a prize!",@triviaQuestions.length))
    end

    def pbMain
        nextQuestionType = nil
        nextQuestionSpecies = nil

        visibleSprites = nil
        @triviaQuestions.each_with_index do |nextQuestion, index|
            pbMessage(_INTL("Question {1}...", index + 1))

            nextQuestionType, nextQuestionSpecies = nextQuestion
            presentQuestion(nextQuestionType, nextQuestionSpecies)

            pbFadeInAndShow(@sprites, visibleSprites)

            loop do
                Graphics.update
                Input.update
                update

                if Input.trigger?(Input::USE)
                    pbPlayDecisionSE
                    result = checkAnswer(nextQuestionType, nextQuestionSpecies)
                    next if result.nil?
                    return false unless result
                    break
                end
            end

            wipeQuestionGraphics
            visibleSprites = pbFadeOutAndHide(@sprites)
        end

        return true
    end

    def wipeQuestionGraphics
        @clueOverlay.clear
        @moveInfoOverlay.clear
        @sprites["species_silhoette"].visible = false
        @sprites["move_info_display"].visible = false
    end

    def presentQuestion(nextQuestionType, nextQuestionSpecies)
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
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        @questionTextOverlay.clear
        sideBuffer = 24
        drawTextEx(@questionTextOverlay, sideBuffer, 8, Graphics.width - sideBuffer * 2, 2, text, base, shadow)
    end

    def presentSilhoetteQuestion(questionSpecies)
        @sprites["bg"].setBitmap("Graphics/Pictures/Trivia/triviabg_silhoette")
        @sprites["species_silhoette"].tone = Tone.new(-255,-255,-255)
        @sprites["species_silhoette"].visible = true
        @sprites["species_silhoette"].setSpeciesBitmap(questionSpecies)
        setQuestionText(_INTL("Which species has this silhoette?"))
    end

    def presentCharacteristicsQuestion(questionSpecies)
        @sprites["bg"].setBitmap("Graphics/Pictures/Trivia/triviabg_characteristics")
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
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
        drawTextEx(@clueOverlay, clueX+32, 166, 240, 3, tribesDescription, base, shadow)
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

    SIGNATURE_COLOR = Color.new(211, 175, 44)
    SIGNATURE_COLOR_LIGHTER = Color.new(228, 207, 128)

    def presentSignatureAbilityQuestion(questionSpecies)
        @sprites["bg"].setBitmap("Graphics/Pictures/Trivia/triviabg_ability")
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        species_data = GameData::Species.get(questionSpecies)

        abilityTextX = 30
        abilityTextY = 54

        chosenAbility = species_data.signature_abilities.sample
        chosenAbilityData = GameData::Ability.get(chosenAbility)
        abilityNameText = "<outln2>" + chosenAbilityData.name + "</outln2>"
        drawFormattedTextEx(@clueOverlay, abilityTextX, abilityTextY, 450, abilityNameText, SIGNATURE_COLOR_LIGHTER, darkMode? ? shadow : base)

        abilityDescription = addBattleKeywordHighlighting(chosenAbilityData.description, isAbility: true)
        drawFormattedTextEx(@clueOverlay, abilityTextX, abilityTextY + 34, 450, abilityDescription, base, shadow)
    
        setQuestionText(_INTL("This Signature Ability belongs to which fully evolved species?"))
    end

    def presentSignatureMoveQuestion(questionSpecies)
        @sprites["bg"].setBitmap("Graphics/Pictures/Trivia/triviabg_move")
                base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor

        signatureMove = GameData::Species.get(questionSpecies).signature_moves.sample
        signatureMoveData = GameData::Move.get(signatureMove)

        moveTextX = 30
        moveTextY = 54

        moveNameText = "<outln2>" + signatureMoveData.name + "</outln2>"
        drawFormattedTextEx(@clueOverlay, moveTextX, moveTextY, 600, moveNameText, SIGNATURE_COLOR_LIGHTER, darkMode? ? shadow : base)
        writeMoveInfoToInfoOverlay3x3(@moveInfoOverlay, signatureMove)
        @sprites["move_info_display"].visible = true

        setQuestionText(_INTL("This Signature Move belongs to which fully evolved species?"))
    end

    def presentLevelMovesQuestion(questionSpecies)
        setQuestionText(_INTL("Which fully evolved species learns these moves at these levels?"))
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
        @moveInfoDisplayBitmap.dispose
    end
end

class PokemonTrivia
    def initialize(scene)
        @scene=scene
    end

    def pbStartScreen(difficulty)
        generatePokemonTriviaMetadata
        triviaQuestions = generatePokemonTriviaQuestions(difficulty)

        @scene.pbStartScene(difficulty,triviaQuestions)
        result = @scene.pbMain
        @scene.pbEndScene

        return result
    end

    def generatePokemonTriviaQuestions(difficulty)
        numberOfQuestions = TRIVIA_NUMBER_QUESTIONS_BY_DIFFICULTY[difficulty-1]

        # Higher difficulties have more trivia types
        possibleQuestionTypes = TRIVIA_QUESTION_TYPES[0...difficulty]

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
                speciesForQuestion = $PokemonTriviaMetadata[questionType][difficulty-1].sample
                break if !speciesUtilized.include?(speciesForQuestion) || attempts > 3
            end

            speciesUtilized.push(speciesForQuestion)

            questions.push([questionType,speciesForQuestion])

            echoln("#{questionType}, #{speciesForQuestion}")
        end
        return questions
    end
end

# PokemonTriviaMetadata is created as a hash
# With entries for each type of question, which are arrays covering all difficulty levels
# Those arrays contain a list of pokemon species IDs
# E.g. you could access $PokemonTriviaMetadata[:SILHOUETTE][0] to get an array of all of the
# easiest Pokemon that are eligible for Silhoette trivia question
def generatePokemonTriviaMetadata
    return if $PokemonTriviaMetadata
    $PokemonTriviaMetadata = {}

    TRIVIA_QUESTION_TYPES.each do |questionType|
        $PokemonTriviaMetadata[questionType] = []
        for score in 0...TRIVIA_MAX_DIFFICULTY
            $PokemonTriviaMetadata[questionType][score] = []
        end
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

        TRIVIA_QUESTION_TYPES.each do |questionType|
            hasEvolutions = !species.get_evolutions.empty?
            next if questionType == :SIGNATURE_MOVE && (species.signature_moves.empty? || hasEvolutions)
            next if questionType == :SIGNATURE_ABILITY && (species.signature_abilities.empty? || hasEvolutions)
            next if questionType == :LEVEL_MOVES && (species.moves.length < TRIVIA_LEVEL_MOVES_AMOUNT || hasEvolutions)
            # Push to all difficulties at or above the determined species difficulty
            for difficultyToPush in speciesDifficulty...TRIVIA_MAX_DIFFICULTY
                  $PokemonTriviaMetadata[questionType][difficultyToPush].push(species.id)
            end
        end

        echoln("#{species.name}: #{speciesDifficulty}")
    end
end

def triviaMachine(difficulty = 1)
    return unless playerFacingNorth? # Player has to be facing the screen
    victorious = false
    pbFadeOutIn do
        scene = PokemonTriviaScene.new
        screen = PokemonTrivia.new(scene)
        victorious = screen.pbStartScreen(difficulty)
    end
    if victorious
        pbMessage(_INTL("Congratulations! You've earned a prize!"))
        pbMEPlay("Slots win")
        candyLevel = TRIVIA_CANDY_LEVELS_BY_DIFFICULTY[difficulty-1]
        receiveCandyBatch(candyLevel,TRIVIA_CANDY_MULTIPLIER)
        setMySwitch('A')
    else
        pbMessage(_INTL("Better luck next time..."))
    end
end
