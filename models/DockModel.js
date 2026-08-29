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

// How long a hover label takes to open or close. It rides behavior.animationMs
// so that turning motion off (0) silences the label too, rather than leaving one
// animation running for a user who asked for none.
function labelRevealMs(configuration) {
    var behavior = objectOrEmpty(configuration && configuration.behavior)
    return boundedInteger(behavior.animationMs, 160, 0, 500)
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

// Whether two item lists would draw the same strip.
//
// The strip's Repeater is backed by a plain JavaScript array, which QML cannot
// diff: assigning a new one destroys and recreates every delegate, taking the
// hover state, the colour easing, any open tooltip, and any drag in progress
// with it. Items are rebuilt from scratch whenever the windows, the pinned
// list, or the desktop entries change, so the new array is never the same
// object as the old one and the list has to be compared by value to tell a real
// change from a rebuild that landed on the same answer.
var COMPARED_ITEM_FIELDS = [
    "key", "desktopId", "appId", "name", "shortLabel", "icon", "iconSource",
    "categories", "exec", "pinned", "missing", "running", "active", "urgent",
    "windowCount", "slot"
]

// An item carries whole window records, but it only ever reads a handful of
// fields off them: which window is active, where it lives, and the handle an
// action is performed through. Everything else on a record -- geometry,
// workspace, floating, the maximise and minimise flags -- exists for Smart
// Hide, which reads the records directly.
//
// Comparing only what the strip consumes is what keeps a window being dragged
// or resized from rebuilding every dock item on the way: that moves geometry on
// every frame, and none of it changes a glyph, a label, or a marker.
var COMPARED_WINDOW_FIELDS = ["key", "active", "monitorName", "toplevel"]

function sameNameList(first, second) {
    var left = toArray(first)
    var right = toArray(second)
    if (left.length !== right.length) return false
    for (var index = 0; index < left.length; index += 1) {
        if (String(left[index]) !== String(right[index])) return false
    }
    return true
}

function sameWindow(first, second) {
    if (!first || !second) return !first && !second
    for (var index = 0; index < COMPARED_WINDOW_FIELDS.length; index += 1) {
        var field = COMPARED_WINDOW_FIELDS[index]
        if (first[field] !== second[field]) return false
    }
    return sameNameList(first.screenNames, second.screenNames)
}

// Order matters: cycling steps through this list, so two lists holding the same
// windows in a different order do not behave the same.
function sameWindowList(first, second) {
    var left = toArray(first)
    var right = toArray(second)
    if (left.length !== right.length) return false
    for (var index = 0; index < left.length; index += 1) {
        if (!sameWindow(left[index], right[index])) return false
    }
    return true
}

function sameItem(first, second) {
    if (!first || !second) return !first && !second
    for (var index = 0; index < COMPARED_ITEM_FIELDS.length; index += 1) {
        var field = COMPARED_ITEM_FIELDS[index]
        if (first[field] !== second[field]) return false
    }
    return sameWindowList(first.windows, second.windows)
}

function sameItems(first, second) {
    var left = toArray(first)
    var right = toArray(second)
    if (left.length !== right.length) return false
    for (var index = 0; index < left.length; index += 1) {
        if (!sameItem(left[index], right[index])) return false
    }
    return true
}
