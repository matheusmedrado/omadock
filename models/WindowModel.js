.pragma library

// Whether two window records describe the same state, for deciding if the
// record list is worth republishing.
//
// The dock rebuilds its records from scratch on every Hyprland event it cares
// about, so the new list is always a fresh array of fresh objects and comparing
// by identity would always say "changed". Republishing drives the whole dock:
// the item model is rebuilt, and because the strip's Repeater is backed by a
// plain JavaScript array it cannot diff one, so every delegate is destroyed and
// recreated. Anything the pointer was on -- hover state, the colour easing, an
// open tooltip, a drag in progress -- is lost with it.
//
// That is only acceptable when something actually changed, hence this
// comparison.

// Window titles are deliberately not compared. Nothing in the dock reads one:
// glyphs, labels, ordering, and every Smart Hide decision come from the
// application id, the workspace, and the geometry. Terminals running an agent
// CLI rewrite their title on a spinner cadence -- about once a second -- and
// Hyprland re-emits `activewindow` next to `windowtitle` for the focused
// window, so counting a title as a change republished the records roughly once
// a second for as long as such a terminal was open.
//
// A record's `title` is therefore a snapshot from the last refresh that changed
// something else, and is kept for diagnostics rather than for display.
var COMPARED_FIELDS = [
    "appId", "active", "urgent", "minimized", "maximized", "fullscreen",
    "mapped", "floating", "workspaceId", "workspaceName", "monitorId",
    "monitorName"
]

function sameRectangle(first, second) {
    if (!first || !second) return !first && !second
    return first.x === second.x && first.y === second.y
        && first.width === second.width && first.height === second.height
}

function sameNames(first, second) {
    var left = Array.isArray(first) ? first : []
    var right = Array.isArray(second) ? second : []
    if (left.length !== right.length) return false
    for (var index = 0; index < left.length; index += 1) {
        if (String(left[index]) !== String(right[index])) return false
    }
    return true
}

function sameRecord(first, second) {
    if (!first || !second) return !first && !second
    if (first.key !== second.key) return false

    for (var index = 0; index < COMPARED_FIELDS.length; index += 1) {
        var field = COMPARED_FIELDS[index]
        if (first[field] !== second[field]) return false
    }

    // The handles are what an action is performed through, so a replaced one
    // has to reach the item even when every value around it matches, or the
    // dock would go on calling activate() on a dead toplevel.
    if (first.toplevel !== second.toplevel) return false
    if (first.hyprToplevel !== second.hyprToplevel) return false

    return sameNames(first.screenNames, second.screenNames)
        && sameRectangle(first.geometry, second.geometry)
}

// Order is part of the comparison: the records are rebuilt in enumeration
// order, and the item strip lays out from it.
function sameRecords(first, second) {
    var left = Array.isArray(first) ? first : []
    var right = Array.isArray(second) ? second : []
    if (left.length !== right.length) return false
    for (var index = 0; index < left.length; index += 1) {
        if (!sameRecord(left[index], right[index])) return false
    }
    return true
}

// Which Hyprland events the dock has to refresh for.
//
// Names are matched by prefix so a `v2` form is covered by its base name.
//
// `windowtitle` is deliberately absent: nothing in the dock reads a window
// title, and refreshing is an IPC round trip Hyprland answers on its own event
// loop, so listening for a title meant paying for that round trip on every
// spinner frame of every terminal running an agent CLI.
var REFRESH_EVENTS = [
    "openwindow", "closewindow", "movewindow", "movewindowv2",
    "fullscreen", "workspace", "workspacev2",
    "moveworkspace", "moveworkspacev2", "monitoradded", "monitorremoved",
    "focusedmon", "focusedmonv2", "changefloating", "urgent"
]

var WORKSPACE_EVENTS = ["workspace", "moveworkspace", "focusedmon"]

function eventName(event) {
    return String(event && (event.name || event.event || event.type) || "").toLowerCase()
}

function eventData(event) {
    return String(event && (event.data !== undefined ? event.data : "") || "").trim()
}

function matchesAnyPrefix(name, prefixes) {
    for (var index = 0; index < prefixes.length; index += 1) {
        if (name === prefixes[index] || name.indexOf(prefixes[index]) === 0) return true
    }
    return false
}

function isRefreshEvent(event) {
    return matchesAnyPrefix(eventName(event), REFRESH_EVENTS)
}

function isWorkspaceEvent(event) {
    return matchesAnyPrefix(eventName(event), WORKSPACE_EVENTS)
}

// The focused window is reported twice. `activewindow` carries its class and
// title, so it is re-emitted on every title change -- the same spinner cadence
// `windowtitle` has, which is why it cannot be treated as a focus change. Its
// `v2` form carries the address instead, which is the part that identifies the
// window, so that is the form the dock acts on.
//
// Returns the focused address for the v2 form, an empty string when focus was
// cleared, and null for every other event including the v1 form.
function activeWindowAddress(event) {
    var name = eventName(event)
    if (name === "activewindowv2") return eventData(event)
    return null
}

function isActiveWindowEvent(event) {
    var name = eventName(event)
    return name === "activewindow" || name === "activewindowv2"
}
