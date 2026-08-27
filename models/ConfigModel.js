.pragma library

var CONFIG_VERSION = 1

function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value)
}

function has(object, key) {
    return Object.prototype.hasOwnProperty.call(object, key)
}

function clone(value) {
    if (value === null || typeof value !== "object") return value

    if (Array.isArray(value)) {
        var array = []
        for (var index = 0; index < value.length; index += 1) array.push(clone(value[index]))
        return array
    }

    var object = {}
    for (var key in value) {
        if (has(value, key)) object[key] = clone(value[key])
    }
    return object
}

function defaultConfig() {
    return {
        version: CONFIG_VERSION,
        position: "bottom",
        monitorMode: "all",
        monitors: [],
        appearance: {
            density: "compact",
            iconSize: 16,
            itemSize: 28,
            gap: 4,
            edgeMargin: 8,
            showSlotNumbers: false,
            showLabels: "always",
            showPrompt: true,
            usePixelGlyphs: true,
            backgroundOpacity: 0.94
        },
        behavior: {
            hideMode: "smart",
            reserveSpace: false,
            revealDelayMs: 35,
            hideDelayMs: 320,
            animationMs: 160,
            workspaceSettleMs: 120,
            showRunningUnpinned: true,
            clickAction: "focus-or-launch",
            middleClickAction: "launch-new",
            wheelAction: "cycle-windows"
        },
        pinned: [
            { desktopId: "com.mitchellh.ghostty" },
            { desktopId: "zen" },
            { desktopId: "org.gnome.Nautilus" }
        ],
        aliases: {}
    }
}

function isSupportedVersion(value) {
    return value === CONFIG_VERSION
}

function warning(warnings, path, message) {
    warnings.push(path + " " + message)
}

function enumValue(object, key, allowed, fallback, warnings, path) {
    if (!has(object, key)) return fallback
    var value = object[key]
    if (typeof value === "string" && allowed.indexOf(value) >= 0) return value
    warning(warnings, path + "." + key, "was reset to its default")
    return fallback
}

function boolValue(object, key, fallback, warnings, path) {
    if (!has(object, key)) return fallback
    if (typeof object[key] === "boolean") return object[key]
    warning(warnings, path + "." + key, "was reset to its default")
    return fallback
}

function finiteNumber(value) {
    return typeof value === "number" && isFinite(value)
}

function intValue(object, key, fallback, minimum, maximum, warnings, path) {
    if (!has(object, key)) return Math.max(minimum, Math.min(maximum, fallback))
    if (!finiteNumber(object[key])) {
        warning(warnings, path + "." + key, "was reset to its default")
        return Math.max(minimum, Math.min(maximum, fallback))
    }
    return Math.max(minimum, Math.min(maximum, Math.round(object[key])))
}

function realValue(object, key, fallback, minimum, maximum, warnings, path) {
    if (!has(object, key)) return Math.max(minimum, Math.min(maximum, fallback))
    if (!finiteNumber(object[key])) {
        warning(warnings, path + "." + key, "was reset to its default")
        return Math.max(minimum, Math.min(maximum, fallback))
    }
    return Math.max(minimum, Math.min(maximum, object[key]))
}

function normalizedId(value) {
    var id = String(value || "").trim().toLowerCase()
    return id.slice(-8) === ".desktop" ? id.slice(0, -8) : id
}

function normalizeMonitors(raw, fallback, warnings) {
    if (!has(raw, "monitors")) return clone(fallback)
    if (!Array.isArray(raw.monitors)) {
        warning(warnings, "monitors", "was reset to its default")
        return clone(fallback)
    }

    var result = []
    var seen = {}
    for (var index = 0; index < raw.monitors.length; index += 1) {
        var monitor = raw.monitors[index]
        if (typeof monitor !== "string" || monitor.trim() === "") continue
        var name = monitor.trim()
        if (!seen[name]) {
            seen[name] = true
            result.push(name)
        }
    }
    return result
}

