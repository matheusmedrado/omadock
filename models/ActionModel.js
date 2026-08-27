.pragma library

// Pointer bindings. Each list is both the set the configuration accepts and the
// set performAction() understands, so a value that validates always resolves to
// something the dock can actually do.
var CLICK_ACTIONS = ["focus-or-launch", "focus-only", "launch-new", "cycle-windows", "none"]
var MIDDLE_CLICK_ACTIONS = ["launch-new", "focus-or-launch", "close-active", "none"]
var WHEEL_ACTIONS = ["cycle-windows", "none"]

function resolveAction(configuration, key, allowed, fallback) {
    var behavior = configuration && configuration.behavior
    var value = behavior ? String(behavior[key] || "") : ""
    return allowed.indexOf(value) >= 0 ? value : fallback
}

function clickAction(configuration) {
    return resolveAction(configuration, "clickAction", CLICK_ACTIONS, "focus-or-launch")
}

function middleClickAction(configuration) {
    return resolveAction(configuration, "middleClickAction", MIDDLE_CLICK_ACTIONS, "launch-new")
}

function wheelAction(configuration) {
    return resolveAction(configuration, "wheelAction", WHEEL_ACTIONS, "cycle-windows")
}

// `forward` only matters to cycle-windows, which runs once per wheel notch in
// the direction of the scroll.
function performAction(action, appService, item, forward) {
    if (!appService || !item || action === "none") return false

    if (action === "focus-or-launch") return !!appService.focusOrLaunch(item)
    if (action === "launch-new") return !!appService.launchNew(item)
    if (action === "close-active") return !!appService.closeActive(item)
    if (action === "focus-only") {
        return Number(item.windowCount) > 0 ? !!appService.focusOrLaunch(item) : false
    }
    if (action === "cycle-windows") {
        return forward === false ? !!appService.focusPrevious(item) : !!appService.focusNext(item)
    }
    return false
}

function isLaunchable(item) {
    return !!item && !item.missing
        && typeof item.desktopId === "string"
        && item.desktopId.trim() !== ""
}

function nextWindowIndex(windows) {
    return stepWindowIndex(windows, 1)
}

function previousWindowIndex(windows) {
    return stepWindowIndex(windows, -1)
}

// Window lists reach here from a QML delegate, where they are QVariantList
// rather than Array. Length-based access works for both.
function stepWindowIndex(windows, step) {
    var count = windows && typeof windows === "object" ? Number(windows.length) : 0
    if (!isFinite(count) || count <= 0) return -1

    for (var index = 0; index < count; index += 1) {
        if (windows[index] && windows[index].active) {
            return ((index + step) % count + count) % count
        }
    }
    return step > 0 ? 0 : count - 1
}

function actionsForItem(item) {
    if (!item) return []

    var actions = []
    if (isLaunchable(item)) {
        actions.push({ key: "launch-new", label: "Open new instance" })
    }
    if (Number(item.windowCount) > 1) {
        actions.push({ key: "focus-next", label: "Focus next instance" })
    }
    // Unpinning must not depend on the application still being installed.
    // Gating both halves on "launchable" meant a pin whose desktop entry had
    // gone -- because the application was uninstalled, or was never installed on
    // this machine -- offered no way out, which is exactly the pin you most need
    // to remove. Pinning still requires something launchable to pin.
    if (item.pinned) {
        if (typeof item.desktopId === "string" && item.desktopId.trim() !== "") {
            actions.push({ key: "unpin", label: "Unpin" })
        }
    } else if (isLaunchable(item)) {
        actions.push({ key: "pin", label: "Pin" })
    }
    if (Number(item.windowCount) > 0) {
        actions.push({ key: "close-active", label: "Close active instance" })
    }
    return actions
}
