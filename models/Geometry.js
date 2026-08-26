.pragma library

function intersects(first, second) {
    return first.x < second.x + second.width
        && first.x + first.width > second.x
        && first.y < second.y + second.height
        && first.y + first.height > second.y
}

function validRect(rectangle) {
    return rectangle && [rectangle.x, rectangle.y, rectangle.width, rectangle.height]
        .every(function(value) { return typeof value === "number" && isFinite(value) })
        && rectangle.width >= 0 && rectangle.height >= 0
}

function dockRect(monitor, dockWidth, dockHeight, edgeMargin) {
    if (!monitor) return null
    var values = [monitor.x, monitor.y, monitor.width, monitor.height,
        dockWidth, dockHeight, edgeMargin]
    for (var index = 0; index < values.length; index += 1) {
        if (typeof values[index] !== "number" || !isFinite(values[index])) return null
    }
    return {
        x: monitor.x + (monitor.width - dockWidth) / 2,
        y: monitor.y + monitor.height - dockHeight - edgeMargin,
        width: dockWidth,
        height: dockHeight + edgeMargin
    }
}

function sameWorkspace(record, workspace) {
    if (!record || !workspace) return false
    if (record.workspaceId !== null && record.workspaceId !== undefined
            && workspace.id !== null && workspace.id !== undefined) {
        return Number(record.workspaceId) === Number(workspace.id)
    }
    return String(record.workspaceName || "") !== ""
        && String(workspace.name || "") !== ""
        && String(record.workspaceName) === String(workspace.name)
}

function isOmaDockSurface(record) {
    if (!record) return false
    var namespace = String(record.layerNamespace || record.namespace || "")
    return namespace === "omadock-surface"
        || namespace === "omadock-edge"
        || namespace === "omadock-menu"
        || namespace === "omadock-tooltip"
}

function conflicts(record, protectedRect, workspace, monitorName) {
    if (!record || !validRect(protectedRect) || isOmaDockSurface(record)) return false
    if (record.mapped === false || record.minimized || !sameWorkspace(record, workspace)) return false
    if (monitorName && record.monitorName && String(record.monitorName) !== String(monitorName)) return false
    if (record.fullscreen || record.maximized) return true
    if (!validRect(record.geometry)) return !record.floating
    return intersects(record.geometry, protectedRect)
}

function workspaceHasFullscreen(workspace, records, monitorName) {
    if (workspace && workspace.hasFullscreen) return true
    if (!Array.isArray(records)) return false
    for (var index = 0; index < records.length; index += 1) {
        var record = records[index]
        if (record && record.fullscreen && sameWorkspace(record, workspace)
                && (!monitorName || !record.monitorName
                    || String(record.monitorName) === String(monitorName))) return true
    }
    return false
}
