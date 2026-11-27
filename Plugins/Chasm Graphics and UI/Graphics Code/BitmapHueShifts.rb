def shiftBitmapHue(baseBitmap, hueShift)
    ret = baseBitmap.copy
    baseBitmap.dispose
    if ret.respond_to?("each")
        ret.each { |bitmap| bitmap.hue_change(hueShift) }
    else
        ret.hue_change(hueShift)
    end
    return ret
end

def shiftBitmapShade(baseBitmap, shadeShift)
    ret = baseBitmap.copy
    baseBitmap.dispose
    if ret.respond_to?("each")
        ret.each { |bitmap| shade_change(bitmap, shadeShift) }
    else
        shade_change(ret, shadeShift)
    end
    return ret
end

def shade_change(bitmap, shift)
    shiftMult = 1 + (shift / 255.0)
    contrastShift = (shift * (1.0 / 2.0)).abs
    contrastFactor = (259.0 * (contrastShift + 255.0)) / (255.0 * (259.0 - contrastShift))
    (0...bitmap.width).each do |x|
        (0...bitmap.height).each do |y|
            color = bitmap.get_pixel(x, y)
            next if color.alpha == 0
            # Increase brightness
            r = color.red * shiftMult
            g = color.green * shiftMult
            b = color.blue * shiftMult
            # Increase contrast
            r = ((contrastFactor * (r - 128)) + 128)
            g = ((contrastFactor * (g - 128)) + 128)
            b = ((contrastFactor * (b - 128)) + 128)
            color.red   = r.round.clamp(0, 255)
            color.green = g.round.clamp(0, 255)
            color.blue  = b.round.clamp(0, 255)
            bitmap.set_pixel(x, y, color)
        end
    end
end

def shiftPokemonBitmapHue(baseBitmap, pokemon)
    return shiftBitmapHue(baseBitmap, pokemon.hueShift)
end

def shiftPokemonBitmapShade(baseBitmap, pokemon)
    return shiftBitmapShade(baseBitmap, pokemon.shadeShift)
end

def shiftSpeciesBitmapHue(baseBitmap, species)
    species_data = GameData::Species.get(species)
    firstSpecies = species_data.get_line_start
    hueShift = hue_shift_from_id(firstSpecies.id_number)
    ret = baseBitmap.copy
    baseBitmap.dispose
    ret.each { |bitmap| bitmap.hue_change(hueShift) }
    return ret
end

def hue_shift_from_id(id)
    shift = ((((id << 16) ^ 1_000_000_000_063) >> 8) ^ 6_597_069_766_657) >> 8
    if id.even?
        shift = 30 + (shift % 60)
    else
        shift = 330 - (shift % 60)
    end
    return shift
end
