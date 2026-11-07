class Spriteset_Global
    attr_reader :playersprite
    attr_reader :portraits

    PICTURE_VIEWPORT = Viewport.new(0, 0, Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT)
    PICTURE_VIEWPORT.z = 200

    def initialize
        @playersprite = Sprite_Character.new(Spriteset_Map.viewport, $game_player)
        @picture_sprites = []
        (1..100).each do |i|
            @picture_sprites.push(Sprite_Picture.new(PICTURE_VIEWPORT, $game_screen.pictures[i]))
        end
        @timer_sprite = Sprite_Timer.new
        @portraits = DialoguePortraitSet.new
        update
    end

    def dispose
        @playersprite.dispose
        @picture_sprites.each(&:dispose)
        @timer_sprite.dispose
        @portraits.dispose
        @playersprite = nil
        @picture_sprites.clear
        @timer_sprite = nil
    end

    def update
        @playersprite.update
        @picture_sprites.each(&:update)
        @timer_sprite.update
        @portraits.update(pbMapInterpreterRunning? || $game_temp.message_window_showing)
    end
end
