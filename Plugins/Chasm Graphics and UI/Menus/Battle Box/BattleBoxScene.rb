#===============================================================================
# Battle Box visuals
#===============================================================================
class BattleBoxScene

    attr_accessor :selectionOffset
    attr_accessor :currentBoxIndex
    attr_accessor :selectedToMove

    def pbStartBox(screen)
        @screen = screen
        @storage = screen.storage
        @bgviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @bgviewport.z = 99_999
        @boxviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @boxviewport.z = 99_999
        @currentBoxIndex = screen.currentBoxIndex
        @selectedToMove = screen.selectedToMove
        @selection = 0
        @selectionOffset = 0
        @sprites = {}
        addBackgroundPlane(@sprites, "background", "Battle Box/bg", @bgviewport)
        @sprites["box"] = BattleBoxSprite.new(self.currentBox, @boxviewport)
        @sprites["scroll_bar"] = IconSprite.new(0, 0, @boxviewport)
        @sprites["scroll_bar"].setBitmap("Graphics/Pictures/scroll_bar")
        @sprites["scroll_bar"].x = Graphics.width - 16
        @sprites["scroll_bar"].y = 48
        @sprites["scroll_bar"].z = 1
        @sprites["scroll_bar"].visible = true
        pbSEPlay("PC access")
        pbFadeInAndShow(@sprites)
    end

    def currentBox
        return @storage[@currentBoxIndex]
    end

    def pbCloseBox
        pbFadeOutAndHide(@sprites)
        pbDisposeSpriteHash(@sprites)
        @boxviewport.dispose
    end

    def pbDisplay(message)
        msgwindow = Window_UnformattedTextPokemon.newWithSize("", 180, 0, Graphics.width - 180, 32)
        msgwindow.z       = @boxviewport.z + 1
        msgwindow.visible        = true
        msgwindow.letterbyletter = false
        msgwindow.resizeHeightToFit(message, Graphics.width - 180)
        msgwindow.text = message
        pbBottomRight(msgwindow)
        loop do
            Graphics.update
            Input.update
            break if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
            msgwindow.update
            update
        end
        msgwindow.dispose
        Input.update
    end

    def pbShowCommands(message, commands, index = 0)
        ret = -1
        msgwindow = Window_UnformattedTextPokemon.newWithSize("", 180, 0, Graphics.width - 180, 32)
        msgwindow.z = @boxviewport.z+1
        msgwindow.visible        = true
        msgwindow.letterbyletter = false
        msgwindow.text           = message
        msgwindow.resizeHeightToFit(message, Graphics.width - 180)
        pbBottomRight(msgwindow)
        cmdwindow = Window_CommandPokemon.new(commands)
        cmdwindow.z = @boxviewport.z+1
        cmdwindow.visible  = true
        cmdwindow.resizeToFit(cmdwindow.commands)
        cmdwindow.height = Graphics.height - msgwindow.height if cmdwindow.height > Graphics.height - msgwindow.height
        pbBottomRight(cmdwindow)
        cmdwindow.y -= msgwindow.height
        cmdwindow.index = index
        loop do
            Graphics.update
            Input.update
            msgwindow.update
            cmdwindow.update
            if Input.trigger?(Input::BACK)
                ret = -1
                break
            elsif Input.trigger?(Input::USE)
                ret = cmdwindow.index
                break
            end
            update
        end
        msgwindow.dispose
        cmdwindow.dispose
        Input.update
        return ret
    end

    def pbConfirm(str)
        return pbShowCommands(str, [_INTL("Yes"), _INTL("No")]) == 0
    end

    def pbChangeSelection(key, selection)
        ret = selection
        case key
        when Input::UP 
            if selection <= 0
                @selectionOffset = [self.currentBox.teamNumber - 2, 0].max
                ret = self.currentBox.teamNumber
            else
                ret = selection - 1
            end
            if ret - @selectionOffset < 0
                @selectionOffset = ret
            end
        when Input::DOWN
            if selection >= self.currentBox.teamNumber
                @selectionOffset = 0
                ret = 0
            else
                ret = selection + 1
            end
            if ret - @selectionOffset >= 3
                @selectionOffset = ret - 2
            end
        when Input::LEFT
            @currentBoxIndex -= 1
            @currentBoxIndex = @storage.boxNumber-1 if @currentBoxIndex < 0
            pbMoveBoxAndReset
            return 0
        when Input::RIGHT
            @currentBoxIndex += 1
            @currentBoxIndex = 0 if @currentBoxIndex >= @storage.boxNumber
            pbMoveBoxAndReset
            return 0
        end
        return ret
    end

    def pbSelectParty
        selection = @selection
        loop do
            Graphics.update
            Input.update
            key = -1
            key = Input::DOWN if Input.repeat?(Input::DOWN)
            key = Input::UP if Input.repeat?(Input::UP)
            key = Input::RIGHT if Input.repeat?(Input::RIGHT)
            key = Input::LEFT if Input.repeat?(Input::LEFT)

            if key >= 0
                pbPlayCursorSE
                selection = pbChangeSelection(key, selection)
                @sprites["box"].focus = selection
                @sprites["box"].offsetIndex = @selectionOffset
                @screen.currentBoxIndex = @currentBoxIndex
                pbRefresh
            end
            update
            if Input.trigger?(Input::BACK)
                @selection = selection
                return nil
            elsif Input.trigger?(Input::USE)
                @selection = selection
                return [self.currentBox[selection], selection]
            end
        end
    end

    def pbUpdateBox
        @sprites["box"].dispose
        @sprites["box"] = BattleBoxSprite.new(self.currentBox, @boxviewport)
        @sprites["box"].focus = @selection
        @sprites["box"].offsetIndex = @selectionOffset
        @sprites["box"].refresh
    end

    def pbMoveBoxAndReset
        @selection = 0
        @selectionOffset = 0
        @sprites["box"].dispose
        @sprites["box"] = BattleBoxSprite.new(self.currentBox, @boxviewport)
    end

    def pbRefresh
        @sprites["box"].selectedToMove = @selectedToMove
        @sprites["box"].refresh
        @sprites["scroll_bar"].y = 48 + (Graphics.height - 96) * (@selectionOffset / [(self.currentBox.teamNumber - 3), 1].max)
    end

    def pbHardRefresh
        oldFocus = @sprites["box"].focus
        @sprites["box"].dispose
        @sprites["box"] = BattleBoxSprite.new(self.currentBox, @boxviewport)
    end

    def update
        pbUpdateSpriteHash(@sprites)
    end

    
end