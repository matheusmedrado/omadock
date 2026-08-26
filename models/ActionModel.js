.pragma library

function isLaunchable(item) {
    return !!item && !item.missing
        && typeof item.desktopId === "string"
        && item.desktopId.trim() !== ""
}

function nextWindowIndex(windows) {
    if (!Array.isArray(windows) || windows.length === 0) return -1

    for (var index = 0; index < windows.length; index += 1) {
        if (windows[index] && windows[index].active) return (index + 1) % windows.length
    }
    return 0
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
