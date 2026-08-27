.pragma library

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
    if (isLaunchable(item)) {
        actions.push({
            key: item.pinned ? "unpin" : "pin",
            label: item.pinned ? "Unpin" : "Pin"
        })
    }
    if (Number(item.windowCount) > 0) {
        actions.push({ key: "close-active", label: "Close active instance" })
    }
    return actions
}
