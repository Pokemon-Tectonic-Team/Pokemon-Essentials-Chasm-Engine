class PokemonBoxIcon_MultiSelected < PokemonBoxIcon
  def initialize(pokemon, viewport = nil)
      @multiselected = false
      @multiSelectSprite = IconSprite.new(0, 0, @viewport)
      plusPath = "Graphics/Pictures/Storage/multi_move_plus"
      @multiSelectSprite.setBitmap(plusPath)
      @multiSelectSprite.visible = false
      super
  end

  def multiselected=(value)
    @multiselected = value
    @multiSelectSprite.visible = value && @multiselected
  end

  def dispose
    super
    @multiSelectSprite.dispose
  end

  def x=(value)
    super
    @multiSelectSprite.x = value
  end

  def y=(value)
    super
    @multiSelectSprite.y = value
  end

  def z=(value)
    super
    @multiSelectSprite.z = value + 1
  end

  def opacity=(value)
    super
    @multiSelectSprite.opacity = value
  end

  def visible=(value)
    super
    @multiSelectSprite.visible = value && @multiselected
  end
end