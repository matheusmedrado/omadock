import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: root

    property var records: []
    property int refreshDelayMs: 35
    property int ipcSettleMs: 25
    signal workspaceTransition()

    function modelValues(model) {
        return model && model.values ? model.values : []
    }

    function numberOrNull(value) {
        return typeof value === "number" && isFinite(value) ? value : null
    }

    function rectangleFromIpc(ipc) {
        if (!ipc || !Array.isArray(ipc.at) || !Array.isArray(ipc.size)) return null
        if (ipc.at.length < 2 || ipc.size.length < 2) return null
        var x = numberOrNull(ipc.at[0])
        var y = numberOrNull(ipc.at[1])
        var width = numberOrNull(ipc.size[0])
        var height = numberOrNull(ipc.size[1])
        if (x === null || y === null || width === null || height === null) return null
        if (width < 0 || height < 0) return null
        return { x: x, y: y, width: width, height: height }
    }

    function hyprFor(toplevel, hyprToplevels) {
        var attached = toplevel && toplevel.HyprlandToplevel
        if (attached) return attached

        for (var index = 0; index < hyprToplevels.length; index += 1) {
            if (hyprToplevels[index].wayland === toplevel
                    && hyprToplevels[index].lastIpcObject !== undefined) {
                return hyprToplevels[index]
            }
        }
        return null
    }

    function workspaceId(workspace) {
        return workspace && workspace.id !== undefined ? workspace.id : null
    }

    function monitorName(monitor) {
        return monitor && monitor.name ? String(monitor.name) : ""
    }

    function screenNames(screens) {
        var names = []
        if (!Array.isArray(screens)) return names
        for (var index = 0; index < screens.length; index += 1) {
            if (screens[index] && screens[index].name) names.push(String(screens[index].name))
        }
        return names
    }

    function normalizedRecord(toplevel, hyprToplevel, index) {
        var ipc = hyprToplevel ? hyprToplevel.lastIpcObject : null
        var screens = Array.isArray(toplevel.screens) ? toplevel.screens : []
        var monitor = hyprToplevel ? hyprToplevel.monitor : null
        var workspace = hyprToplevel ? hyprToplevel.workspace : null
        var geometry = rectangleFromIpc(ipc)
        var appId = String(toplevel.appId || (ipc && (ipc.class || ipc.initialClass)) || "")
        var title = String(toplevel.title || (hyprToplevel && hyprToplevel.title) || (ipc && ipc.title) || "")
        var address = hyprToplevel && hyprToplevel.address ? String(hyprToplevel.address) : ""

        return {
            key: address || "wayland:" + appId + ":" + index,
            appId: appId,
            title: title,
            active: !!(toplevel.activated || (hyprToplevel && hyprToplevel.activated)),
            urgent: !!(hyprToplevel && hyprToplevel.urgent),
            minimized: !!toplevel.minimized,
            maximized: !!toplevel.maximized || !!(ipc && ipc.maximized),
            fullscreen: !!toplevel.fullscreen || !!(ipc && ipc.fullscreen),
            mapped: ipc && ipc.mapped !== undefined ? !!ipc.mapped : true,
            floating: ipc && ipc.floating !== undefined ? !!ipc.floating : false,
            geometry: geometry,
            workspaceId: workspaceId(workspace),
            workspaceName: workspace && workspace.name ? String(workspace.name) : "",
            monitorId: monitor && monitor.id !== undefined ? monitor.id : null,
            monitorName: monitorName(monitor),
            screens: screens,
            screenNames: screenNames(screens),
            toplevel: toplevel,
            hyprToplevel: hyprToplevel
        }
    }

    function rebuild() {
        var toplevels = modelValues(ToplevelManager.toplevels)
        var hyprToplevels = modelValues(Hyprland.toplevels)
        var nextRecords = []
        for (var index = 0; index < toplevels.length; index += 1) {
            nextRecords.push(normalizedRecord(toplevels[index], hyprFor(toplevels[index], hyprToplevels), index))
        }
        records = nextRecords
    }

    function scheduleRefresh() {
        refreshTimer.restart()
    }

    function refresh() {
        if (typeof Hyprland.refreshToplevels === "function") Hyprland.refreshToplevels()
        settleTimer.restart()
    }

    function relevantEvent(event) {
        var name = String(event && (event.name || event.event || event.type) || "").toLowerCase()
        var events = [
            "openwindow", "closewindow", "movewindow", "movewindowv2", "windowtitle",
            "activewindow", "activewindowv2", "fullscreen", "workspace", "workspacev2",
            "moveworkspace", "moveworkspacev2", "monitoradded", "monitorremoved",
            "focusedmon", "focusedmonv2", "changefloating", "urgent"
        ]
        for (var index = 0; index < events.length; index += 1) {
            if (name === events[index] || name.indexOf(events[index]) === 0) return true
        }
        return false
    }

    function isWorkspaceEvent(event) {
        var name = String(event && (event.name || event.event || event.type) || "").toLowerCase()
        return name.indexOf("workspace") === 0
            || name.indexOf("moveworkspace") === 0
            || name.indexOf("focusedmon") === 0
    }

    Timer {
        id: refreshTimer
        interval: root.refreshDelayMs
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: settleTimer
        interval: root.ipcSettleMs
        repeat: false
        onTriggered: root.rebuild()
    }

    Connections {
        target: ToplevelManager
        function onToplevelsChanged() { root.scheduleRefresh() }
        function onActiveToplevelChanged() { root.scheduleRefresh() }
    }

    Connections {
        target: ToplevelManager.toplevels
        function onObjectInsertedPost() { root.scheduleRefresh() }
        function onObjectRemovedPost() { root.scheduleRefresh() }
    }

    Connections {
        target: Hyprland
        function onToplevelsChanged() { root.scheduleRefresh() }
        function onWorkspacesChanged() { root.scheduleRefresh() }
        function onMonitorsChanged() { root.scheduleRefresh() }
        function onActiveToplevelChanged() { root.scheduleRefresh() }
        function onRawEvent(event) {
            if (root.isWorkspaceEvent(event)) root.workspaceTransition()
            if (root.relevantEvent(event)) root.scheduleRefresh()
        }
    }

    Component.onCompleted: root.scheduleRefresh()
}
