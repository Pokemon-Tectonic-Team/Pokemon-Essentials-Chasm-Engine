# Face specs, as written in \ff and the dialogue portrait codes: "name" or
# "name,index", where index picks a frame of a sheet laid out four to a row.
# An animated sheet's name starts with its frame count and delay in brackets,
# as in "[2,10]Val,1", and the comma inside them doesn't split.
FACE_SPEC = /\A(\[\d+(?:,\d+)?\][^,]*|[^,]*)(?:,(.*))?\z/m

# Splits a face spec "name" or "name,index" into [name, index]. Raises
# ArgumentError for a negative index, which names no frame.
def parseFaceSpec(face)
    return [nil, 0] if face.empty?
    match = FACE_SPEC.match(face)
    index = match[2].to_i
    raise ArgumentError, "face #{face.inspect} has a negative frame index" if index.negative?
    return [match[1], index]
end

# The rect of frame index in a sheet of frameWidth by frameHeight frames.
def faceFrameRect(index, frameWidth, frameHeight)
    return Rect.new((index % 4) * frameWidth, (index / 4) * frameHeight, frameWidth, frameHeight)
end
