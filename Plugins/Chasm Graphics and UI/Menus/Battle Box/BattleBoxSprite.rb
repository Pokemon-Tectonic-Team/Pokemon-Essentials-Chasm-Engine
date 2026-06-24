#===============================================================================
# Box
#===============================================================================
class BattleBoxSprite < SpriteWrapper
    attr_accessor :refreshSprites
    attr_accessor :focus
    attr_accessor :offsetIndex
    attr_accessor :selectedToMove

    def initialize(battlebox, viewport)
        super(viewport)
        @battlebox = battlebox
        @refreshSprites = true
        @focus = 0
        @offsetIndex = 0
        @selectedToMove = -1
        @pokemonsprites = []
        @teamtribedescs = []
        @teamlegendnumbers = []
        
        for i in 0...@battlebox.teamNumber
            for j in 0...@battlebox.teams[i].size
                @pokemonsprites[i*6+j] = nil
                pokemon = @battlebox.teams[i][j]
                @pokemonsprites[i*6+j] = PokemonBoxIcon.new(pokemon, viewport)
            end
        end
        @contents = BitmapWrapper.new(Graphics.width, Graphics.height)
        @slotbitmap = Bitmap.new("Graphics/Pictures/Battle Box/teamslot")
        @focusslotbitmap = Bitmap.new("Graphics/Pictures/Battle Box/teamslot_focus")
        @moveslotbitmap = Bitmap.new("Graphics/Pictures/Battle Box/teamslot_move")
        @headerbitmap = Bitmap.new("Graphics/Pictures/Battle Box/header")
        self.bitmap = @contents
        self.x = 0
        self.y = 0
        update
        refresh
    end

    def dispose
        unless disposed?
            for i in 0...@battlebox.teamNumber
                for j in 0...@battlebox.teams[i].size
                    @pokemonsprites[i*6+j].dispose if @pokemonsprites[i*6+j]
                    @pokemonsprites[i*6+j] = nil
                end
            end
            @contents.dispose
            super
        end
    end

    def x=(value)
        super
        refresh
    end

    def y=(value)
        super
        refresh
    end

    def color=(value)
        super
        if @refreshSprites
            for i in 0...@battlebox.teamNumber
                for j in 0...@battlebox.teams[i].size
                    @pokemonsprites[i*6+j].color = value if @pokemonsprites[i*6+j] && !@pokemonsprites[i*6+j].disposed?
                end
            end
        end
        refresh
    end

    def visible=(value)
        super
        for i in 0...@battlebox.teamNumber
            for j in 0...@battlebox.teams[i].size
                @pokemonsprites[i*6+j].visible = value if @pokemonsprites[i*6+j] && !@pokemonsprites[i*6+j].disposed?
            end
        end
        refresh
    end

    def refresh
        @contents.clear
        @contents.blt(8, self.y+6, @headerbitmap, Rect.new(0, 0, Graphics.width - 16, 32))
        pbSetSystemFont(@contents)
        titlewidthval = @contents.text_size(@battlebox.boxname).width
        pbDrawShadowText(@contents, (Graphics.width - titlewidthval)/2, 4, titlewidthval, 16, @battlebox.boxname, Color.new(248, 248, 248), Color.new(40, 48, 48))
        @pokemonsprites.each { |sprite| sprite.visible = false if sprite && !sprite.disposed?}
        yval = self.y + 32
        for j in 0...[@battlebox.teamNumber+1, 3].min

            teamIndex = j + @offsetIndex

            sprite = nil
            if teamIndex == @selectedToMove
                sprite = @moveslotbitmap
            else
                sprite = (@focus == teamIndex) ? @focusslotbitmap : @slotbitmap
            end

            @contents.blt(8, yval+8, sprite, Rect.new(0, 0, 496, 120))

            teamname = @battlebox.getTeamName(teamIndex)
            pbSetSystemFont(@contents)
            if teamname
                widthval = @contents.text_size(teamname).width
                pbDrawShadowText(@contents, 24, yval+16, widthval, 20, teamname, Color.new(248, 248, 248), Color.new(40, 48, 48))
            end



            xval = self.x
            pbSetSmallFont(@contents)
            pbDrawImagePositions(@contents, [
                ["Graphics/Pictures/icon_tribal_bonus", xval+320, yval+12],
                ["Graphics/Pictures/Battle Box/arc-rings", xval+320, yval+36]
            ])
            drawFormattedTextEx(@contents, xval+344, yval+12, 196, @teamtribedescs[teamIndex] || "Error", Color.new(248, 248, 248), Color.new(40, 48, 48))
            legends_text = (@teamlegendnumbers[teamIndex] == 0 ? "No" : (@teamlegendnumbers[teamIndex] || "Error").to_s) + " legendaries"
            drawFormattedTextEx(@contents, xval+344, yval+36, 196, legends_text, Color.new(248, 248, 248), Color.new(40, 48, 48))

            for k in 0...6
                arrayIndex = teamIndex * 6 + k
                sprite = @pokemonsprites[arrayIndex]
                if sprite && !sprite.disposed?
                    sprite.viewport = viewport
                    sprite.x = xval + 36
                    sprite.y = yval + 54
                    sprite.z = 0
                    sprite.visible = true
                end
                xval += 72
            end
            yval += 114
        end
    end

    def update
        super
        for i in 0...@battlebox.teamNumber
            dummy_trainer = @battlebox.getTrainer(i)
            dummy_trainer.tribalBonus.updateTribeCount
            bonusesList = dummy_trainer.tribalBonus.getActiveBonusesList(false)
            tribesTotal = GameData::Tribe.legal_tribes_count
            fullDescription = ""
            if bonusesList.empty?
                fullDescription = _INTL("None")
            elsif bonusesList.length == tribesTotal
                fullDescription = _INTL("All")
            elsif bonusesList.length <= 2
                bonusesList.each_with_index do |label,index|
                    fullDescription += "," unless index == 0
                    fullDescription += label
                end
            else
                fullDescription = bonusesList.length.to_s
            end
            @teamtribedescs[i] = fullDescription

            legends_count = 0
            dummy_trainer.party.each do |pkmn|
                legends_count += 1 if GameData::Species.get(pkmn.species).isLegendary?
            end
            @teamlegendnumbers[i] = legends_count

            for j in 0...@battlebox.teams[i].size
                @pokemonsprites[i*6+j].update if @pokemonsprites[i*6+j] && !@pokemonsprites[i*6+j].disposed?
            end
        end
    end
end