function normalizePinned(raw, fallback, warnings) {
    if (!has(raw, "pinned")) return clone(fallback)
    if (!Array.isArray(raw.pinned)) {
        warning(warnings, "pinned", "was reset to its default")
        return clone(fallback)
    }

    var result = []
    var seen = {}
    for (var index = 0; index < raw.pinned.length; index += 1) {
        var record = raw.pinned[index]
        if (!isObject(record) || typeof record.desktopId !== "string") continue
        var desktopId = record.desktopId.trim()
        var key = normalizedId(desktopId)
        if (desktopId !== "" && !seen[key]) {
            seen[key] = true
            result.push({ desktopId: desktopId })
        }
    }
    return result
}

function insertPinned(pinned, desktopId, index) {
    var value = String(desktopId || "").trim()
    var wanted = normalizedId(value)
    var result = Array.isArray(pinned) ? clone(pinned) : []
    if (!wanted) return result

    for (var existingIndex = 0; existingIndex < result.length; existingIndex += 1) {
        if (normalizedId(result[existingIndex] && result[existingIndex].desktopId) === wanted) {
            return result
        }
    }

    var destination = Number(index)
    if (!isFinite(destination)) destination = result.length
    destination = Math.max(0, Math.min(result.length, Math.floor(destination)))
    result.splice(destination, 0, { desktopId: value })
    return result
}

function reorderPinned(pinned, fromIndex, toIndex) {
    if (!Array.isArray(pinned)) return null
    var result = clone(pinned)
    var from = Number(fromIndex)
    var to = Number(toIndex)
    if (!isFinite(from) || !isFinite(to)
            || Math.floor(from) !== from || Math.floor(to) !== to
            || from < 0 || from >= result.length || to < 0 || to > result.length) return null

    var moved = result.splice(from, 1)[0]
    var destination = Math.min(to, result.length)
    result.splice(destination, 0, moved)
    return result
}

function samePinnedOrder(first, second) {
    if (!Array.isArray(first) || !Array.isArray(second) || first.length !== second.length) return false
    for (var index = 0; index < first.length; index += 1) {
        if (normalizedId(first[index] && first[index].desktopId)
                !== normalizedId(second[index] && second[index].desktopId)) return false
    }
    return true
}

function normalizeAliases(raw, fallback, warnings) {
    if (!has(raw, "aliases")) return clone(fallback)
    if (!isObject(raw.aliases)) {
        warning(warnings, "aliases", "was reset to its default")
        return clone(fallback)
    }

    var result = {}
    for (var key in raw.aliases) {
        if (!has(raw.aliases, key) || typeof raw.aliases[key] !== "string") continue
        var normalizedKey = normalizedId(key)
        var target = raw.aliases[key].trim()
        if (normalizedKey !== "" && target !== "") result[normalizedKey] = target
    }
    return result
}

