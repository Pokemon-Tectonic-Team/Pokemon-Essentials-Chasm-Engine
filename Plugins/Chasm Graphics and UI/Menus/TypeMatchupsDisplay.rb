# The type matchups pages of the MasterDex and the MoveDex: every type sorted
# by effectiveness, drawn as three columns of type icons. A scene including it
# loads @typebitmap and @types_emphasized_bitmap.
module TypeMatchupsDisplay
    MATCHUPS_X_LEFT = 36
    MATCHUPS_Y_BASE = 60
    MATCHUPS_LABEL_WIDTH = 450
    MATCHUPS_ICONS_BELOW_LABEL = 30
    MATCHUPS_ROW_HEIGHT = 36
    MATCHUPS_ROWS = 7
    MATCHUPS_COLUMN_WIDTH = 112
    MATCHUPS_WIDE_COLUMN_WIDTH = 212
    MATCHUPS_WRAP_OFFSET = 100
    TYPE_ICON_WIDTH = 96
    TYPE_ICON_HEIGHT = 32

    # Every non-pseudo type, sorted by the effectiveness the block gives for its
    # ID into immune, barely, resisted, super and hyper lists.
    def typeMatchupsBy
        matchups = { immune: [], barely: [], resisted: [], super: [], hyper: [] }
        GameData::Type.each do |t|
            next if t.pseudo_type

            effect = yield t.id
            if Effectiveness.ineffective?(effect)
                matchups[:immune].push(t)
            elsif Effectiveness.barely_effective?(effect)
                matchups[:barely].push(t)
            elsif Effectiveness.not_very_effective?(effect)
                matchups[:resisted].push(t)
            elsif Effectiveness.hyper_effective?(effect)
                matchups[:hyper].push(t)
            elsif Effectiveness.super_effective?(effect)
                matchups[:super].push(t)
            end
        end
        return matchups
    end

    # Draws hyper then super types, barely then resisted types, and immune
    # types, under the three labels, with hyper and barely types emphasised.
    # The column at index wideColumn is wider and wraps into a second column.
    def drawTypeMatchups(overlay, matchups, labels, wideColumn)
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        columns = [
            [matchups[:hyper], matchups[:super]],
            [matchups[:barely], matchups[:resisted]],
            [[], matchups[:immune]],
        ]
        x = MATCHUPS_X_LEFT
        iconsY = MATCHUPS_Y_BASE + MATCHUPS_ICONS_BELOW_LABEL
        columns.each_with_index do |(emphasized, plain), column|
            wide = column == wideColumn
            types = emphasized + plain
            drawTextEx(overlay, x, MATCHUPS_Y_BASE, MATCHUPS_LABEL_WIDTH, 1, labels[column], base, shadow)
            drawTextEx(overlay, x, iconsY, MATCHUPS_LABEL_WIDTH, 1, _INTL("None"), base, shadow) if types.empty?
            types.each_with_index do |t, index|
                wrapped = wide && index >= MATCHUPS_ROWS
                row = wide ? index % MATCHUPS_ROWS : index
                bitmap = emphasized.include?(t) ? @types_emphasized_bitmap.bitmap : @typebitmap.bitmap
                iconRect = Rect.new(0, t.id_number * TYPE_ICON_HEIGHT, TYPE_ICON_WIDTH, TYPE_ICON_HEIGHT)
                overlay.blt(x + (wrapped ? MATCHUPS_WRAP_OFFSET : 0), iconsY + (MATCHUPS_ROW_HEIGHT * row), bitmap, iconRect)
            end
            x += wide ? MATCHUPS_WIDE_COLUMN_WIDTH : MATCHUPS_COLUMN_WIDTH
        end
    end
end
