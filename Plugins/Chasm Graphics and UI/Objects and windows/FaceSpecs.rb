# Face specs, as written in \ff and the dialogue portrait codes: "name" or
# "name,index", where index picks a frame of a sheet laid out four to a row.

# Splits a face spec "name" or "name,index" into [name, index]. Raises
# ArgumentError for a negative index, which names no frame.
def parseFaceSpec(face)
    name, index = face.split(",", 2)
    index = index.to_i
    raise ArgumentError, "face #{face.inspect} has a negative frame index" if index.negative?
    return [name, index]
end

# The rect of frame index in a sheet of frameWidth by frameHeight frames.
def faceFrameRect(index, frameWidth, frameHeight)
    return Rect.new((index % 4) * frameWidth, (index / 4) * frameHeight, frameWidth, frameHeight)
end
