# Counts the fully transparent rows of rect within bitmap, from its top (or its
# bottom when fromBottom), judging each row by its pixel at the rect's middle.
# A window's edges start with such rows when its skin leaves space around the
# visible frame.
def transparentRowsAt(bitmap, rect, fromBottom)
    x = rect.x + (rect.width / 2)
    rows = 0
    while rows < rect.height
        y = fromBottom ? rect.y + rect.height - 1 - rows : rect.y + rows
        break if bitmap.get_pixel(x, y).alpha > 0
        rows += 1
    end
    return rows
end
