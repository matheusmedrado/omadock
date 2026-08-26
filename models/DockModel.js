.pragma library

function objectOrEmpty(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value)
        ? value : {}
}

function boundedInteger(value, fallback, minimum, maximum) {
    if (typeof value !== "number" || !isFinite(value)) return fallback
    return Math.max(minimum, Math.min(maximum, Math.round(value)))
}

function surfaceMetrics(configuration) {
    var appearance = objectOrEmpty(configuration && configuration.appearance)
    var iconSize = boundedInteger(appearance.iconSize, 24, 16, 48)
    var itemSize = boundedInteger(appearance.itemSize, 44, iconSize + 12, 72)
    var gap = boundedInteger(appearance.gap, 4, 0, 16)
    var edgeMargin = boundedInteger(appearance.edgeMargin, 8, 0, 32)

    return {
        iconSize: iconSize,
        itemSize: itemSize,
        gap: gap,
        edgeMargin: edgeMargin,
        surfaceHeight: itemSize + edgeMargin + 8
    }
}

function contentWidth(itemCount, itemSize, gap) {
    var count = Math.max(0, Number(itemCount) || 0)
    var size = Math.max(0, Number(itemSize) || 0)
    var spacing = Math.max(0, Number(gap) || 0)
    return count > 0 ? count * size + (count - 1) * spacing : 0
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
