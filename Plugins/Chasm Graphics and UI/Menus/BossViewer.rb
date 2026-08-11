class BossViewer_Scene
    POKEMON_ICON_SIZE = 64
    base   = Color.new(80, 80, 88)
    shadow = Color.new(160, 160, 168)

    def initialize(bossSpecies, bossVersion: 0)
        @bossSpecies = bossSpecies
        @boss = GameData::Avatar.get(bossSpecies, bossVersion)
        @phase = 0

        @sprites = {}
        @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
        @viewport.z = 99999

        backgroundFileName = "Boss viewer/boss_viewer_bg"
        addBackgroundPlane(@sprites, "bg", backgroundFileName, @viewport)

        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @overlay = @sprites["overlay"].bitmap
        pbSetSmallFont(@overlay)

        @sprites["overlay2"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["overlay2"].z = 99999
        @overlay2 = @sprites["overlay2"].bitmap
        pbSetSmallFont(@overlay2)

        renderBossInfo(@phase)

        pbFadeInAndShow(@sprites) { pbUpdate }

        loop do
            Graphics.update
            Input.update
            pbUpdate
            if Input.trigger?(Input::BACK)
                pbEndScene
                pbPlayCloseMenuSE
                return
            end
        end
    end

    MAX_MOVE_NAME_WIDTH = 140

    def renderBossInfo(phase = 0)
        base = MessageConfig::DARK_TEXT_MAIN_COLOR
        shadow = MessageConfig::DARK_TEXT_SHADOW_COLOR
        speciesName = GameData::Species.get(@bossSpecies).name
        topRowY = 16
        drawFormattedTextEx(@overlay, 38, topRowY, Graphics.width, speciesName, base, shadow)

        drawFormattedTextEx(@overlay, 294, topRowY, Graphics.width, _INTL("Phase {1}",@phase+1), base, shadow)
    end

    # End the scene here
    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        # DISPOSE OF BITMAPS HERE #
    end

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end
end

def bossViewer(bossSpecies, bossVersion: 0)
    if bossSpecies.is_a?(PokeBattle_Battler)
        bossVersion = bossSpecies.pokemon.bossVersion
        bossSpecies = bossSpecies.species
    end
    pbFadeOutIn {
        BossViewer_Scene.new(bossSpecies, bossVersion: bossVersion)
    }
end