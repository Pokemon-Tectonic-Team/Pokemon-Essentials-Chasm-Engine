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
        addBackgroundPlane(@sprites, "bg", addLanguageSuffix("Pokegear/bg"), @viewport)

        @triviaQuestions = triviaQuestions
        @questionIndex = 0

        update
        pbFadeInAndShow(@sprites)
    end

    def pbMain
        loop do
            Graphics.update
            Input.update
            update

            result = presentNextQuestion

            return false if !result

            break if @questionIndex >= @triviaQuestions.length
        end

        return true
    end

    def presentNextQuestion
        nextQuestion = @triviaQuestions[@questionIndex]
        nextQuestionType, nextQuestionSpecies = nextQuestion
        case nextQuestionType
        when :SILHOUETTE
            presentSilhoetteQuestion(nextQuestionSpecies)
        when :CRY
            presentCryQuestion(nextQuestionSpecies)
        when :SIGNATURE_ABILITY
            presentSignatureAbilityQuestion(nextQuestionSpecies)
        when :SIGNATURE_MOVE
            presentSignatureMoveQuestion(nextQuestionSpecies)
        when :LEVEL_MOVES
            presentLevelMovesQuestion(nextQuestionSpecies)
        end
        result = checkAnswer(nextQuestionSpecies)
        @questionIndex += 1
        return result
    end

    def presentSilhoetteQuestion(questionSpecies)
        pbMessage(_INTL("Which Pokemon species has this silhoette?"))
    end

    def presentCryQuestion(questionSpecies)
        pbMessage(_INTL("The following cry belongs to which Pokemon species?"))
    end

    def presentSignatureAbilityQuestion(questionSpecies)
        pbMessage(_INTL("This Signature Ability belongs to which Pokemon species?"))
    end

    def presentSignatureMoveQuestion(questionSpecies)
        pbMessage(_INTL("This Signature Move belongs to which Pokemon species?"))
    end

    def presentSignatureMoveQuestion(questionSpecies)
        pbMessage(_INTL("Which Pokemon species has these moves on its level up learnset, in this order?"))
    end

    def checkAnswer(questionSpecies)
        matchingSpecies = nil

        loop do
            inputText = pbEnterText(_INTL("Enter species name"),0,20).downcase

            if inputText.length <= 2
                pbMessage(_INTL("Invalid input."))
                next
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
            pbMessage(_INTL("Correct! The answer was {1}!", answerName))
            return true
        else  
            pbMessage(_INTL("Incorrect... the correct answer was {1}.", answerName))
            return false
        end
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites)
        pbDisposeSpriteHash(@sprites)
        @viewport.dispose
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
        possibleQuestionTypes = [:SILHOUETTE, :CRY, :SIGNATURE_ABILITY, :SIGNATURE_MOVE, :LEVEL_MOVES][0...difficulty]

        questions = []
        speciesUtilized = []
        numberOfQuestions.times do |i|
            questionType = possibleQuestionTypes.sample

            speciesDifficulty = difficulty + [-1,0,0,0,1].sample
            speciesDifficulty = speciesDifficulty.clamp(1,TRIVIA_MAX_DIFFICULTY)

            # Choose a random pokemon at the select species difficulty
            # but re-generate if it's already been picked for this set of trivia questions
            # but give up if you re-roll the same mon 3 times (infinite loop avoidance)
            attempts = 0
            speciesForQuestion = :PIKACHU
            loop do
                attempts += 1
                speciesForQuestion = $PokemonTriviaMetadata[speciesDifficulty-1].sample
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
    if getMySwitch("A")
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
