.pragma library

// A list handed to a Repeater model, or read back off one, arrives as a
// QVariantList: it indexes and has a length, but Array.isArray rejects it. Every
// guard written as `Array.isArray(...)` therefore fails silently on exactly the
// data the delegates are rendering, so list access goes through here instead.
function toArray(value) {
    if (Array.isArray(value)) return value
    if (!value || typeof value !== "object") return []

    var length = Number(value.length)
    if (!isFinite(length) || length < 0) return []

    var result = []
    for (var index = 0; index < length; index += 1) result.push(value[index])
    return result
}

function objectOrEmpty(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value)
        ? value : {}
}

function boundedInteger(value, fallback, minimum, maximum) {
    if (typeof value !== "number" || !isFinite(value)) return fallback
    return Math.max(minimum, Math.min(maximum, Math.round(value)))
}

// The command strip sizes itself from the glyph and the label beside it, so
// `iconSize` bounds the glyph and `itemSize` becomes the row height rather than
// the side of a square tile. Both keep their configuration names so an existing
// config.json keeps validating.
function surfaceMetrics(configuration) {
    var appearance = objectOrEmpty(configuration && configuration.appearance)
    var glyphSize = boundedInteger(appearance.iconSize, 28, 14, 42)
    var itemHeight = boundedInteger(appearance.itemSize, 40, glyphSize + 8, 72)
    var gap = boundedInteger(appearance.gap, 4, 0, 16)
    var edgeMargin = boundedInteger(appearance.edgeMargin, 8, 0, 32)
    var contentPadding = appearance.density === "comfortable" ? 10 : 7
    var itemPadding = appearance.density === "comfortable" ? 10 : 8
    var ditherCell = boundedInteger(appearance.ditherCell, 2, 1, 6)

    return {
        glyphSize: glyphSize,
        itemHeight: itemHeight,
        gap: gap,
        edgeMargin: edgeMargin,
        contentPadding: contentPadding,
        itemPadding: itemPadding,
        ditherCell: ditherCell,
        surfaceHeight: itemHeight + contentPadding * 2 + edgeMargin
    }
}

// Dragging a pinned application clear of the strip unpins it, the way a dock
// icon is dragged off on macOS. Only vertical distance counts: the strip is
// horizontal and dragging past either end is how an item is moved to the front
// or back, so treating that as "outside" would make reordering to an edge
// unpin instead.
//
// The threshold keeps a slightly wobbly reorder from throwing the pin away; a
// deliberate pull away from the strip is required.
function dragLeavesStrip(pointerY, stripHeight, threshold) {
    var y = Number(pointerY)
    var height = Number(stripHeight)
    var margin = Number(threshold)
    if (!isFinite(y) || !isFinite(height) || !isFinite(margin) || margin < 0) return false
    return y < -margin || y > height + margin
}

function slotLabel(slot) {
    var number = Number(slot)
    if (!isFinite(number) || number <= 0) return ""
    return ("0" + Math.floor(number)).slice(-2)
}

function instanceCountLabel(count) {
    var number = Number(count)
    if (!isFinite(number) || number < 2) return ""
    return Math.floor(number) + "x"
}

function fallbackGlyph(label, fallback) {
    var value = String(label || fallback || "APP")
        .toUpperCase().replace(/[^A-Z0-9]/g, "")
    return value.slice(0, 2) || "?"
}
