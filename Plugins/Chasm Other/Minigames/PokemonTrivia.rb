TRIVIA_MAX_DIFFICULTY = 5

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

        update
        pbFadeInAndShow(@sprites)
    end

    def pbMain
        loop do
            Graphics.update
            Input.update
            update
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
        @scene.pbMain
        @scene.pbEndScene
    end

    def generatePokemonTriviaQuestions(difficulty)
        numberOfQuestions = [1,1,2,2,3][difficulty-1]

        # Higher difficulties have more trivia types
        possibleQuestionTypes = [:SILHOUETTE, :CRY, :SIGNATURE_ABILITY, :SIGNATURE_MOVE, :LEVEL_MOVES][0...difficulty]

        questions = []
        speciesUtilized = []
        numberOfQuestions.times do |i|
            questionType = possibleQuestionTypes.sample

            speciesDifficulty = difficulty + [-1,0,0,1].sample
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
        end
        return questions
    end
end

def generatePokemonTriviaMetadata
    return if $PokemonTriviaMetadata
    $PokemonTriviaMetadata = []
    for score in 0..4
        $PokemonTriviaMetadata[score] = []
    end

    echoln("GENERATING POKEMON TRIVIA METADATA")
    GameData::Species.each do |species|
        # Do not include alt forms that aren't accessible via the Universal Formalizer
        next if species.form != 0 && !species.formalizer.include?(species.form)
        
        speciesDifficulty = 0

        # Legendary pokemon are more difficult
        speciesDifficulty += 1 if species.isLegendary?

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
			setMySwitch('A') if victorious
        end
    end
end
