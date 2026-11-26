# Face specs, as written in \ff and the dialogue portrait codes: "name" or
# "name,index", where index picks a frame of a sheet laid out four to a row.

# Splits a face spec "name" or "name,index" into [name, index].
def parseFaceSpec(face)
    name, index = face.split(",", 2)
    return [name, index.to_i]
end

# The rect of frame index in a sheet of frameWidth by frameHeight frames.
def faceFrameRect(index, frameWidth, frameHeight)
    return Rect.new((index % 4) * frameWidth, (index / 4) * frameHeight, frameWidth, frameHeight)
end
