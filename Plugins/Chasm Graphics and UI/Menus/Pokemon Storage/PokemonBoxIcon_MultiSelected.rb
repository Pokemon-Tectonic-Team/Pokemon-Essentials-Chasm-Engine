class PokemonBoxIcon_MultiSelected < PokemonBoxIcon
  def initialize(pokemon, viewport = nil)
      @multiselected = false
      @multiSelectSprite = IconSprite.new(0, 0, viewport)
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
    @multiSelectSprite.x = value + 18
  end

  def y=(value)
    super
    @multiSelectSprite.y = value + 24
  end

  def z=(value)
    super
    @multiSelectSprite.z = value + 1
  end

  def opacity=(value)
    super
    @multiSelectSprite.opacity = value
  end

  def color=(value)
    super
    @multiSelectSprite.color = value
  end

  def tone=(value)
    super
    @multiSelectSprite.tone = value
  end

  def visible=(value)
    super
    @multiSelectSprite.visible = value && @multiselected
  end
end