function normalizeConfig(raw, defaults) {
    var fallback = clone(defaults || defaultConfig())
    if (!isObject(raw)) {
        return {
            valid: false,
            value: fallback,
            errors: ["configuration must be a JSON object"],
            warnings: []
        }
    }

    if (!isSupportedVersion(raw.version)) {
        return {
            valid: false,
            value: fallback,
            errors: ["version must be " + CONFIG_VERSION],
            warnings: []
        }
    }

    var warnings = []
    var value = fallback
    value.version = CONFIG_VERSION
    value.position = enumValue(raw, "position", ["bottom"], fallback.position, warnings, "config")
    value.monitorMode = enumValue(raw, "monitorMode", ["all", "focused", "named"], fallback.monitorMode, warnings, "config")
    value.monitors = normalizeMonitors(raw, fallback.monitors, warnings)

    var appearance = isObject(raw.appearance) ? raw.appearance : {}
    if (has(raw, "appearance") && !isObject(raw.appearance)) warning(warnings, "appearance", "was reset to its defaults")
    value.appearance.density = enumValue(appearance, "density", ["compact", "comfortable"], fallback.appearance.density, warnings, "appearance")
    value.appearance.iconSize = intValue(appearance, "iconSize", fallback.appearance.iconSize, 10, 32, warnings, "appearance")
    value.appearance.itemSize = intValue(appearance, "itemSize", fallback.appearance.itemSize, value.appearance.iconSize + 8, 56, warnings, "appearance")
    value.appearance.gap = intValue(appearance, "gap", fallback.appearance.gap, 0, 16, warnings, "appearance")
    value.appearance.edgeMargin = intValue(appearance, "edgeMargin", fallback.appearance.edgeMargin, 0, 32, warnings, "appearance")
    value.appearance.showSlotNumbers = boolValue(appearance, "showSlotNumbers", fallback.appearance.showSlotNumbers, warnings, "appearance")
    value.appearance.showLabels = enumValue(appearance, "showLabels", ["always", "hover", "never"], fallback.appearance.showLabels, warnings, "appearance")
    value.appearance.showPrompt = boolValue(appearance, "showPrompt", fallback.appearance.showPrompt, warnings, "appearance")
    value.appearance.usePixelGlyphs = boolValue(appearance, "usePixelGlyphs", fallback.appearance.usePixelGlyphs, warnings, "appearance")
    value.appearance.backgroundOpacity = realValue(appearance, "backgroundOpacity", fallback.appearance.backgroundOpacity, 0.35, 1.0, warnings, "appearance")

    var behavior = isObject(raw.behavior) ? raw.behavior : {}
    if (has(raw, "behavior") && !isObject(raw.behavior)) warning(warnings, "behavior", "was reset to its defaults")
    value.behavior.hideMode = enumValue(behavior, "hideMode", ["smart", "always", "never"], fallback.behavior.hideMode, warnings, "behavior")
    value.behavior.reserveSpace = value.behavior.hideMode === "never"
        && boolValue(behavior, "reserveSpace", fallback.behavior.reserveSpace, warnings, "behavior")
    value.behavior.revealDelayMs = intValue(behavior, "revealDelayMs", fallback.behavior.revealDelayMs, 0, 1000, warnings, "behavior")
    value.behavior.hideDelayMs = intValue(behavior, "hideDelayMs", fallback.behavior.hideDelayMs, 0, 2000, warnings, "behavior")
    value.behavior.animationMs = intValue(behavior, "animationMs", fallback.behavior.animationMs, 0, 500, warnings, "behavior")
    value.behavior.workspaceSettleMs = intValue(behavior, "workspaceSettleMs", fallback.behavior.workspaceSettleMs, 0, 1000, warnings, "behavior")
    value.behavior.showRunningUnpinned = boolValue(behavior, "showRunningUnpinned", fallback.behavior.showRunningUnpinned, warnings, "behavior")
    value.behavior.clickAction = enumValue(behavior, "clickAction", ["focus-or-launch", "focus-only", "launch-new", "cycle-windows", "none"], fallback.behavior.clickAction, warnings, "behavior")
    value.behavior.middleClickAction = enumValue(behavior, "middleClickAction", ["launch-new", "focus-or-launch", "close-active", "none"], fallback.behavior.middleClickAction, warnings, "behavior")
    value.behavior.wheelAction = enumValue(behavior, "wheelAction", ["cycle-windows", "none"], fallback.behavior.wheelAction, warnings, "behavior")

    value.pinned = normalizePinned(raw, fallback.pinned, warnings)
    value.aliases = normalizeAliases(raw, fallback.aliases, warnings)

    return {
        valid: true,
        value: value,
        errors: [],
        warnings: warnings
    }
}

function mergeKnownSettings(original, normalized) {
    var result = isObject(original) ? clone(original) : {}
    var knownKeys = ["version", "position", "monitorMode", "monitors", "appearance", "behavior", "pinned", "aliases"]
    for (var index = 0; index < knownKeys.length; index += 1) {
        var key = knownKeys[index]
        result[key] = clone(normalized[key])
    }
    return result
}
