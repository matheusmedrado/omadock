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

function overlapsHorizontally(first, second) {
    return first.x < second.x + second.width
        && first.x + first.width > second.x
}

function dockRect(monitor, dockWidth, dockHeight, edgeMargin) {
    if (!monitor) return null
    var values = [monitor.x, monitor.y, monitor.width, monitor.height,
        dockWidth, dockHeight, edgeMargin]
    for (var index = 0; index < values.length; index += 1) {
        if (typeof values[index] !== "number" || !isFinite(values[index])) return null
    }
    if (monitor.width <= 0 || monitor.height <= 0
            || dockWidth < 0 || dockHeight < 0 || edgeMargin < 0) return null
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
        var recordId = Number(record.workspaceId)
        var workspaceId = Number(workspace.id)
        if (isFinite(recordId) && isFinite(workspaceId)) return recordId === workspaceId
    }
    return String(record.workspaceName || "") !== ""
        && String(workspace.name || "") !== ""
        && String(record.workspaceName) === String(workspace.name)
}

function isOmaDockSurface(record) {
    if (!record) return false
    var namespaces = [record.layerNamespace, record.namespace]
    for (var index = 0; index < namespaces.length; index += 1) {
        var namespace = String(namespaces[index] || "")
        if (namespace === "omadock-surface" || namespace === "omadock-edge"
                || namespace === "omadock-menu" || namespace === "omadock-tooltip") return true
    }
    return false
}

// Smart Hide answers one question regardless of layout mode: would this window
// want the dock's screen band? A reserved dock pushes bottom tiles up so they
// only touch the band's top edge instead of overlapping it; that still counts
// as a conflict because hiding the dock gives that strip back immediately.
//
// Floating windows keep using literal overlap because the exclusive zone never
// moves them.
function conflicts(record, protectedRect, workspace, monitorName) {
    if (!record || !validRect(protectedRect) || isOmaDockSurface(record)) return false
    if (record.mapped === false || record.minimized || !sameWorkspace(record, workspace)) return false
    if (monitorName && record.monitorName && String(record.monitorName) !== String(monitorName)) return false
    if (record.fullscreen || record.maximized) return true
    if (!validRect(record.geometry)) return !record.floating
    if (!record.floating) {
        var bottom = record.geometry.y + record.geometry.height
        return overlapsHorizontally(record.geometry, protectedRect) && bottom >= protectedRect.y
    }
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
